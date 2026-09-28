import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wifi_snapshot.dart';
import 'tcp_probe.dart';
import 'wifi_service.dart';

enum NetworkHealth {
  checking,
  healthy,
  noInternet,
  routerUnreachable,
  notOnWifi,
  gatewayUnknown,
}

/// Holds the current Wi-Fi snapshot plus a quick "phone -> router -> internet"
/// reachability check. Refreshes itself while the app is in the foreground.
class NetworkController extends ChangeNotifier {
  NetworkController(this._wifi);

  final WifiService _wifi;

  WifiSnapshot? _snapshot;
  bool _loading = false;
  bool _refreshing = false;
  bool _disposed = false;
  bool _checked = false;
  double? _routerMs;
  double? _internetMs;
  Timer? _timer;

  WifiSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  bool get checked => _checked;
  double? get routerMs => _routerMs;
  double? get internetMs => _internetMs;

  NetworkHealth get health {
    final s = _snapshot;
    if (s == null) return NetworkHealth.checking;
    if (!s.onWifi) return NetworkHealth.notOnWifi;
    if (s.gatewayIp == null) return NetworkHealth.gatewayUnknown;
    if (!_checked) return NetworkHealth.checking;
    if (_routerMs == null) return NetworkHealth.routerUnreachable;
    if (_internetMs == null) return NetworkHealth.noInternet;
    return NetworkHealth.healthy;
  }

  /// [askPermission] shows the location permission prompt if needed.
  void start({bool askPermission = true}) {
    _timer?.cancel();
    refresh(silent: !askPermission);
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => refresh(silent: true));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent) {
      _loading = true;
      _notify();
    }
    try {
      final snap = await _wifi.read(askPermission: !silent);
      if (snap.gatewayIp != _snapshot?.gatewayIp) {
        _checked = false;
        _routerMs = null;
        _internetMs = null;
      }
      _snapshot = snap;
      _notify();

      final gateway = snap.gatewayIp;
      if (snap.onWifi && gateway != null) {
        final results = await Future.wait<double?>([
          _probeRouter(gateway),
          _probeInternet(),
        ]);
        _routerMs = results[0];
        _internetMs = results[1];
        _checked = true;
      } else if (snap.onWifi) {
        _internetMs = await _probeInternet();
      } else {
        _routerMs = null;
        _internetMs = null;
        _checked = false;
      }
    } catch (_) {
      // Keep the last known values; the next tick will try again.
    } finally {
      _refreshing = false;
      _loading = false;
      _notify();
    }
  }

  Future<double?> _probeRouter(String gateway) async {
    return (await TcpProbe.probe(gateway, 80)) ?? (await TcpProbe.probe(gateway, 443));
  }

  Future<double?> _probeInternet() async {
    return (await TcpProbe.probe('8.8.8.8', 53)) ?? (await TcpProbe.probe('1.1.1.1', 53));
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
