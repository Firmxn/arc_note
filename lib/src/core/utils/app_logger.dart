import 'dart:developer' as developer;

class AppLogger {
  static const String _tag = 'ArcNote';

  static void debug(String message, [String? tag]) {
    developer.log(
      'DEBUG: $message',
      name: tag ?? _tag,
      time: DateTime.now(),
    );
  }

  static void info(String message, [String? tag]) {
    developer.log(
      'INFO: $message',
      name: tag ?? _tag,
      time: DateTime.now(),
    );
  }

  static void warning(String message, [String? tag]) {
    developer.log(
      'WARNING: $message',
      name: tag ?? _tag,
      time: DateTime.now(),
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    developer.log(
      'ERROR: $message',
      name: tag ?? _tag,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}