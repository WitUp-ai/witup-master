import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debug_log_service.dart';

/// A collapsible debug panel that shows pipeline log entries in real time.
/// Can be embedded at the bottom of any screen.
class DebugOverlay extends StatefulWidget {
  const DebugOverlay({super.key});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _expanded = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _levelColor(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.info:
        return Colors.blue;
      case DebugLogLevel.success:
        return Colors.green;
      case DebugLogLevel.warning:
        return Colors.orange;
      case DebugLogLevel.error:
        return Colors.red;
    }
  }

  IconData _levelIcon(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.info:
        return Icons.info_outline;
      case DebugLogLevel.success:
        return Icons.check_circle_outline;
      case DebugLogLevel.warning:
        return Icons.warning_amber;
      case DebugLogLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final debugService = DebugLogService.instance;
    if (!debugService.enabled) return const SizedBox.shrink();

    return ValueListenableBuilder<List<DebugLogEntry>>(
      valueListenable: debugService.entries,
      builder: (context, entries, _) {
        if (entries.isEmpty && !_expanded) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header bar
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Colors.green.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Log (${entries.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (entries.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: debugService.exportLogs()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logs copied')),
                            );
                          },
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => debugService.clear(),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Log entries
              if (_expanded)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: entries.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No log entries yet. Start a drawing to see pipeline activity.',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _levelIcon(entry.level),
                                    color: _levelColor(entry.level),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.formattedTime,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _levelColor(entry.level).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      entry.step,
                                      style: TextStyle(
                                        color: _levelColor(entry.level),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.message,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}
