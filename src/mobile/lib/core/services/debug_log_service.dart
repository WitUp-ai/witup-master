import 'package:flutter/foundation.dart';

/// Entry in the debug log
class DebugLogEntry {
  final DateTime timestamp;
  final String step;
  final DebugLogLevel level;
  final String message;
  final Map<String, dynamic>? data;

  DebugLogEntry({
    required this.step,
    required this.level,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  @override
  String toString() => '[$formattedTime] [$step] $message';
}

enum DebugLogLevel { info, success, warning, error }

/// Singleton service for debug logging across the pipeline.
/// Provides reactive updates via ValueNotifier.
class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  final ValueNotifier<List<DebugLogEntry>> entries =
      ValueNotifier<List<DebugLogEntry>>([]);

  bool enabled = true;

  void log(String step, String message, {Map<String, dynamic>? data}) {
    _add(DebugLogEntry(
      step: step,
      level: DebugLogLevel.info,
      message: message,
      data: data,
    ));
  }

  void success(String step, String message, {Map<String, dynamic>? data}) {
    _add(DebugLogEntry(
      step: step,
      level: DebugLogLevel.success,
      message: message,
      data: data,
    ));
  }

  void warning(String step, String message, {Map<String, dynamic>? data}) {
    _add(DebugLogEntry(
      step: step,
      level: DebugLogLevel.warning,
      message: message,
      data: data,
    ));
  }

  void error(String step, String message, {Object? error, Map<String, dynamic>? data}) {
    _add(DebugLogEntry(
      step: step,
      level: DebugLogLevel.error,
      message: '$message${error != null ? ': $error' : ''}',
      data: data,
    ));
  }

  void _add(DebugLogEntry entry) {
    if (!enabled) return;
    debugPrint(entry.toString());
    entries.value = [...entries.value, entry];
  }

  void clear() {
    entries.value = [];
  }

  /// Get all entries as a copyable string
  String exportLogs() {
    return entries.value.map((e) => e.toString()).join('\n');
  }
}
