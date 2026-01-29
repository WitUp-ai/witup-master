import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with Replicate AI API
/// Documentation: https://replicate.com/docs/reference/http
class ReplicateService {
  static const String _baseUrl = 'https://api.replicate.com/v1';
  final String _apiToken;

  ReplicateService({required String apiToken}) : _apiToken = apiToken;

  /// Generate a 3D model from an image using TripoSR model
  /// Model: camenduru/triposr
  Future<ReplicatePrediction> generate3DFromImage({
    required String imageUrl,
    required String drawingId,
    String style = 'cartoon',
    int mcResolution = 256,
    double foregroundRatio = 0.9,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predictions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'version': 'ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5', // TripoSR
          'input': {
            'image': imageUrl,
            'mc_resolution': mcResolution,
            'foreground_ratio': foregroundRatio,
            'style': style,
          },
          'webhook': null, // TODO: Add webhook for async processing
          'webhook_events_filter': ['completed'],
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ReplicatePrediction.fromJson(data);
      } else {
        throw ReplicateException(
          'Failed to create prediction: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('Replicate API error: $e');
      rethrow;
    }
  }

  /// Remove background from image using rembg model
  Future<ReplicatePrediction> removeBackground({
    required String imageUrl,
    required String drawingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predictions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'version': 'fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003', // rembg
          'input': {
            'image': imageUrl,
            'model': 'u2net',
            'return_mask': false,
            'alpha_matting': true,
            'alpha_matting_foreground_threshold': 240,
            'alpha_matting_background_threshold': 10,
            'alpha_matting_erode_size': 10,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ReplicatePrediction.fromJson(data);
      } else {
        throw ReplicateException(
          'Failed to remove background: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('Replicate background removal error: $e');
      rethrow;
    }
  }

  /// Get prediction status and result
  Future<ReplicatePrediction> getPrediction(String predictionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/predictions/$predictionId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReplicatePrediction.fromJson(data);
      } else {
        throw ReplicateException(
          'Failed to get prediction: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('Replicate get prediction error: $e');
      rethrow;
    }
  }

  /// Cancel a running prediction
  Future<void> cancelPrediction(String predictionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predictions/$predictionId/cancel'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw ReplicateException(
          'Failed to cancel prediction: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('Replicate cancel prediction error: $e');
      rethrow;
    }
  }

  /// List all predictions (for admin/debug purposes)
  Future<List<ReplicatePrediction>> listPredictions({
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      };
      final uri = Uri.parse('$_baseUrl/predictions').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        return results.map((json) => ReplicatePrediction.fromJson(json)).toList();
      } else {
        throw ReplicateException(
          'Failed to list predictions: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      debugPrint('Replicate list predictions error: $e');
      rethrow;
    }
  }

  /// Upload image to Replicate and get URL
  /// Note: Replicate accepts public URLs, but for private images we need to upload
  Future<String> uploadImage(File imageFile) async {
    try {
      // For now, we assume images are already publicly accessible via Supabase signed URLs
      // In production, you might need to implement direct upload to Replicate
      throw UnimplementedError('Direct image upload to Replicate not implemented. Use public URLs.');
    } catch (e) {
      debugPrint('Image upload error: $e');
      rethrow;
    }
  }

  /// Get API headers with authentication
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Token $_apiToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}

/// Replicate prediction response model
class ReplicatePrediction {
  final String id;
  final String version;
  final Map<String, dynamic> input;
  final String status;
  final String? output;
  final String? error;
  final Map<String, dynamic>? metrics;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? urls;

  ReplicatePrediction({
    required this.id,
    required this.version,
    required this.input,
    required this.status,
    this.output,
    this.error,
    this.metrics,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.urls,
  });

  factory ReplicatePrediction.fromJson(Map<String, dynamic> json) {
    return ReplicatePrediction(
      id: json['id'],
      version: json['version'],
      input: Map<String, dynamic>.from(json['input'] ?? {}),
      status: json['status'],
      output: json['output'],
      error: json['error'],
      metrics: json['metrics'] != null ? Map<String, dynamic>.from(json['metrics']) : null,
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      urls: json['urls'] != null ? Map<String, dynamic>.from(json['urls']) : null,
    );
  }

  bool get isCompleted => status == 'succeeded';
  bool get isProcessing => status == 'processing' || status == 'starting';
  bool get isFailed => status == 'failed' || status == 'canceled';
  bool get isPending => status == 'queued';

  /// Get the output URL for 3D model or processed image
  String? get outputUrl {
    if (output is String) {
      return output;
    } else if (output is List) {
      final list = output as List;
      if (list.isNotEmpty && list.first is String) {
        return list.first;
      }
    }
    return null;
  }

  /// Get processing time in seconds
  double? get processingTime {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!).inMilliseconds / 1000.0;
    }
    return null;
  }
}

/// Replicate API exception
class ReplicateException implements Exception {
  final String message;
  final String? responseBody;

  ReplicateException(this.message, [this.responseBody]);

  @override
  String toString() {
    if (responseBody != null) {
      return 'ReplicateException: $message\nResponse: $responseBody';
    }
    return 'ReplicateException: $message';
  }
}

/// Helper class for Replicate model configurations
class ReplicateModels {
  // Background removal models
  static const String rembg = 'fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003';
  
  // 3D generation models
  static const String tripoSR = 'ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5';
  static const String shapE = 'a2eae9e8b5b4b8c5c5c5c5c5c5c5c5c5c5c5c5c5c5'; // Example, update with actual
  
  // Image enhancement models
  static const String realESRGAN = '42fed1c4974146d4d2414e2be2c5277c7fcf05fcc3a73abf41610695738c1d7b';
}

/// Configuration for Replicate API
class ReplicateConfig {
  // API token must be read from system_config table or Edge Function env vars.
  // Never hardcode tokens in client code.
  static const String baseUrl = 'https://api.replicate.com/v1';
  
  // Timeout settings
  static const Duration predictionTimeout = Duration(seconds: 120);
  static const Duration pollingInterval = Duration(seconds: 2);
  
  // Model settings
  static const Map<String, dynamic> tripoSRSettings = {
    'mc_resolution': 256,
    'foreground_ratio': 0.9,
    'style': 'cartoon',
  };
  
  static const Map<String, dynamic> rembgSettings = {
    'model': 'u2net',
    'return_mask': false,
    'alpha_matting': true,
    'alpha_matting_foreground_threshold': 240,
    'alpha_matting_background_threshold': 10,
    'alpha_matting_erode_size': 10,
  };
}