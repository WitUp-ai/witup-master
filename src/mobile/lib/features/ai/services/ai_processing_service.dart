import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/debug_log_service.dart';

/// Service to handle AI processing of drawings
class AIProcessingService {
  final SupabaseClient _supabase;
  final String _supabaseUrl;

  final _debug = DebugLogService.instance;

  AIProcessingService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client,
        _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

  /// Trigger processing for a drawing
  /// For MVP: processes directly in client, marks as completed
  /// For Production: calls Edge Function with AI APIs
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

      // Try Edge Function first (if deployed)
      try {
        _debug.log('Processing', 'Attempting Edge Function call to $_supabaseUrl/functions/v1/process-drawing');
        final result = await _tryEdgeFunction(drawingId, userId);
        if (result != null) {
          _debug.success('Processing', 'Edge Function returned successfully', data: {
            'has_processed_image': result.processedImageUrl != null,
            'has_3d_model': result.model3dUrl != null,
          });
          return result;
        }
        _debug.warning('Processing', 'Edge Function returned null, falling back to MVP mode');
      } catch (e) {
        _debug.warning('Processing', 'Edge Function failed, falling back to MVP mode: $e');
      }

      // Fallback: Direct processing (MVP mode)
      _debug.log('Processing', 'Using MVP direct processing (simulated)');
      return await _processDirectly(drawingId, userId);
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

  /// Try to use Edge Function (production mode)
  Future<ProcessingResult?> _tryEdgeFunction(String drawingId, String userId) async {
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null || _supabaseUrl.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$_supabaseUrl/functions/v1/process-drawing'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'drawing_id': drawingId,
        'user_id': userId,
      }),
    ).timeout(const Duration(seconds: 45), onTimeout: () {
      throw Exception('Edge Function timeout (45s)');
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
        'has_processed_image': data['processed_image_url'] != null,
        'has_3d_model': data['model_3d_url'] != null,
        'processing_time_ms': data['processing_time_ms'],
      });
      return ProcessingResult.fromJson(data);
    }

    _debug.warning('EdgeFunction', 'Non-200 response: ${response.statusCode} - ${response.body}');
    return null; // Fallback to direct processing
  }

  /// Direct processing (MVP mode - no external APIs)
  Future<ProcessingResult> _processDirectly(String drawingId, String userId) async {
    // Simulate processing delay for UX
    _debug.warning('MVP', 'Simulating 2s processing delay (no real AI)');
    await Future.delayed(const Duration(seconds: 2));

    // Get the drawing to retrieve original image URL
    final drawing = await _supabase
        .from('drawings')
        .select('original_image_url')
        .eq('id', drawingId)
        .single();

    final originalPath = drawing['original_image_url'] as String?;
    String? processedUrl;

    // Generate signed URL for the original image (as processed for MVP)
    if (originalPath != null) {
      try {
        processedUrl = await _supabase.storage
            .from('drawings-original')
            .createSignedUrl(originalPath, 86400); // 24 hours
      } catch (e) {
        debugPrint('Could not create signed URL: $e');
      }
    }

    // Update drawing as completed
    _debug.log('MVP', 'Marking drawing as completed (no 3D model in MVP mode)');
    await _supabase.from('drawings').update({
      'model_status': 'completed',
      'processing_completed_at': DateTime.now().toIso8601String(),
      'processed_image_url': processedUrl,
      // model_3d_url will be null until AI APIs are configured
    }).eq('id', drawingId);

    // Create notification
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': 'drawing_processed',
        'title': 'Your drawing is ready!',
        'message': 'Your drawing has been processed. Tap to view!',
        'action_url': '/viewer/$drawingId',
        'metadata': {'drawing_id': drawingId},
      });
    } catch (e) {
      debugPrint('Could not create notification: $e');
    }

    return ProcessingResult(
      success: true,
      processedImageUrl: processedUrl,
      model3dUrl: null, // 3D requires AI API configuration
    );
  }

  /// Check processing status for a drawing
  Future<DrawingStatus> checkStatus(String drawingId) async {
    try {
      final response = await _supabase
          .from('drawings')
          .select('model_status, processed_image_url, model_3d_url, processing_error, original_image_url')
          .eq('id', drawingId)
          .single();

      return DrawingStatus.fromJson(response);
    } catch (e) {
      debugPrint('Status check error: $e');
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
  final String? model3dUrl;
  final String? error;

  ProcessingResult({
    required this.success,
    this.processedImageUrl,
    this.model3dUrl,
    this.error,
  });

  factory ProcessingResult.fromJson(Map<String, dynamic> json) {
    return ProcessingResult(
      success: json['success'] ?? false,
      processedImageUrl: json['processed_image_url'],
      model3dUrl: json['model_3d_url'],
      error: json['error'],
    );
  }
}

/// Drawing processing status
class DrawingStatus {
  final String status;
  final String? processedImageUrl;
  final String? model3dUrl;
  final String? originalImageUrl;
  final String? error;

  DrawingStatus({
    required this.status,
    this.processedImageUrl,
    this.model3dUrl,
    this.originalImageUrl,
    this.error,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing' || status == 'processing_3d';
  bool get isProcessing3D => status == 'processing_3d';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  /// Get the best available image URL
  String? get displayImageUrl => processedImageUrl ?? originalImageUrl;

  factory DrawingStatus.fromJson(Map<String, dynamic> json) {
    return DrawingStatus(
      status: json['model_status'] ?? 'pending',
      processedImageUrl: json['processed_image_url'],
      model3dUrl: json['model_3d_url'],
      originalImageUrl: json['original_image_url'],
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
