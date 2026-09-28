import 'dart:io';

/// Measures round-trip time by timing a TCP connection to host:port.
///
/// Android apps cannot send ICMP ping without root, so this is the reliable
/// alternative. The result tracks real ping closely, but is not identical.
/// A "connection refused" reply still counts: the host answered, it just has
/// nothing listening on that port.
class TcpProbe {
  TcpProbe._();

  static const _refusedCodes = {111, 61, 10061}; // Linux/Android, macOS, Windows

  /// Returns the round-trip time in milliseconds, or null if there was no answer.
  static Future<double?> probe(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return sw.elapsedMicroseconds / 1000.0;
    } on SocketException catch (e) {
      if (_refusedCodes.contains(e.osError?.errorCode)) {
        sw.stop();
        return sw.elapsedMicroseconds / 1000.0;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
