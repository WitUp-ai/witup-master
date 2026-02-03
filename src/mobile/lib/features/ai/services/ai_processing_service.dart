import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/debug_log_service.dart';

/// Service to handle AI processing of drawings
class AIProcessingService {
  final SupabaseClient _supabase;
  final String _supabaseUrl;
  final String _anonKey;

  final _debug = DebugLogService.instance;

  AIProcessingService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        _supabaseUrl = Supabase.instance.client.rest.url.toString().replaceAll('/rest/v1', ''),
        _anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY',
            defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74');

  /// Trigger AI processing for a drawing via Edge Function
  Future<ProcessingResult> processDrawing({
    required String drawingId,
    required String userId,
  }) async {
    try {
      _debug.log('Processing', 'Starting processing for drawing: $drawingId');

      // First, update status to processing
      await _supabase.from('drawings').update({
        'model_status': 'processing',
        'processing_started_at': DateTime.now().toIso8601String(),
      }).eq('id', drawingId).eq('user_id', userId);

      // Call Edge Function (required — no fallback)
      _debug.log('Processing', 'Calling Edge Function at $_supabaseUrl/functions/v1/process-drawing');
      final result = await _tryEdgeFunction(drawingId, userId);
      _debug.success('Processing', 'Edge Function returned successfully', data: {
        'has_processed_image': result.processedImageUrl != null,
        'has_3d_model': result.model3dUrl != null,
      });
      return result;
    } catch (e) {
      _debug.error('Processing', 'Processing failed', error: e);

      // Mark as failed
      try {
        await _supabase.from('drawings').update({
          'model_status': 'failed',
          'processing_error': e.toString(),
        }).eq('id', drawingId);
      } catch (_) {}

      rethrow;
    }
  }

  /// Call Edge Function for AI processing (required — no fallback)
  Future<ProcessingResult> _tryEdgeFunction(String drawingId, String userId) async {
    // Check if token is expired and refresh if needed
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      final expiresAt = currentSession.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final isExpired = now >= expiresAt;

        _debug.log('Auth', 'Token check - expires: $expiresAt, now: $now, expired: $isExpired');

        // Only refresh if actually expired
        if (isExpired) {
          _debug.warning('Auth', 'Token expired, refreshing...');
          try {
            await _supabase.auth.refreshSession();
            _debug.success('Auth', 'Token refreshed successfully');
          } catch (e) {
            _debug.error('Auth', 'Token refresh failed', error: e);
          }
        }
      }
    }

    if (_supabaseUrl.isEmpty) {
      throw Exception('Errore Configurazione: URL Supabase non configurato.');
    }

    _debug.log('Auth', 'Calling Edge Function with anon key (no user JWT needed)');

    final response = await http.post(
      Uri.parse('$_supabaseUrl/functions/v1/process-drawing'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_anonKey',
      },
      body: jsonEncode({
        'drawing_id': drawingId,
        'user_id': userId,
      }),
    ).timeout(const Duration(seconds: 90), onTimeout: () {
      throw Exception('Edge Function timeout (90s)');
    });

    _debug.log('EdgeFunction', 'Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check for validation failure (not a drawing)
      if (data['error'] == 'not_a_drawing') {
        _debug.warning('Validation', 'Image rejected: ${data['error_message']}');
        throw DrawingValidationException(
          data['error_message'] ?? 'The uploaded image does not appear to be a drawing.',
        );
      }

      _debug.success('EdgeFunction', 'Parsed response', data: {
        'success': data['success'],
        'processed_image_url': data['processed_image_url'],
        'concept_url': data['concept_url'],
        'has_processed_image': data['processed_image_url'] != null,
        'has_concept': data['concept_url'] != null,
        'has_3d_model': data['model_3d_url'] != null,
        'processing_time_ms': data['processing_time_ms'],
        'fn_version': data['fn_version'],
      });

      _debug.log('EdgeFunction', 'Full response body: ${response.body}');

      return ProcessingResult.fromJson(data);
    }

    // Parse error from Edge Function response
    String errorMessage = 'Errore server (${response.statusCode})';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        errorMessage = errorData['error'].toString();
      }
    } catch (_) {}

    _debug.error('EdgeFunction', 'Non-200 response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 500) {
      throw Exception('Errore Configurazione: $errorMessage');
    }
    throw Exception('Errore Elaborazione: $errorMessage');
  }

  /// Check processing status for a drawing
  Future<DrawingStatus> checkStatus(String drawingId) async {
    try {
      final response = await _supabase
          .from('drawings')
          .select('model_status, processing_step, processed_image_url, model_3d_url, processing_error, original_image_url, thumbnail_url')
          .eq('id', drawingId)
          .single();

      return DrawingStatus.fromJson(response);
    } catch (e) {
      _debug.error('Status', 'Status check error', error: e);
      rethrow;
    }
  }

  /// Stream processing status updates using Supabase Realtime
  Stream<DrawingStatus> watchStatus(String drawingId) {
    return _supabase
        .from('drawings')
        .stream(primaryKey: ['id'])
        .eq('id', drawingId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Drawing not found');
          }
          return DrawingStatus.fromJson(data.first);
        });
  }
}

