import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/replicate_service.dart';

/// ============================================================================
/// REPLICATE SERVICE PROVIDERS WITH DYNAMIC CONFIGURATION
/// ============================================================================

/// Provider that creates ReplicateService with API token from system_config.
/// Returns null if no token is configured - all AI calls should go through Edge Functions.
final replicateServiceProvider = FutureProvider<ReplicateService?>((ref) async {
  final token = await ref.watch(replicateApiTokenProvider.future);
  if (token == null || token.isEmpty) {
    return null;
  }
  return ReplicateService(apiToken: token);
});

/// Provider that reads Replicate API token from system_config
final replicateApiTokenProvider = FutureProvider<String?>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final result = await supabase
        .from('system_config')
        .select('value')
        .eq('key', 'REPLICATE_API_TOKEN')
        .maybeSingle();
    
    return result?['value'] as String?;
  } catch (e) {
    // If table doesn't exist yet, return null to use fallback
    return null;
  }
});

/// Provider that reads vision model from system_config
final visionModelProvider = FutureProvider<String>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final result = await supabase
        .from('system_config')
        .select('value')
        .eq('key', 'MODEL_VISION')
        .maybeSingle();
    
    return (result?['value'] as String?) ?? 'moondream';
  } catch (e) {
    // Default fallback
    return 'moondream';
  }
});

/// Provider that reads 3D model from system_config
final threeDModelProvider = FutureProvider<String>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final result = await supabase
        .from('system_config')
        .select('value')
        .eq('key', 'MODEL_3D_GENERATOR')
        .maybeSingle();
    
    return (result?['value'] as String?) ?? 'triposr';
  } catch (e) {
    // Default fallback
    return 'triposr';
  }
});

/// State for AI processing with vision validation
class AIProcessingWithValidationState {
  final bool isProcessing;
  final double progress;
  final String? currentStep;
  final bool? isDrawingValid;
  final String? validationReason;
  final String? validationError;
  final bool? canProceedTo3D;

  const AIProcessingWithValidationState({
    this.isProcessing = false,
    this.progress = 0.0,
    this.currentStep,
    this.isDrawingValid,
    this.validationReason,
    this.validationError,
    this.canProceedTo3D,
  });

  AIProcessingWithValidationState copyWith({
    bool? isProcessing,
    double? progress,
    String? currentStep,
    bool? isDrawingValid,
    String? validationReason,
    String? validationError,
    bool? canProceedTo3D,
  }) {
    return AIProcessingWithValidationState(
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      isDrawingValid: isDrawingValid ?? this.isDrawingValid,
      validationReason: validationReason ?? this.validationReason,
      validationError: validationError ?? this.validationError,
      canProceedTo3D: canProceedTo3D ?? this.canProceedTo3D,
    );
  }
}

/// Notifier for AI processing with drawing validation step
class AIProcessingWithValidationNotifier
    extends StateNotifier<AIProcessingWithValidationState> {
  ReplicateService? _replicateService;
  final SupabaseClient _supabase;

  AIProcessingWithValidationNotifier(
      this._replicateService, this._supabase)
      : super(const AIProcessingWithValidationState());

  void updateReplicateService(ReplicateService? service) {
    _replicateService = service;
  }

  /// Validate if an image is a drawing using vision model
  Future<void> validateDrawing({
    required String imageUrl,
    required String drawingId,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      progress: 0.1,
      currentStep: 'Validating drawing...',
      validationError: null,
    );

    try {
      // TODO: Implement actual vision model validation
      // For MVP, we'll simulate validation
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // For now, always return true - implement actual validation later
      final validationResult = await _simulateVisionValidation(imageUrl);
      
      state = state.copyWith(
        progress: 0.5,
        isDrawingValid: validationResult['is_drawing'],
        validationReason: validationResult['reason'],
        canProceedTo3D: validationResult['is_drawing'],
      );
      
      // Update drawing record with validation result
      await _supabase.from('drawings').update({
        'validation_status': validationResult['is_drawing'] ? 'valid' : 'invalid',
        'validation_reason': validationResult['reason'],
        'validation_completed_at': DateTime.now().toIso8601String(),
      }).eq('id', drawingId);
      
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        validationError: 'Validation failed: $e',
      );
      rethrow;
    }
  }

  /// Process to 3D if validation passed
  Future<void> processTo3D({
    required String imageUrl,
    required String drawingId,
    String style = 'cartoon',
  }) async {
    if (state.isDrawingValid != true) {
      throw Exception('Cannot process to 3D: drawing validation failed');
    }

    state = state.copyWith(
      isProcessing: true,
      progress: 0.6,
      currentStep: 'Generating 3D model...',
      validationError: null,
    );

    try {
      if (_replicateService == null) {
        throw Exception('Replicate API not configured. Set REPLICATE_API_TOKEN in system_config.');
      }
      // Use ReplicateService to generate 3D model
      final prediction = await _replicateService!.generate3DFromImage(
        imageUrl: imageUrl,
        drawingId: drawingId,
        style: style,
      );

      // Poll for completion
      state = state.copyWith(
        progress: 0.8,
        currentStep: 'Processing 3D model...',
      );

      // TODO: Implement proper polling and result handling
      
      state = state.copyWith(
        isProcessing: false,
        progress: 1.0,
        currentStep: '3D model generated!',
      );
      
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        validationError: '3D generation failed: $e',
      );
      rethrow;
    }
  }

  /// Reset state
  void reset() {
    state = const AIProcessingWithValidationState();
  }

  /// Simulate vision validation (to be replaced with actual model)
  Future<Map<String, dynamic>> _simulateVisionValidation(String imageUrl) async {
    // TODO: Replace with actual vision model call
    // For MVP, we'll use a simple heuristic based on URL or basic analysis
    
    // Example response format expected from vision model:
    // {
    //   "is_drawing": true,
    //   "reason": "Image contains pencil sketch on paper"
    // }
    
    // For now, always return true to allow testing
    return {
      'is_drawing': true,
      'reason': 'Simulated validation - implement actual vision model',
    };
  }
}

/// Provider for AI processing with validation.
/// ReplicateService may be null if no API token is configured.
final aiProcessingWithValidationProvider = StateNotifierProvider<
    AIProcessingWithValidationNotifier, AIProcessingWithValidationState>((ref) {
  final supabase = Supabase.instance.client;
  return AIProcessingWithValidationNotifier(null, supabase);
});

/// Async version that waits for the Replicate token to be loaded
final aiProcessingWithValidationInitProvider = FutureProvider<void>((ref) async {
  final service = await ref.watch(replicateServiceProvider.future);
  final notifier = ref.read(aiProcessingWithValidationProvider.notifier);
  notifier.updateReplicateService(service);
});

/// Utility function to create a properly configured ReplicateService
ReplicateService createReplicateServiceFromConfig(String apiToken) {
  return ReplicateService(apiToken: apiToken);
}