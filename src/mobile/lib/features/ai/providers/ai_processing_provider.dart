import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/debug_log_service.dart';
import '../services/ai_processing_service.dart';

/// Provider for AI Processing Service
final aiProcessingServiceProvider = Provider<AIProcessingService>((ref) {
  return AIProcessingService();
});

/// State for AI processing
class AIProcessingState {
  final bool isProcessing;
  final double progress;
  final String? currentStep;
  final ProcessingResult? result;
  final String? error;

  const AIProcessingState({
    this.isProcessing = false,
    this.progress = 0.0,
    this.currentStep,
    this.result,
    this.error,
  });

  AIProcessingState copyWith({
    bool? isProcessing,
    double? progress,
    String? currentStep,
    ProcessingResult? result,
    String? error,
  }) {
    return AIProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

/// Provider for managing AI processing state
final aiProcessingProvider =
    StateNotifierProvider<AIProcessingNotifier, AIProcessingState>((ref) {
  return AIProcessingNotifier(ref.read(aiProcessingServiceProvider));
});

class AIProcessingNotifier extends StateNotifier<AIProcessingState> {
  final AIProcessingService _service;

  AIProcessingNotifier(this._service) : super(const AIProcessingState());

  final _debug = DebugLogService.instance;

  /// Process a drawing through the AI pipeline
  Future<ProcessingResult> processDrawing({
    required String drawingId,
    required String userId,
  }) async {
    _debug.log('Provider', 'processDrawing called: drawingId=$drawingId');

    state = state.copyWith(
      isProcessing: true,
      progress: 0.1,
      currentStep: 'Preparing your drawing...',
      error: null,
    );

    try {
      state = state.copyWith(
        progress: 0.2,
        currentStep: 'Validating drawing...',
      );

      _debug.log('Provider', 'Calling AIProcessingService.processDrawing');

      final result = await _service.processDrawing(
        drawingId: drawingId,
        userId: userId,
      );

      _debug.success('Provider', 'Processing complete', data: {
        'success': result.success,
        'has_processed_image': result.processedImageUrl != null,
        'has_3d_model': result.model3dUrl != null,
      });

      state = state.copyWith(
        progress: 1.0,
        currentStep: 'Complete!',
        isProcessing: false,
        result: result,
      );

      return result;
    } on DrawingValidationException catch (e) {
      _debug.warning('Provider', 'Drawing validation failed: $e');
      state = state.copyWith(
        isProcessing: false,
        error: e.message,
        currentStep: 'Not a valid drawing',
      );
      rethrow;
    } catch (e) {
      _debug.error('Provider', 'Processing failed', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
        currentStep: null,
      );
      rethrow;
    }
  }

  /// Watch drawing status in real-time
  Stream<DrawingStatus> watchDrawingStatus(String drawingId) {
    return _service.watchStatus(drawingId);
  }

  /// Reset processing state
  void reset() {
    state = const AIProcessingState();
  }
}

/// Provider to watch a specific drawing's processing status
final drawingStatusProvider =
    StreamProvider.family<DrawingStatus, String>((ref, drawingId) {
  final service = ref.read(aiProcessingServiceProvider);
  return service.watchStatus(drawingId);
});
