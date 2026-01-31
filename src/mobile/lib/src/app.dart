import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/drawing_notifier_service.dart';

class Draw2ToyApp extends ConsumerStatefulWidget {
  const Draw2ToyApp({super.key});

  @override
  ConsumerState<Draw2ToyApp> createState() => _Draw2ToyAppState();
}

class _Draw2ToyAppState extends ConsumerState<Draw2ToyApp> {
  DrawingNotifierService? _notifier;

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);

    // Start/stop notifier based on auth
    if (authState.isAuthenticated) {
      if (_notifier == null) {
        _notifier = DrawingNotifierService(rootNavigatorKey);
        _notifier!.start();
      }
    } else {
      _notifier?.stop();
      _notifier = null;
    }

    return MaterialApp.router(
      title: 'Draw2Toy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
