import '../models/auth_result.dart';
import '../models/connected_device.dart';
import '../models/pppoe_settings.dart';
import '../models/router_info.dart';
import '../models/wifi_settings.dart';

/// Every capability an adapter *might* support. The UI uses this to decide
/// what to show/hide instead of calling a method and catching an exception —
/// cheaper, and makes "this router can't do X" a first-class, checkable fact
/// rather than a runtime surprise.
enum RouterCapability {
  wifiSettings,
  pppoeSettings,
  connectedDevices,
  reboot,
}

/// The contract every manufacturer-specific implementation must satisfy.
/// The UI and RouterManager depend ONLY on this interface — never on a
/// concrete adapter class. This is what makes it possible to add
/// Netis/Tenda/TOTOLINK/etc. later without touching any screen.
///
/// Implementations must NOT throw for "feature not supported" — they
/// should declare that up front via [supportedCapabilities] and the
/// getters should return null / an empty result instead. Exceptions are
/// reserved for actual failures (network, auth, save).
abstract class RouterAdapter {
  /// Stable identifier, e.g. 'tplink_archer_c6'. Used for persistence,
  /// analytics-free diagnostics, and matching against admin toggles.
  String get adapterId;

  String get manufacturerName;

  /// Null if this adapter matches a manufacturer generically rather than
  /// one specific model (e.g. GenericAdapter).
  String? get modelName;

  Set<RouterCapability> get supportedCapabilities;

  /// Cheap, read-only check: does this gateway look like it's handled by
  /// this adapter? Implementations typically inspect response headers,
  /// page title, or a known JS/API endpoint. Must not mutate router state
  /// and should fail closed (return false) on any error rather than throw.
  Future<bool> canHandle(String gatewayIp);

  /// Attempts login with [password]. Implementations should keep whatever
  /// session token/cookie they receive internally; nothing sensitive
  /// should leak into the returned [AuthResult] beyond what's needed to
  /// optionally save the credential.
  Future<AuthResult> authenticate(String gatewayIp, String password);

  /// Returns whatever router-identity fields could actually be read.
  /// Only called after a successful [authenticate].
  Future<RouterInfo> getRouterInfo();

  Future<WifiSettings> getWifiSettings();
  Future<void> setWifiSettings(WifiSettings settings);

  Future<PppoeSettings> getPppoeSettings();
  Future<void> setPppoeSettings(PppoeSettings settings);

  Future<List<ConnectedDevice>> getConnectedDevices();

  Future<void> rebootRouter();

  /// Release any session/cookies. Called when the technician leaves the
  /// dashboard or switches networks.
  Future<void> disconnect();
}
