/// Identifies which adapter should handle a given gateway, plus whatever
/// static info we could read off the router. Every field except
/// [gatewayIp] is nullable because we only ever show what we could
/// actually retrieve (spec section 14) — never fabricate values.
class RouterInfo {
  final String gatewayIp;
  final String? manufacturer;
  final String? model;
  final String? firmwareVersion;
  final String? macAddress;

  /// The adapter id (e.g. 'tplink_archer_c6') that claimed this router
  /// during fingerprinting. Null means "unidentified" — the UI then
  /// falls back to GenericAdapter / manual password entry.
  final String? adapterId;

  const RouterInfo({
    required this.gatewayIp,
    this.manufacturer,
    this.model,
    this.firmwareVersion,
    this.macAddress,
    this.adapterId,
  });

  bool get isIdentified => adapterId != null;

  String get displayName {
    if (manufacturer == null && model == null) return 'Unknown Router';
    return [manufacturer, model].where((e) => e != null && e.isNotEmpty).join(' ');
  }

  RouterInfo copyWith({
    String? manufacturer,
    String? model,
    String? firmwareVersion,
    String? macAddress,
    String? adapterId,
  }) {
    return RouterInfo(
      gatewayIp: gatewayIp,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      macAddress: macAddress ?? this.macAddress,
      adapterId: adapterId ?? this.adapterId,
    );
  }
}
