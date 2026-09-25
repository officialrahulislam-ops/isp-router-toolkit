enum ConnectionType { wifi2_4, wifi5, ethernet, unknown }

/// Every field is nullable except [ipAddress] because routers vary
/// wildly in what they expose. Spec section 13: "Only display
/// information that the router actually provides."
class ConnectedDevice {
  final String ipAddress;
  final String? hostname;
  final String? macAddress;
  final ConnectionType connectionType;
  final int? signalStrengthDbm;
  final String? linkSpeedMbps;
  final bool isOnline;

  const ConnectedDevice({
    required this.ipAddress,
    this.hostname,
    this.macAddress,
    this.connectionType = ConnectionType.unknown,
    this.signalStrengthDbm,
    this.linkSpeedMbps,
    this.isOnline = true,
  });

  String get displayName =>
      (hostname != null && hostname!.trim().isNotEmpty) ? hostname! : 'Unknown Device';
}
