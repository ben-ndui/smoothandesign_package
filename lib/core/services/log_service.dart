import 'dart:async';

import 'package:flutter/foundation.dart';

/// Log levels for filtering
enum LogLevel { debug, info, warning, error }

/// A single log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? source;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.source,
    this.error,
    this.stackTrace,
  });

  String get levelIcon {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Service for capturing and streaming app logs.
///
/// Use as singleton:
/// ```dart
/// final logService = LogService();
/// logService.info('App started', source: 'main');
/// logService.error('Failed to load', error: e, source: 'API');
/// ```
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  final _logStreamController = StreamController<LogEntry>.broadcast();
  static const int _maxLogs = 500;

  /// Stream of new log entries
  Stream<LogEntry> get stream => _logStreamController.stream;

  /// All captured logs
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Log a debug message
  void debug(String message, {String? source}) {
    _addLog(LogLevel.debug, message, source: source);
  }

  /// Log an info message
  void info(String message, {String? source}) {
    _addLog(LogLevel.info, message, source: source);
  }

  /// Log a warning message
  void warning(String message, {String? source}) {
    _addLog(LogLevel.warning, message, source: source);
  }

  /// Log an error message
  void error(
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _addLog(
      LogLevel.error,
      message,
      source: source,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _addLog(
    LogLevel level,
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      source: source,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);

    // Keep logs under max limit
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    _logStreamController.add(entry);

    // Also print to console in debug mode
    if (kDebugMode) {
      final src = source != null ? '[$source] ' : '';
      debugPrint('${entry.levelIcon} [${entry.formattedTime}] $src$message');
      if (error != null) debugPrint('  Error: $error');
    }
  }

  /// Clear all logs
  void clear() {
    _logs.clear();
  }

  /// Export logs as string
  String export() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      final src = log.source != null ? '[${log.source}] ' : '';
      buffer.writeln(
        '[${log.formattedTime}] ${log.level.name.toUpperCase()} $src${log.message}',
      );
      if (log.error != null) buffer.writeln('  Error: ${log.error}');
      if (log.stackTrace != null) buffer.writeln('  Stack: ${log.stackTrace}');
    }
    return buffer.toString();
  }

  /// Dispose the service
  void dispose() {
    _logStreamController.close();
  }
}

/// Global log service instance
final logService = LogService();
