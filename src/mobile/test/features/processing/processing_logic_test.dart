import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/ai/services/ai_processing_service.dart';

void main() {
  group('DrawingStatus progressPercent', () {
    DrawingStatus makeStatus({String status = 'processing', String? step}) {
      return DrawingStatus.fromJson({
        'model_status': status,
        'processing_step': step,
      });
    }

    test('uploading = 10%', () {
      expect(makeStatus(step: 'uploading').progressPercent, 0.10);
    });

    test('validating = 25%', () {
      expect(makeStatus(step: 'validating').progressPercent, 0.25);
    });

    test('removing_background = 35%', () {
      expect(makeStatus(step: 'removing_background').progressPercent, 0.35);
    });

    test('stylizing = 55%', () {
      expect(makeStatus(step: 'stylizing').progressPercent, 0.55);
    });

    test('generating_3d = 65%', () {
      expect(makeStatus(step: 'generating_3d').progressPercent, 0.65);
    });

    test('finalizing = 85%', () {
      expect(makeStatus(step: 'finalizing').progressPercent, 0.85);
    });

    test('waiting_3d = 90%', () {
      expect(makeStatus(step: 'waiting_3d').progressPercent, 0.90);
    });

    test('completed with no step = 100%', () {
      expect(makeStatus(status: 'completed').progressPercent, 1.0);
    });

    test('processing_3d with no step = 70%', () {
      expect(makeStatus(status: 'processing_3d').progressPercent, 0.70);
    });

    test('processing with no step = 20%', () {
      expect(makeStatus().progressPercent, 0.20);
    });

    test('pending with no step = 0%', () {
      expect(makeStatus(status: 'pending').progressPercent, 0.0);
    });
  });

  group('DrawingStatus stepLabel (Italian)', () {
    DrawingStatus makeStatus({String status = 'processing', String? step}) {
      return DrawingStatus.fromJson({
        'model_status': status,
        'processing_step': step,
      });
    }

    test('uploading label', () {
      expect(makeStatus(step: 'uploading').stepLabel, 'Caricamento immagine...');
    });

    test('validating label', () {
      expect(makeStatus(step: 'validating').stepLabel, 'Validazione disegno con AI...');
    });

    test('removing_background label', () {
      expect(makeStatus(step: 'removing_background').stepLabel, 'Rimozione sfondo...');
    });

    test('stylizing label', () {
      expect(makeStatus(step: 'stylizing').stepLabel, 'Trasformazione stile Cuppy...');
    });

    test('generating_3d label', () {
      expect(makeStatus(step: 'generating_3d').stepLabel, 'Avvio generazione 3D...');
    });

    test('finalizing label', () {
      expect(makeStatus(step: 'finalizing').stepLabel, 'Finalizzazione...');
    });

    test('waiting_3d label', () {
      expect(makeStatus(step: 'waiting_3d').stepLabel, 'Concept 2D pronto! 3D in generazione...');
    });

    test('completed label', () {
      expect(makeStatus(status: 'completed').stepLabel, 'Completato!');
    });

    test('processing_3d default label', () {
      expect(makeStatus(status: 'processing_3d').stepLabel, 'Generazione modello 3D in corso...');
    });

    test('processing default label', () {
      expect(makeStatus().stepLabel, 'Elaborazione in corso...');
    });

    test('pending default label', () {
      expect(makeStatus(status: 'pending').stepLabel, 'In attesa...');
    });
  });

  group('ProcessingResult concept fields', () {
    test('parses concept_url and est_time_seconds', () {
      final result = ProcessingResult.fromJson({
        'success': true,
        'processed_image_url': 'https://example.com/processed.png',
        'concept_url': 'https://example.com/concept.png',
        'est_time_seconds': 120,
      });
      expect(result.conceptUrl, 'https://example.com/concept.png');
      expect(result.estTimeSeconds, 120);
    });

    test('defaults est_time_seconds to 0', () {
      final result = ProcessingResult.fromJson({'success': true});
      expect(result.estTimeSeconds, 0);
      expect(result.conceptUrl, isNull);
    });

    test('parses model_3d_url', () {
      final result = ProcessingResult.fromJson({
        'success': true,
        'model_3d_url': 'https://example.com/model.glb',
        'est_time_seconds': 0,
      });
      expect(result.model3dUrl, 'https://example.com/model.glb');
      expect(result.estTimeSeconds, 0);
    });
  });

  group('DrawingStatus edge cases', () {
    test('isProcessing3D is true for processing_3d', () {
      final s = DrawingStatus.fromJson({'model_status': 'processing_3d'});
      expect(s.isProcessing3D, true);
      expect(s.isProcessing, true); // also true
    });

    test('displayImageUrl prefers processed over original', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'completed',
        'processed_image_url': 'processed',
        'original_image_url': 'original',
      });
      expect(s.displayImageUrl, 'processed');
    });

    test('error field from processing_error', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'failed',
        'processing_error': 'timeout',
      });
      expect(s.error, 'timeout');
      expect(s.isFailed, true);
    });

    test('processingStep from json', () {
      final s = DrawingStatus.fromJson({
        'model_status': 'processing',
        'processing_step': 'removing_background',
      });
      expect(s.processingStep, 'removing_background');
    });
  });
}
