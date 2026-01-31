import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/ai/services/ai_processing_service.dart';

/// Tests the complete pipeline flow by simulating the state transitions
/// that occur during a real processing cycle:
/// pending → processing → processing_3d → completed
void main() {
  group('Pipeline flow: state transitions', () {
    test('full pipeline: pending → uploading → validating → removing_bg → generating_3d → finalizing → waiting_3d → completed', () {
      final states = [
        {'model_status': 'pending', 'processing_step': null},
        {'model_status': 'processing', 'processing_step': 'uploading'},
        {'model_status': 'processing', 'processing_step': 'validating'},
        {'model_status': 'processing', 'processing_step': 'removing_background'},
        {'model_status': 'processing', 'processing_step': 'generating_3d'},
        {'model_status': 'processing', 'processing_step': 'finalizing'},
        {'model_status': 'processing_3d', 'processing_step': 'waiting_3d'},
        {
          'model_status': 'completed',
          'processing_step': 'done',
          'processed_image_url': 'https://example.com/concept.png',
          'model_3d_url': 'https://example.com/model.glb',
        },
      ];

      double lastProgress = -1;
      for (final stateJson in states) {
        final status = DrawingStatus.fromJson(stateJson);
        // Progress should monotonically increase
        expect(status.progressPercent, greaterThanOrEqualTo(lastProgress),
            reason: 'Progress should increase at step ${stateJson['processing_step'] ?? stateJson['model_status']}');
        lastProgress = status.progressPercent;
      }

      // Final state should be 100%
      expect(lastProgress, 1.0);
    });

    test('validation failure flow: pending → uploading → validating → failed', () {
      final failedStatus = DrawingStatus.fromJson({
        'model_status': 'failed',
        'processing_error': 'Not a drawing: The image appears to be a photograph',
      });

      expect(failedStatus.isFailed, true);
      expect(failedStatus.error, contains('Not a drawing'));
    });

    test('Phase 1 result triggers Phase 2', () {
      // Edge Function returns concept_url + est_time when 3D is pending
      final phase1Result = ProcessingResult.fromJson({
        'success': true,
        'processed_image_url': 'https://example.com/processed.png',
        'concept_url': 'https://example.com/processed.png',
        'est_time_seconds': 120,
      });

      expect(phase1Result.success, true);
      expect(phase1Result.conceptUrl, isNotNull);
      expect(phase1Result.estTimeSeconds, greaterThan(0));
      // This triggers _phase2Active in ProcessingScreen
    });

    test('Phase 2 completion: processing_3d → completed with model_3d_url', () {
      final before = DrawingStatus.fromJson({
        'model_status': 'processing_3d',
        'processing_step': 'waiting_3d',
        'processed_image_url': 'https://example.com/concept.png',
      });

      final after = DrawingStatus.fromJson({
        'model_status': 'completed',
        'processing_step': 'done',
        'processed_image_url': 'https://example.com/concept.png',
        'model_3d_url': 'https://example.com/model.glb',
      });

      expect(before.isProcessing3D, true);
      expect(before.model3dUrl, isNull);

      expect(after.isCompleted, true);
      expect(after.model3dUrl, isNotNull);
      // This transition triggers DrawingNotifier SnackBar
    });

    test('timeout flow: processing_3d → failed by cleanup-stale', () {
      final timedOut = DrawingStatus.fromJson({
        'model_status': 'failed',
        'processing_step': 'timeout',
        'processing_error': 'Processing timeout: stuck in processing_3d for over 10 minutes',
      });

      expect(timedOut.isFailed, true);
      expect(timedOut.processingStep, 'timeout');
      expect(timedOut.error, contains('timeout'));
    });
  });
}
