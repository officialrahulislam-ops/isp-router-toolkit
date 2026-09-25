import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import '../constants.dart';
import '../errors/app_exceptions.dart';
import '../errors/safe_logger.dart';

class WifiNetworkSnapshot {
  final String? ssid;
  final String? phoneIp;
  final String? gatewayIp;
  final String? subnetMask;

  const WifiNetworkSnapshot({this.ssid, this.phoneIp, this.gatewayIp, this.subnetMask});
}

/// Wraps network_info_plus + connectivity_plus to answer Phase 2's core
/// question: "what network is this phone on, and what's its gateway?"
class NetworkInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  /// Throws [NoWifiConnectionException] if the phone isn't on Wi-Fi at all.
  Future<void> assertOnWifi() async {
    final result = await _connectivity.checkConnectivity();
    final onWifi = result.contains(ConnectivityResult.wifi);
    if (!onWifi) {
      throw const NoWifiConnectionException();
    }
  }

  /// Reads SSID/IP/gateway/subnet from the OS. On Android 10+ this
  /// requires location permission to be granted for SSID; gateway/IP
  /// are generally available regardless.
  Future<WifiNetworkSnapshot> captureSnapshot() async {
    await assertOnWifi();

    final ssid = await _safeCall(() => _networkInfo.getWifiName());
    final phoneIp = await _safeCall(() => _networkInfo.getWifiIP());
    final gatewayIp = await _safeCall(() => _networkInfo.getWifiGatewayIP());
    final subnet = await _safeCall(() => _networkInfo.getWifiSubmask());

    SafeLogger.i('Captured network snapshot', data: {
      'ssid': ssid,
      'phoneIp': phoneIp,
      'gatewayIp': gatewayIp,
      'subnet': subnet,
    });

    return WifiNetworkSnapshot(
      ssid: _stripQuotes(ssid),
      phoneIp: phoneIp,
      gatewayIp: gatewayIp,
      subnetMask: subnet,
    );
  }

  /// Confirms the gateway actually answers before we try HTTP fingerprinting.
  /// Falls back gracefully — some routers block ICMP but still serve HTTP,
  /// so a failed ping alone should not be treated as fatal by callers.
  Future<bool> isGatewayReachable(String gatewayIp) async {
    try {
      final ping = Ping(gatewayIp, count: 1, timeout: AppConstants.gatewayPingTimeout.inSeconds);
      final result = await ping.stream.first.timeout(AppConstants.gatewayPingTimeout);
      return result.response != null;
    } catch (_) {
      return false;
    }
  }

  String? _stripQuotes(String? s) => s?.replaceAll('"', '');

  Future<T?> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      SafeLogger.w('Network info call failed', data: {'error': e.runtimeType.toString()});
      return null;
    }
  }
}
