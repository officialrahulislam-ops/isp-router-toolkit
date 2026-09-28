enum SignalQuality { unknown, excellent, good, fair, weak }

extension SignalQualityLabel on SignalQuality {
  String get label => switch (this) {
        SignalQuality.unknown => '—',
        SignalQuality.excellent => 'Excellent',
        SignalQuality.good => 'Good',
        SignalQuality.fair => 'Fair',
        SignalQuality.weak => 'Weak',
      };
}

/// Everything we could read about the current Wi-Fi connection.
/// Any field the phone could not provide stays null and is simply not shown.
class WifiSnapshot {
  const WifiSnapshot({
    required this.onWifi,
    this.locationGranted = true,
    this.ssid,
    this.bssid,
    this.phoneIp,
    this.gatewayIp,
    this.subnetMask,
    this.rssiDbm,
    this.frequencyMhz,
    this.linkSpeedMbps,
  });

  static const offline = WifiSnapshot(onWifi: false);

  final bool onWifi;
  final bool locationGranted;
  final String? ssid;
  final String? bssid;
  final String? phoneIp;
  final String? gatewayIp;
  final String? subnetMask;
  final int? rssiDbm;
  final int? frequencyMhz;
  final int? linkSpeedMbps;

  String? get band {
    final f = frequencyMhz;
    if (f == null) return null;
    if (f < 3000) return '2.4 GHz';
    if (f < 5900) return '5 GHz';
    return '6 GHz';
  }

  SignalQuality get signalQuality {
    final r = rssiDbm;
    if (r == null) return SignalQuality.unknown;
    if (r >= -55) return SignalQuality.excellent;
    if (r >= -67) return SignalQuality.good;
    if (r >= -75) return SignalQuality.fair;
    return SignalQuality.weak;
  }
}
