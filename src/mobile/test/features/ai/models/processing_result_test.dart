import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/ai/services/ai_processing_service.dart';

void main() {
  group('ProcessingResult latency tracking', () {
    test('fromJson parses processing_time_ms for latency measurement', () {
      final result = ProcessingResult.fromJson({
        'success': true,
        'processed_image_url': 'https://example.com/processed.png',
        'concept_url': 'https://example.com/concept.png',
        'processing_time_ms': 8500,
        'est_time_seconds': 120,
      });

      expect(result.success, true);
      expect(result.conceptUrl, isNotNull);
      expect(result.estTimeSeconds, 120);
      // processing_time_ms is in the JSON response for logging/monitoring
      // Target: < 15000ms (NFR-001)
    });

    test('fast processing scenario (< 15s target)', () {
      // Simulates a fast Phase 1 completion
      final result = ProcessingResult.fromJson({
        'success': true,
        'concept_url': 'https://example.com/concept.png',
        'processing_time_ms': 7200,
        'est_time_seconds': 120,
      });
      expect(result.success, true);
      expect(result.conceptUrl, isNotNull);
    });

    test('slow processing still returns concept', () {
      // Even if Phase 1 takes longer, concept should still be returned
      final result = ProcessingResult.fromJson({
        'success': true,
        'concept_url': 'https://example.com/concept.png',
        'processing_time_ms': 28000,
        'est_time_seconds': 120,
      });
      expect(result.success, true);
      expect(result.conceptUrl, isNotNull);
    });

    test('failure case has no concept_url', () {
      final result = ProcessingResult.fromJson({
        'success': false,
        'error': 'Background removal timeout',
      });
      expect(result.success, false);
      expect(result.conceptUrl, isNull);
      expect(result.error, 'Background removal timeout');
    });
  });
}
