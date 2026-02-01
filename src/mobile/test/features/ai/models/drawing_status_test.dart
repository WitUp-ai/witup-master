import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/ai/services/ai_processing_service.dart';

void main() {
  group('DrawingStatus', () {
    test('fromJson parses all fields correctly', () {
      final status = DrawingStatus.fromJson({
        'model_status': 'completed',
        'processed_image_url': 'https://example.com/processed.png',
        'model_3d_url': 'https://example.com/model.glb',
        'original_image_url': 'user/original.png',
        'processing_error': null,
      });

      expect(status.status, 'completed');
      expect(status.processedImageUrl, 'https://example.com/processed.png');
      expect(status.model3dUrl, 'https://example.com/model.glb');
      expect(status.originalImageUrl, 'user/original.png');
      expect(status.error, isNull);
    });

    test('fromJson defaults to pending when model_status is null', () {
      final status = DrawingStatus.fromJson({});
      expect(status.status, 'pending');
      expect(status.isPending, isTrue);
    });

    test('isPending returns true only for pending status', () {
      expect(DrawingStatus(status: 'pending').isPending, isTrue);
      expect(DrawingStatus(status: 'processing').isPending, isFalse);
    });

    test('isProcessing returns true for processing and processing_3d', () {
      expect(DrawingStatus(status: 'processing').isProcessing, isTrue);
      expect(DrawingStatus(status: 'processing_3d').isProcessing, isTrue);
      expect(DrawingStatus(status: 'completed').isProcessing, isFalse);
    });

    test('isProcessing3D returns true only for processing_3d', () {
      expect(DrawingStatus(status: 'processing_3d').isProcessing3D, isTrue);
      expect(DrawingStatus(status: 'processing').isProcessing3D, isFalse);
    });

    test('isCompleted returns true only for completed status', () {
      expect(DrawingStatus(status: 'completed').isCompleted, isTrue);
      expect(DrawingStatus(status: 'failed').isCompleted, isFalse);
    });

    test('isFailed returns true only for failed status', () {
      expect(DrawingStatus(status: 'failed').isFailed, isTrue);
      expect(DrawingStatus(status: 'completed').isFailed, isFalse);
    });

    test('displayImageUrl prefers processedImageUrl over originalImageUrl', () {
      final status = DrawingStatus(
        status: 'completed',
        processedImageUrl: 'processed.png',
        originalImageUrl: 'original.png',
      );
      expect(status.displayImageUrl, 'processed.png');
    });

    test('displayImageUrl falls back to originalImageUrl', () {
      final status = DrawingStatus(
        status: 'completed',
        originalImageUrl: 'original.png',
      );
      expect(status.displayImageUrl, 'original.png');
    });

    test('displayImageUrl returns null when both are null', () {
      final status = DrawingStatus(status: 'pending');
      expect(status.displayImageUrl, isNull);
    });
  });

  group('ProcessingResult', () {
    test('fromJson parses successful result', () {
      final result = ProcessingResult.fromJson({
        'success': true,
        'processed_image_url': 'https://example.com/img.png',
        'model_3d_url': 'https://example.com/model.glb',
      });

      expect(result.success, isTrue);
      expect(result.processedImageUrl, 'https://example.com/img.png');
      expect(result.model3dUrl, 'https://example.com/model.glb');
      expect(result.error, isNull);
    });

    test('fromJson parses failed result', () {
      final result = ProcessingResult.fromJson({
        'success': false,
        'error': 'api_config_missing',
      });

      expect(result.success, isFalse);
      expect(result.error, 'api_config_missing');
      expect(result.processedImageUrl, isNull);
    });

    test('fromJson defaults success to false when missing', () {
      final result = ProcessingResult.fromJson({});
      expect(result.success, isFalse);
    });
  });

  group('DrawingValidationException', () {
    test('toString returns the message', () {
      final ex = DrawingValidationException('Not a drawing');
      expect(ex.toString(), 'Not a drawing');
      expect(ex.message, 'Not a drawing');
    });
  });
}
