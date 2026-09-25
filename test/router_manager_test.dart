import 'package:flutter_test/flutter_test.dart';
import 'package:isp_router_toolkit/models/auth_result.dart';
import 'package:isp_router_toolkit/models/connected_device.dart';
import 'package:isp_router_toolkit/models/pppoe_settings.dart';
import 'package:isp_router_toolkit/models/router_info.dart';
import 'package:isp_router_toolkit/models/wifi_settings.dart';
import 'package:isp_router_toolkit/routers/generic/generic_adapter.dart';
import 'package:isp_router_toolkit/routers/router_adapter.dart';

/// A fake adapter for exercising RouterManager-level logic without any
/// real network access — mirrors what a real manufacturer adapter would
/// return, so RouterManager's orchestration (credential loop, capability
/// gating) is testable in isolation.
class FakeAdapter implements RouterAdapter {
  final String correctPassword;
  bool authenticated = false;

  FakeAdapter(this.correctPassword);

  @override
  String get adapterId => 'fake';
  @override
  String get manufacturerName => 'FakeCorp';
  @override
  String? get modelName => 'Test Router';
  @override
  Set<RouterCapability> get supportedCapabilities => {
        RouterCapability.wifiSettings,
        RouterCapability.pppoeSettings,
        RouterCapability.connectedDevices,
        RouterCapability.reboot,
      };

  @override
  Future<bool> canHandle(String gatewayIp) async => true;

  @override
  Future<AuthResult> authenticate(String gatewayIp, String password) async {
    if (password == correctPassword) {
      authenticated = true;
      return const AuthResult(success: true);
    }
    return const AuthResult.failure();
  }

  @override
  Future<RouterInfo> getRouterInfo() async =>
      RouterInfo(gatewayIp: '192.168.1.1', manufacturer: manufacturerName, model: modelName);

  @override
  Future<WifiSettings> getWifiSettings() async => const WifiSettings(bands: [
        WifiBandSettings(band: WifiBand.single, ssid: 'TestNet', password: 'testpass123'),
      ]);

  @override
  Future<void> setWifiSettings(WifiSettings settings) async {}

  @override
  Future<PppoeSettings> getPppoeSettings() async =>
      const PppoeSettings(username: 'client123', password: 'secret');

  @override
  Future<void> setPppoeSettings(PppoeSettings settings) async {}

  @override
  Future<List<ConnectedDevice>> getConnectedDevices() async => const [
        ConnectedDevice(ipAddress: '192.168.1.50', hostname: 'Test-PC'),
      ];

  @override
  Future<void> rebootRouter() async {}

  @override
  Future<void> disconnect() async {
    authenticated = false;
  }
}

void main() {
  group('GenericAdapter', () {
    test('never claims to handle a router during fingerprinting', () async {
      final adapter = GenericAdapter('192.168.1.1');
      expect(await adapter.canHandle('192.168.1.1'), isFalse);
    });

    test('reports zero capabilities', () {
      final adapter = GenericAdapter('192.168.1.1');
      expect(adapter.supportedCapabilities, isEmpty);
    });

    test('authenticate always fails', () async {
      final adapter = GenericAdapter('192.168.1.1');
      final result = await adapter.authenticate('192.168.1.1', 'admin');
      expect(result.success, isFalse);
    });
  });

  group('FakeAdapter credential loop behavior', () {
    test('succeeds only with the correct password', () async {
      final adapter = FakeAdapter('Jd12345678');

      final wrong = await adapter.authenticate('192.168.1.1', 'admin');
      expect(wrong.success, isFalse);

      final right = await adapter.authenticate('192.168.1.1', 'Jd12345678');
      expect(right.success, isTrue);
      expect(adapter.authenticated, isTrue);
    });

    test('exposes wifi/pppoe/devices once authenticated', () async {
      final adapter = FakeAdapter('admin');
      await adapter.authenticate('192.168.1.1', 'admin');

      final wifi = await adapter.getWifiSettings();
      expect(wifi.bands.single.ssid, 'TestNet');

      final pppoe = await adapter.getPppoeSettings();
      expect(pppoe.username, 'client123');

      final devices = await adapter.getConnectedDevices();
      expect(devices, hasLength(1));
      expect(devices.first.displayName, 'Test-PC');
    });
  });

  group('RouterInfo', () {
    test('displayName falls back to "Unknown Router"', () {
      const info = RouterInfo(gatewayIp: '192.168.1.1');
      expect(info.displayName, 'Unknown Router');
      expect(info.isIdentified, isFalse);
    });

    test('displayName combines manufacturer + model when present', () {
      const info = RouterInfo(
        gatewayIp: '192.168.1.1',
        manufacturer: 'TP-Link',
        model: 'Archer C6',
        adapterId: 'tplink_archer_c6',
      );
      expect(info.displayName, 'TP-Link Archer C6');
      expect(info.isIdentified, isTrue);
    });
  });

  group('ConnectedDevice', () {
    test('falls back to "Unknown Device" when hostname is missing', () {
      const device = ConnectedDevice(ipAddress: '192.168.1.99');
      expect(device.displayName, 'Unknown Device');
    });
  });
}
