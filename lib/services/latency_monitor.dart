import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/latency_stats.dart';
import 'tcp_probe.dart';

enum ProbeTarget {
  gateway('Router', 'Your router (local network)'),
  googleDns('Google DNS', '8.8.8.8'),
  cloudflare('Cloudflare', '1.1.1.1');

  const ProbeTarget(this.label, this.detail);
  final String label;
  final String detail;
}

/// Probes the selected target about once a second and keeps the last
/// [maxSamples] results for the chart and statistics.
class LatencyMonitor extends ChangeNotifier {
  static const int maxSamples = 60;

  final List<double?> _samples = [];
  ProbeTarget _target = ProbeTarget.googleDns;
  String? _gatewayIp;
  int _gatewayPort = 80;
  Timer? _timer;
  bool _busy = false;
  bool _disposed = false;

  ProbeTarget get target => _target;
  List<double?> get samples => List.unmodifiable(_samples);
  LatencyStats get stats => LatencyStats.fromSamples(_samples);
  bool get isRunning => _timer != null;

  String? get host => switch (_target) {
        ProbeTarget.gateway => _gatewayIp,
        ProbeTarget.googleDns => '8.8.8.8',
        ProbeTarget.cloudflare => '1.1.1.1',
      };

  bool get hasTarget => host != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
    _notify();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _notify();
  }

  void setTarget(ProbeTarget target) {
    if (target == _target) return;
    _target = target;
    _samples.clear();
    _notify();
  }

  void setGateway(String? ip) {
    if (ip == _gatewayIp) return;
    _gatewayIp = ip;
    _gatewayPort = 80;
    if (_target == ProbeTarget.gateway) _samples.clear();
    _notify();
  }

  void clear() {
    _samples.clear();
    _notify();
  }

  Future<void> _tick() async {
    if (_busy) return;
    final currentHost = host;
    if (currentHost == null) return;
    final currentTarget = _target;

    _busy = true;
    double? result;
    try {
      result = await _probe(currentHost, currentTarget);
    } finally {
      _busy = false;
    }

    // Ignore the result if the user switched target while we were waiting.
    if (_disposed || currentTarget != _target || currentHost != host) return;

    _samples.add(result);
    if (_samples.length > maxSamples) _samples.removeAt(0);
    _notify();
  }

  Future<double?> _probe(String host, ProbeTarget target) async {
    if (target != ProbeTarget.gateway) {
      return TcpProbe.probe(host, 53);
    }
    final first = await TcpProbe.probe(host, _gatewayPort);
    if (first != null) return first;
    final altPort = _gatewayPort == 80 ? 443 : 80;
    final second = await TcpProbe.probe(host, altPort);
    if (second != null) _gatewayPort = altPort;
    return second;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
