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
  DateTime? _lastStatusChange;
  String? _lastStep;
  bool _isStalled = false;
  static const _stallTimeout = Duration(seconds: 120);

  // 2-phase: concept 2D shown + 3D countdown
  String? _conceptUrl;
  int _estTimeSeconds = 120;
  DateTime? _countdownStart;
  bool _phase2Active = false;

  @override
  void initState() {
    super.initState();
    _lastStatusChange = DateTime.now();
    _startProcessing();
    _startStallChecker();
  }

  void _startStallChecker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      final elapsed = DateTime.now().difference(_lastStatusChange!);
      final stalled = elapsed > _stallTimeout;
      if (stalled != _isStalled) {
        setState(() => _isStalled = stalled);
      }
      return mounted;
    });
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_phase2Active) return false;
      setState(() {}); // trigger rebuild for countdown
      return mounted && _phase2Active;
    });
  }

  int get _remainingSeconds {
    if (_countdownStart == null) return _estTimeSeconds;
    final elapsed = DateTime.now().difference(_countdownStart!).inSeconds;
    final remaining = _estTimeSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  String get _countdownText {
    final s = _remainingSeconds;
    final min = s ~/ 60;
    final sec = s % 60;
    return '${min}:${sec.toString().padLeft(2, '0')}';
  }

  void _onStatusChanged(String? step) {
    if (step != _lastStep) {
      _lastStep = step;
      _lastStatusChange = DateTime.now();
      if (_isStalled) {
        setState(() => _isStalled = false);
      }
    }
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
      final result = await ref.read(aiProcessingProvider.notifier).processDrawing(
            drawingId: widget.drawingId,
            userId: userId,
          );
      // If concept_url returned, enter phase 2 (show concept + countdown)
      if (mounted && result.conceptUrl != null && result.estTimeSeconds > 0) {
        setState(() {
          _conceptUrl = result.conceptUrl;
          _estTimeSeconds = result.estTimeSeconds;
          _countdownStart = DateTime.now();
          _phase2Active = true;
        });
        _startCountdown();
      }
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
            // Track step changes for stall detection
            _onStatusChanged(status.processingStep ?? status.status);

            // If 3D just completed and we were in phase2, deactivate countdown
            if (status.isCompleted && _phase2Active) {
              _phase2Active = false;
            }

            if (status.isCompleted) {
              return _buildCompletedView(status);
            } else if (status.isFailed) {
              return _buildErrorView(status.error ?? _pipelineError ?? 'Elaborazione fallita');
            } else if (_phase2Active && _conceptUrl != null) {
              // Phase 2: concept 2D ready, waiting for 3D
              return _buildConceptReadyView(status);
            } else {
              // Phase 1: still processing 2D
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

  Widget _buildConceptReadyView(DrawingStatus status) {
    final remaining = _remainingSeconds;
    final showOvertime = remaining <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spaceM),

          // Title
          Text(
            'Ecco il tuo Concept 2D!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ).animate().fadeIn().slideY(begin: 0.3),

          const SizedBox(height: AppTheme.spaceL),

          // Concept 2D image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.shadowLarge,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              _conceptUrl!,
              height: 260,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stack) {
                return Container(
                  height: 260,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 60),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: AppTheme.spaceXL),

          // 3D countdown section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spaceL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                  AppTheme.accentColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.view_in_ar, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Modello 3D in generazione...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceM),

                // Timer
                Text(
                  showOvertime ? 'Ancora pochi istanti...' : 'Tempo stimato: ${_countdownText}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: showOvertime ? Colors.orange : AppTheme.primaryColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),

                const SizedBox(height: AppTheme.spaceM),

                // Progress bar for 3D
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: showOvertime
                        ? null // indeterminate when overtime
                        : 1.0 - (remaining.toDouble() / _estTimeSeconds.toDouble()),
                    minHeight: 6,
                    color: AppTheme.primaryColor,
                    backgroundColor: const Color(0xFFE0E0E0),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: AppTheme.spaceL),

          // "Puoi continuare a navigare" message
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: AppTheme.successColor),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Text(
                    'Puoi continuare a navigare!\nTi avviseremo quando il modello 3D sarà pronto.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: AppTheme.spaceL),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: const Text('Torna alla Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildProcessingView(DrawingStatus status) {
    final progress = status.progressPercent;
    final percent = (progress * 100).toInt();

    // Pipeline steps definition
    final steps = [
      _PipelineStep('Caricamento', 'uploading', Icons.cloud_upload),
      _PipelineStep('Validazione AI', 'validating', Icons.psychology),
      _PipelineStep('Rimozione sfondo', 'removing_background', Icons.auto_fix_high),
      _PipelineStep('Generazione 3D', 'generating_3d', Icons.view_in_ar),
      _PipelineStep('Finalizzazione', 'finalizing', Icons.check_circle_outline),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spaceL),

          // Animated icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.magicGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowLarge,
            ),
            child: const Icon(Icons.auto_awesome, size: 50, color: Colors.white),
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3.seconds),

          const SizedBox(height: AppTheme.spaceL),

          // Current step label
          Text(
            status.stepLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: AppTheme.primaryColor),

          const SizedBox(height: AppTheme.spaceM),

          // Percentage
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
          ),

          const SizedBox(height: AppTheme.spaceM),

          // Determinate progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppTheme.primaryColor,
              backgroundColor: const Color(0xFFE0E0E0),
            ),
          ),

          const SizedBox(height: AppTheme.spaceXL),

          // Step list
          ...steps.map((step) {
            final stepState = _getStepState(step.key, status);
            return _buildStepRow(step, stepState);
          }),

          const SizedBox(height: AppTheme.spaceL),

          // Stall warning
          if (_isStalled)
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'L\'operazione sta impiegando più del previsto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Potrebbe esserci un problema. Puoi riprovare o tornare alla home.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().shake(),

          if (_isStalled) ...[
            const SizedBox(height: AppTheme.spaceM),
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
                      _isStalled = false;
                      _lastStatusChange = DateTime.now();
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

          // Info tip (when not stalled)
          if (!_isStalled)
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spaceL),
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
    );
  }

  /// Determine step state: done, active, or pending
  _StepState _getStepState(String stepKey, DrawingStatus status) {
    const order = ['uploading', 'validating', 'removing_background', 'generating_3d', 'finalizing'];
    final currentStep = status.processingStep;

    if (status.isCompleted) return _StepState.done;

    if (currentStep == null) {
      // Fallback: use model_status only
      if (status.isProcessing3D) {
        final idx = order.indexOf(stepKey);
        if (idx <= 3) return _StepState.done;
        return _StepState.pending;
      }
      return _StepState.pending;
    }

    final currentIdx = order.indexOf(currentStep);
    final stepIdx = order.indexOf(stepKey);

    if (stepIdx < currentIdx) return _StepState.done;
    if (stepIdx == currentIdx) return _StepState.active;
    return _StepState.pending;
  }

  Widget _buildStepRow(_PipelineStep step, _StepState state) {
    final Color color;
    final Widget leading;

    switch (state) {
      case _StepState.done:
        color = AppTheme.successColor;
        leading = Icon(Icons.check_circle, color: color, size: 22);
        break;
      case _StepState.active:
        color = AppTheme.primaryColor;
        leading = SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        );
        break;
      case _StepState.pending:
        color = Colors.grey.shade400;
        leading = Icon(Icons.radio_button_unchecked, color: color, size: 22);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Icon(step.icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: state == _StepState.active ? FontWeight.w600 : FontWeight.w400,
              color: state == _StepState.pending ? Colors.grey.shade400 : Colors.black87,
            ),
          ),
        ],
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

/// Pipeline step definition
class _PipelineStep {
  final String label;
  final String key;
  final IconData icon;
  const _PipelineStep(this.label, this.key, this.icon);
}

/// Step visual state
enum _StepState { done, active, pending }
