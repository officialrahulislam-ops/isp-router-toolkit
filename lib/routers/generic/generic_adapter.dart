import '../../models/auth_result.dart';
import '../../models/connected_device.dart';
import '../../models/pppoe_settings.dart';
import '../../models/router_info.dart';
import '../../models/wifi_settings.dart';
import '../router_adapter.dart';

/// Adapter of last resort. It never claims to *own* a router during
/// fingerprinting (canHandle always returns false) — it exists so the
/// rest of the app (manual password entry, "unknown router" screen) has
/// a concrete, well-typed object to hold onto instead of null-checking
/// everywhere. It reports zero capabilities, which is what tells the
/// dashboard to show "not currently supported" for settings sections.
///
/// This is also the class to subclass first when starting a brand-new
/// adapter: copy it, rename, and fill in real HTTP calls once the
/// firmware's protocol has been determined (spec section 25).
class GenericAdapter implements RouterAdapter {
  final String gatewayIp;

  GenericAdapter(this.gatewayIp);

  @override
  String get adapterId => 'generic';

  @override
  String get manufacturerName => 'Unknown';

  @override
  String? get modelName => null;

  @override
  Set<RouterCapability> get supportedCapabilities => {};

  @override
  Future<bool> canHandle(String gatewayIp) async => false;

  @override
  Future<AuthResult> authenticate(String gatewayIp, String password) async {
    return const AuthResult.failure();
  }

  @override
  Future<RouterInfo> getRouterInfo() async => RouterInfo(gatewayIp: gatewayIp);

  @override
  Future<WifiSettings> getWifiSettings() async =>
      const WifiSettings(bands: []);

  @override
  Future<void> setWifiSettings(WifiSettings settings) async {
    throw UnimplementedError('GenericAdapter cannot write settings.');
  }

  @override
  Future<PppoeSettings> getPppoeSettings() async =>
      const PppoeSettings(username: '', password: '');

  @override
  Future<void> setPppoeSettings(PppoeSettings settings) async {
    throw UnimplementedError('GenericAdapter cannot write settings.');
  }

  @override
  Future<List<ConnectedDevice>> getConnectedDevices() async => [];

  @override
  Future<void> rebootRouter() async {
    throw UnimplementedError('GenericAdapter cannot reboot this router.');
  }

  @override
  Future<void> disconnect() async {}
}
