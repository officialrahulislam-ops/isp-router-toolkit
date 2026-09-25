import 'package:dio/dio.dart';
import '../constants.dart';
import '../errors/safe_logger.dart';
import '../../routers/router_fingerprint.dart';

/// Performs the read-only HTTP/HTTPS probe described in spec section 5:
/// hit the gateway root, capture headers/title/body, and hand the result
/// to each adapter's canHandle(). This is intentionally the ONLY place
/// that makes an unauthenticated request to the router root, so probing
/// behavior (timeouts, redirect handling, scheme fallback) lives in one
/// tested spot rather than being duplicated per adapter.
class RouterProber {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConstants.httpTimeout,
    receiveTimeout: AppConstants.httpTimeout,
    followRedirects: true,
    validateStatus: (_) => true, // we want to inspect 401/403 pages too
  ));

  Future<RouterProbeResult?> probe(String gatewayIp) async {
    for (final scheme in ['http', 'https']) {
      try {
        final response = await _dio.get<String>('$scheme://$gatewayIp/');
        final body = response.data ?? '';
        return RouterProbeResult(
          statusCode: response.statusCode,
          headers: response.headers.map.map((k, v) => MapEntry(k.toLowerCase(), v.join(', '))),
          bodySnippet: body.length > 4096 ? body.substring(0, 4096) : body,
          finalUrl: response.realUri.toString(),
        );
      } catch (e) {
        SafeLogger.w('Probe failed for scheme', data: {'scheme': scheme, 'error': e.runtimeType.toString()});
        continue;
      }
    }
    return null; // neither http nor https answered
  }
}
