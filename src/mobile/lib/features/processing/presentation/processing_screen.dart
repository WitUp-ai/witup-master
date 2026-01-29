import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/debug_overlay.dart';
import '../../../core/services/debug_log_service.dart';
import '../../ai/providers/ai_processing_provider.dart';
import '../../ai/services/ai_processing_service.dart';
import 'dart:async';

/// Processing screen - shows AI processing progress and results
class ProcessingScreen extends ConsumerStatefulWidget {
  final String drawingId;

  const ProcessingScreen({
    super.key,
    required this.drawingId,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Start processing when screen loads
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    final userId = _getUserId();
    DebugLogService.instance.clear();
    DebugLogService.instance.log('Pipeline', 'Start Creating pressed for drawing: ${widget.drawingId}');

    if (userId != null) {
      DebugLogService.instance.log('Pipeline', 'User authenticated: $userId');
      try {
        await ref.read(aiProcessingProvider.notifier).processDrawing(
              drawingId: widget.drawingId,
              userId: userId,
            );
      } catch (e) {
        // Error is handled in the provider state
      }
    } else {
      DebugLogService.instance.error('Pipeline', 'No authenticated user!');
    }
  }

  String? _getUserId() {
    // Get user ID from Supabase auth
    return Supabase.instance.client.auth.currentUser?.id;
  }

  @override
  Widget build(BuildContext context) {
    final processingState = ref.watch(aiProcessingProvider);
    final statusAsync = ref.watch(drawingStatusProvider(widget.drawingId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Creating Magic'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: statusAsync.when(
                loading: () => _buildProcessingView(processingState),
                error: (error, _) => _buildErrorView(error.toString()),
                data: (status) {
                  if (status.isCompleted) {
                    return _buildCompletedView(status);
                  } else if (status.isFailed) {
                    return _buildErrorView(status.error ?? 'Processing failed');
                  } else {
                    return _buildProcessingView(processingState);
                  }
                },
              ),
            ),
            const DebugOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView(AIProcessingState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated magic wand icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.magicGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowLarge,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 3.seconds)
                .then()
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 500.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.1, 1.1),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                ),

            const SizedBox(height: AppTheme.space2XL),

            // Status text
            Text(
              state.currentStep ?? 'Starting magic...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1500.ms, color: AppTheme.primaryColor),

            const SizedBox(height: AppTheme.spaceL),

            // Progress bar
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: state.progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.magicGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ).animate().fadeIn(),

            const SizedBox(height: AppTheme.spaceM),

            Text(
              '${(state.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppTheme.space2XL),

            // Fun facts while waiting
            _buildFunFact(),
          ],
        ),
      ),
    );
  }

  Widget _buildFunFact() {
    final facts = [
      'Your drawing is being analyzed by AI...',
      'Removing the background...',
      'Finding the perfect 3D shape...',
      'Adding magical touches...',
      'Almost there!',
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Text(
              facts[DateTime.now().second % facts.length],
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildCompletedView(DrawingStatus status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        children: [
          // Success animation
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .then()
              .shake(duration: 500.ms),

          const SizedBox(height: AppTheme.spaceL),

          Text(
            'Magic Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
          ).animate().fadeIn().slideY(begin: 0.3),

          const SizedBox(height: AppTheme.spaceXL),

          // Processed image preview
          if (status.processedImageUrl != null) ...[
            const Text(
              'Your processed drawing:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.shadowMedium,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                status.processedImageUrl!,
                height: 250,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 250,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stack) {
                  return Container(
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
          ],

          const SizedBox(height: AppTheme.spaceXL),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status.model3dUrl != null
                      ? () => context.go('/viewer/${widget.drawingId}')
                      : null,
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('View in AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

          if (status.model3dUrl == null) ...[
            const SizedBox(height: AppTheme.spaceM),
            Text(
              '3D model generation requires API configuration.\nContact support to enable this feature.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    // Detect validation errors for user-friendly messaging
    final isValidationError = error.contains('not_a_drawing') ||
        error.contains('Not a valid drawing') ||
        error.contains('does not appear to be a drawing');

    final title = isValidationError
        ? 'Not a Drawing'
        : 'Oops! Something went wrong';
    final icon = isValidationError ? Icons.image_not_supported : Icons.error_outline;
    final color = isValidationError ? Colors.orange : AppTheme.errorColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
            ).animate().shake(),

            const SizedBox(height: AppTheme.spaceL),

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppTheme.spaceM),

            Text(
              isValidationError
                  ? 'The image you uploaded doesn\'t look like a drawing. Please try with a photo of a hand-drawn sketch on paper.'
                  : error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppTheme.spaceXL),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
                const SizedBox(width: AppTheme.spaceM),
                ElevatedButton.icon(
                  onPressed: _startProcessing,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
