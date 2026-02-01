import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'debug_log_service.dart';

/// Global notifier that listens to Supabase Realtime for drawing status changes.
/// Shows in-app SnackBar when a drawing's 3D model becomes ready.
class DrawingNotifierService {
  final GlobalKey<NavigatorState> navigatorKey;
  StreamSubscription? _subscription;
  final _debug = DebugLogService.instance;

  /// Track known statuses to detect transitions
  final Map<String, String> _knownStatuses = {};

  DrawingNotifierService(this.navigatorKey);

  void start() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _debug.warning('DrawingNotifier', 'No authenticated user, skipping');
      return;
    }

    _debug.log('DrawingNotifier', 'Starting Realtime listener for user ${user.id}');

    _subscription?.cancel();
    _subscription = Supabase.instance.client
        .from('drawings')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen((rows) {
          for (final row in rows) {
            final drawingId = row['id'] as String;
            final status = row['model_status'] as String? ?? 'pending';
            final previousStatus = _knownStatuses[drawingId];
            _knownStatuses[drawingId] = status;

            // Detect transition to completed (3D ready)
            if (previousStatus != null &&
                previousStatus != 'completed' &&
                status == 'completed' &&
                row['model_3d_url'] != null) {
              _debug.success('DrawingNotifier', '3D ready for drawing $drawingId');
              _showNotification(drawingId, row['title'] as String?);
            }
          }
        }, onError: (e) {
          _debug.error('DrawingNotifier', 'Realtime error', error: e);
        });
  }

  void _showNotification(String drawingId, String? title) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final drawingName = title ?? 'Il tuo disegno';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.view_in_ar, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modello 3D Pronto!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$drawingName è pronto per la visualizzazione 3D',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'VEDI',
          textColor: Colors.white,
          onPressed: () {
            context.go('/viewer/$drawingId');
          },
        ),
      ),
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _knownStatuses.clear();
    _debug.log('DrawingNotifier', 'Stopped');
  }

  void dispose() {
    stop();
  }
}

/// Provider for DrawingNotifierService - requires navigatorKey
final drawingNotifierProvider = Provider<DrawingNotifierService>((ref) {
  throw UnimplementedError('Must be overridden with navigatorKey');
});
