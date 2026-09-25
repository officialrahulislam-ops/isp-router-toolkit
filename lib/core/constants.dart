/// Central place for magic numbers/strings so nothing is scattered
/// across screens or adapters.
class AppConstants {
  AppConstants._();

  static const String appName = 'ISP Router Toolkit';

  /// Timeouts
  static const Duration httpTimeout = Duration(seconds: 6);
  static const Duration gatewayPingTimeout = Duration(seconds: 2);
  static const Duration authAttemptTimeout = Duration(seconds: 8);

  /// Secure storage keys
  static const String storageKeyCredentialList = 'credential_list_v1';
  static const String storageKeyTechnicianPin = 'technician_pin_v1';
  static const String storageKeyAdminPin = 'admin_pin_v1';
  static const String storageKeyAdapterToggles = 'adapter_toggles_v1';

  /// Default seed credentials (first run only — user-editable afterwards,
  /// never re-seeded once the admin has customized the list).
  static const List<String> defaultSeedCredentials = [
    'admin',
  ];

  /// Common router LAN gateways, used only as a fallback hint list for UI
  /// copy/diagnostics. The actual gateway is always read from the OS.
  static const List<String> commonGatewayHints = [
    '192.168.0.1',
    '192.168.1.1',
    '192.168.10.1',
    '192.168.8.1',
  ];
}
