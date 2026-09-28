import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_snapshot.dart';

/// Reads the current Wi-Fi connection details from Android.
class WifiService {
  static const MethodChannel _channel = MethodChannel('isp_helper/wifi');

  final NetworkInfo _info = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  Future<WifiSnapshot> read({bool askPermission = false}) async {
    final connection = await _connectivity.checkConnectivity();
    if (!connection.contains(ConnectivityResult.wifi)) {
      return WifiSnapshot.offline;
    }

    var granted = await Permission.locationWhenInUse.isGranted;
    if (!granted && askPermission) {
      granted = (await Permission.locationWhenInUse.request()).isGranted;
    }

    final ssid = granted ? _cleanName(await _safe(_info.getWifiName)) : null;
    final bssid = granted ? _cleanBssid(await _safe(_info.getWifiBSSID)) : null;
    final phoneIp = _cleanIp(await _safe(_info.getWifiIP));
    final gateway = _cleanIp(await _safe(_info.getWifiGatewayIP));
    final subnet = _cleanIp(await _safe(_info.getWifiSubmask));

    int? rssi;
    int? frequency;
    int? linkSpeed;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getWifiDetails');
      final r = _asInt(res?['rssi']);
      final f = _asInt(res?['frequency']);
      final s = _asInt(res?['linkSpeed']);
      if (r != null && r < 0 && r > -127) rssi = r;
      if (f != null && f > 0) frequency = f;
      if (s != null && s > 0) linkSpeed = s;
    } catch (_) {
      // Native details unavailable; the rest of the snapshot is still useful.
    }

    return WifiSnapshot(
      onWifi: true,
      locationGranted: granted,
      ssid: ssid,
      bssid: bssid,
      phoneIp: phoneIp,
      gatewayIp: gateway,
      subnetMask: subnet,
      rssiDbm: rssi,
      frequencyMhz: frequency,
      linkSpeedMbps: linkSpeed,
    );
  }

  Future<T?> _safe<T>(Future<T?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  int? _asInt(Object? v) => v is int ? v : null;

  String? _cleanName(String? v) {
    if (v == null) return null;
    final s = v.replaceAll('"', '').trim();
    if (s.isEmpty || s == '<unknown ssid>') return null;
    return s;
  }

  String? _cleanBssid(String? v) {
    final s = _cleanName(v);
    if (s == null || s == '02:00:00:00:00:00') return null;
    return s;
  }

  String? _cleanIp(String? v) {
    final s = _cleanName(v);
    if (s == null || s == '0.0.0.0') return null;
    return s;
  }
}
