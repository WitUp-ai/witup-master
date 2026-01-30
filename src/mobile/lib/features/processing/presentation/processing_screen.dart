import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/debug_log_service.dart';
import '../../ai/providers/ai_processing_provider.dart';
import '../../ai/services/ai_processing_service.dart';

/// Processing screen - shows real AI processing progress
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
  bool _pipelineStarted = false;
  String? _pipelineError;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    if (_pipelineStarted) return;
    _pipelineStarted = true;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    DebugLogService.instance.clear();
    DebugLogService.instance.log('Pipeline', 'Start Creating pressed for drawing: ${widget.drawingId}');

    if (userId == null) {
      setState(() => _pipelineError = 'Utente non autenticato');
      return;
    }

    try {
      await ref.read(aiProcessingProvider.notifier).processDrawing(
            drawingId: widget.drawingId,
            userId: userId,
          );
    } catch (e) {
      // Error will be reflected in the stream from DB status
      DebugLogService.instance.error('Pipeline', 'Pipeline error: $e');
      if (mounted) {
        setState(() => _pipelineError = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the REAL status from Supabase Realtime
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
        title: const Text('Creazione in Corso'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => _buildLoadingView(),
          error: (error, _) => _buildErrorView(error.toString()),
          data: (status) {
            if (status.isCompleted) {
              return _buildCompletedView(status);
            } else if (status.isFailed) {
              return _buildErrorView(status.error ?? _pipelineError ?? 'Elaborazione fallita');
            } else {
              // processing or processing_3d
              return _buildProcessingView(status);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'Connessione in corso...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView(DrawingStatus status) {
    final stepLabel = status.isProcessing3D
        ? 'Generazione modello 3D...'
        : 'Elaborazione disegno...';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
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
                .rotate(duration: 3.seconds),

            const SizedBox(height: AppTheme.space2XL),

            Text(
              stepLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1500.ms, color: AppTheme.primaryColor),

            const SizedBox(height: AppTheme.spaceL),

            // Real indeterminate progress
            const LinearProgressIndicator(
              color: AppTheme.primaryColor,
              backgroundColor: Color(0xFFE0E0E0),
            ),

            const SizedBox(height: AppTheme.space2XL),

            // Info box
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Text(
                      status.isProcessing3D
                          ? 'Il modello 3D potrebbe richiedere fino a 30 secondi...'
                          : 'L\'AI sta analizzando il tuo disegno...',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedView(DrawingStatus status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spaceXL),

          // Success
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 60, color: Colors.white),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: AppTheme.spaceL),

          Text(
            'Elaborazione Completata!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
          ).animate().fadeIn().slideY(begin: 0.3),

          const SizedBox(height: AppTheme.spaceXL),

          // Processed image preview
          if (status.displayImageUrl != null) ...[
            const Text(
              'Il tuo disegno elaborato:',
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
                status.displayImageUrl!,
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
                  label: const Text('Vedi in 3D'),
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
              'Il modello 3D è in fase di generazione.\nVerrà visualizzato nella Gallery quando pronto.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final isValidationError = error.contains('not_a_drawing') ||
        error.contains('Not a valid drawing') ||
        error.contains('does not appear to be a drawing');
    final isConfigError = error.contains('api_config_missing') ||
        error.contains('API configuration');

    final String title;
    final IconData icon;
    final Color color;
    final String message;

    if (isValidationError) {
      title = 'Non è un Disegno';
      icon = Icons.image_not_supported;
      color = Colors.orange;
      message = 'L\'immagine caricata non sembra un disegno. Riprova con una foto di uno sketch su carta.';
    } else if (isConfigError) {
      title = 'Configurazione API Mancante';
      icon = Icons.settings_suggest;
      color = Colors.orange;
      message = 'Il token REPLICATE_API_TOKEN non è configurato. Aggiungilo alla tabella system_config su Supabase.';
    } else {
      title = 'Errore di Elaborazione';
      icon = Icons.error_outline;
      color = AppTheme.errorColor;
      message = error;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 60, color: Colors.white),
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
              message,
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
                  onPressed: () {
                    setState(() {
                      _pipelineStarted = false;
                      _pipelineError = null;
                    });
                    _startProcessing();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
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