/// Result of AI processing
class ProcessingResult {
  final bool success;
  final String? processedImageUrl;
  final String? conceptUrl;
  final String? model3dUrl;
  final int estTimeSeconds;
  final String? error;

  ProcessingResult({
    required this.success,
    this.processedImageUrl,
    this.conceptUrl,
    this.model3dUrl,
    this.estTimeSeconds = 0,
    this.error,
  });

  factory ProcessingResult.fromJson(Map<String, dynamic> json) {
    return ProcessingResult(
      success: json['success'] ?? false,
      processedImageUrl: json['processed_image_url'],
      conceptUrl: json['concept_url'],
      model3dUrl: json['model_3d_url'],
      estTimeSeconds: json['est_time_seconds'] ?? 0,
      error: json['error'],
    );
  }
}

/// Drawing processing status
class DrawingStatus {
  final String status;
  final String? processingStep;
  final String? processedImageUrl;
  final String? model3dUrl;
  final String? originalImageUrl;
  final String? thumbnailUrl;
  final String? error;

  DrawingStatus({
    required this.status,
    this.processingStep,
    this.processedImageUrl,
    this.model3dUrl,
    this.originalImageUrl,
    this.thumbnailUrl,
    this.error,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing' || status == 'processing_3d';
  bool get isProcessing3D => status == 'processing_3d';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  /// Get the best available image URL (use processed, then thumbnail, then original)
  String? get displayImageUrl => processedImageUrl ?? thumbnailUrl ?? originalImageUrl;

  /// Get progress percentage (0.0 - 1.0) based on processing step
  double get progressPercent {
    switch (processingStep) {
      case 'uploading':
        return 0.10;
      case 'validating':
        return 0.25;
      case 'removing_background':
        return 0.35;
      case 'stylizing':
        return 0.55;
      case 'generating_3d':
        return 0.65;
      case 'finalizing':
        return 0.85;
      case 'waiting_3d':
        return 0.90;
      default:
        if (isCompleted) return 1.0;
        if (isProcessing3D) return 0.70;
        if (isProcessing) return 0.20;
        return 0.0;
    }
  }

  /// Get human-readable step label in Italian
  String get stepLabel {
    switch (processingStep) {
      case 'uploading':
        return 'Caricamento immagine...';
      case 'validating':
        return 'Validazione disegno con AI...';
      case 'removing_background':
        return 'Rimozione sfondo...';
      case 'stylizing':
        return 'Trasformazione stile Cuppy...';
      case 'generating_3d':
        return 'Avvio generazione 3D...';
      case 'finalizing':
        return 'Finalizzazione...';
      case 'waiting_3d':
        return 'Concept 2D pronto! 3D in generazione...';
      default:
        if (isCompleted) return 'Completato!';
        if (isProcessing3D) return 'Generazione modello 3D in corso...';
        if (isProcessing) return 'Elaborazione in corso...';
        return 'In attesa...';
    }
  }

  factory DrawingStatus.fromJson(Map<String, dynamic> json) {
    return DrawingStatus(
      status: json['model_status'] ?? 'pending',
      processingStep: json['processing_step'],
      processedImageUrl: json['processed_image_url'],
      model3dUrl: json['model_3d_url'],
      originalImageUrl: json['original_image_url'],
      thumbnailUrl: json['thumbnail_url'],
      error: json['processing_error'],
    );
  }
}

/// Exception thrown when the uploaded image fails drawing validation
class DrawingValidationException implements Exception {
  final String message;
  DrawingValidationException(this.message);

  @override
  String toString() => message;
}
