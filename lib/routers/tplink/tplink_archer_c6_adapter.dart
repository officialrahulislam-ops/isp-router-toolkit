import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../core/networking/router_prober.dart';
import '../../models/auth_result.dart';
import '../../models/connected_device.dart';
import '../../models/pppoe_settings.dart';
import '../../models/router_info.dart';
import '../../models/wifi_settings.dart';
import '../router_adapter.dart';

/// TP-Link Archer C6 adapter.
///
/// STATUS: fingerprinting (canHandle) is real and safe to ship — it only
/// reads the public login page, same as opening it in a browser.
///
/// Authentication and settings read/write are intentionally NOT
/// implemented yet. Per the project's development rule, we do not fake a
/// router API we haven't verified. TP-Link's newer firmware
/// (this targets the common Archer C6 EU/US firmware line) typically
/// uses one of two patterns depending on firmware version:
///   1. A legacy Basic-Auth protected /userRpm/ CGI interface, or
///   2. A newer JSON-RPC-style POST to a single endpoint (commonly seen
///      as something like `/cgi-bin/luci/;stok=<token>/...` on OpenWrt-
///      derived TP-Link builds, or a proprietary `/cgi/...` endpoint with
///      an MD5/RSA-obfuscated password field) with the session token
///      embedded in the URL after login.
///
/// Before implementing [authenticate]/[getWifiSettings]/etc., capture the
/// real traffic from a browser session against an actual Archer C6 (e.g.
/// via a local proxy) to confirm: the exact login endpoint and payload
/// shape, whether the password is sent plain, MD5-hashed, or RSA-
/// encrypted client-side, the session token transport (cookie vs URL
/// stok vs custom header), and the exact field names for SSID/PPPoE
/// read+write. Fill in the TODOs below only once each of those is
/// confirmed against the real device — see spec section 25.
class TpLinkArcherC6Adapter implements RouterAdapter {
  final String gatewayIp;
  final RouterProber _prober;
  final Dio _dio;

  String? _sessionToken;

  TpLinkArcherC6Adapter(this.gatewayIp, {RouterProber? prober, Dio? dio})
      : _prober = prober ?? RouterProber(),
        _dio = dio ?? Dio(BaseOptions(connectTimeout: AppConstants.httpTimeout));

  @override
  String get adapterId => 'tplink_archer_c6';

  @override
  String get manufacturerName => 'TP-Link';

  @override
  String? get modelName => 'Archer C6';

  @override
  Set<RouterCapability> get supportedCapabilities => {
        // Left empty until the corresponding methods are implemented for
        // real. Flip these on one at a time as each is verified working
        // end-to-end against a physical Archer C6 — this set is what
        // drives whether the dashboard shows the section at all.
      };

  @override
  Future<bool> canHandle(String gatewayIp) async {
    final probe = await _prober.probe(gatewayIp);
    if (probe == null) return false;

    // Publicly-visible fingerprint only (page title / server header) —
    // this is the same information any browser gets from the login page.
    final titleMatch = probe.bodyContains('tp-link') || probe.bodyContains('archer');
    final serverMatch = probe.headerContains('server', 'tp-link');
    return titleMatch || serverMatch;
  }

  @override
  Future<AuthResult> authenticate(String gatewayIp, String password) async {
    // TODO(router-protocol): implement once the real login endpoint/
    // payload shape is confirmed (see class doc). Do not guess a payload
    // shape here — an incorrect guess that "succeeds" silently would
    // violate the "don't pretend a feature works" rule and could lock
    // out or misconfigure a customer's router.
    throw UnimplementedError(
      'TP-Link Archer C6 authentication protocol not yet determined. '
      'Capture real device traffic before implementing.',
    );
  }

  @override
  Future<RouterInfo> getRouterInfo() async {
    throw UnimplementedError('Requires authenticate() to be implemented first.');
  }

  @override
  Future<WifiSettings> getWifiSettings() async {
    throw UnimplementedError('TP-Link Wi-Fi read endpoint not yet determined.');
  }

  @override
  Future<void> setWifiSettings(WifiSettings settings) async {
    throw UnimplementedError('TP-Link Wi-Fi write endpoint not yet determined.');
  }

  @override
  Future<PppoeSettings> getPppoeSettings() async {
    throw UnimplementedError('TP-Link PPPoE read endpoint not yet determined.');
  }

  @override
  Future<void> setPppoeSettings(PppoeSettings settings) async {
    throw UnimplementedError('TP-Link PPPoE write endpoint not yet determined.');
  }

  @override
  Future<List<ConnectedDevice>> getConnectedDevices() async {
    throw UnimplementedError('TP-Link client-list endpoint not yet determined.');
  }

  @override
  Future<void> rebootRouter() async {
    throw UnimplementedError('TP-Link reboot endpoint not yet determined.');
  }

  @override
  Future<void> disconnect() async {
    _sessionToken = null;
  }
}
