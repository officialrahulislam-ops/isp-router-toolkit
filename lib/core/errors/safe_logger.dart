import 'package:logger/logger.dart';

/// Every log call in the app must go through here — never call
/// print()/Logger() directly elsewhere. This keeps the "never log
/// passwords / never include them in crash reports" requirement
/// enforceable in one place instead of relying on every call site
/// remembering to redact.
///
/// Usage:
///   SafeLogger.i('Authenticated with router', data: {'gateway': ip});
///   SafeLogger.e('Auth failed', error: e);
///
/// Never pass a raw credential map into `data`. If a field name matches
/// [_sensitiveKeys], its value is replaced with '***' automatically as a
/// second line of defense.
class SafeLogger {
  SafeLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: false, printEmojis: false),
    level: Level.info,
  );

  static const Set<String> _sensitiveKeys = {
    'password',
    'wifipassword',
    'pppoepassword',
    'adminpassword',
    'pin',
    'token',
    'cookie',
    'authorization',
  };

  static Map<String, dynamic>? _redact(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data.map((key, value) {
      final isSensitive = _sensitiveKeys.any((s) => key.toLowerCase().contains(s));
      return MapEntry(key, isSensitive ? '***' : value);
    });
  }

  static void i(String message, {Map<String, dynamic>? data}) {
    _logger.i('$message ${_redact(data) ?? ''}');
  }

  static void w(String message, {Map<String, dynamic>? data}) {
    _logger.w('$message ${_redact(data) ?? ''}');
  }

  /// [error] is logged as its runtime type + message only — never pass
  /// a raw request/response body here if it might contain a credential.
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error?.runtimeType.toString(), stackTrace: stackTrace);
  }
}
