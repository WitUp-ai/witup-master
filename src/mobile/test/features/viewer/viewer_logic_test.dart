import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/ai/services/ai_processing_service.dart';

void main() {
  group('DrawingStatus for Viewer', () {
    test('completed with model_3d_url shows 3D available', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'completed',
        'model_3d_url': 'https://storage.example.com/model.glb',
        'processed_image_url': 'https://storage.example.com/processed.png',
      });
      expect(s.isCompleted, true);
      expect(s.model3dUrl, isNotNull);
      expect(s.displayImageUrl, 'https://storage.example.com/processed.png');
    });

    test('completed without model_3d_url shows 2D fallback', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'completed',
        'processed_image_url': 'https://storage.example.com/processed.png',
      });
      expect(s.isCompleted, true);
      expect(s.model3dUrl, isNull);
      expect(s.displayImageUrl, 'https://storage.example.com/processed.png');
    });

    test('processing_3d status transitions correctly', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'processing_3d',
        'processing_step': 'waiting_3d',
        'processed_image_url': 'https://storage.example.com/processed.png',
      });
      expect(s.isProcessing3D, true);
      expect(s.isProcessing, true);
      expect(s.isCompleted, false);
      expect(s.model3dUrl, isNull);
      expect(s.displayImageUrl, 'https://storage.example.com/processed.png');
      expect(s.processingStep, 'waiting_3d');
    });

    test('failed status with error message', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'failed',
        'processing_error': 'Processing timeout: stuck in processing_3d for over 10 minutes',
      });
      expect(s.isFailed, true);
      expect(s.error, contains('timeout'));
    });

    test('displayImageUrl returns original when processed is null', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'completed',
        'original_image_url': 'https://storage.example.com/original.png',
      });
      expect(s.displayImageUrl, 'https://storage.example.com/original.png');
    });

    test('displayImageUrl returns null when both are null', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'completed',
      });
      expect(s.displayImageUrl, isNull);
    });
  });
}
