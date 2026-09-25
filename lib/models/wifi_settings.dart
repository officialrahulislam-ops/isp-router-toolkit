enum WifiBand { band2_4Ghz, band5Ghz, single }

/// A single radio's settings. Some routers only expose one combined
/// network (`WifiBand.single`); others expose 2.4/5GHz separately —
/// the UI (spec section 10) renders one or two cards accordingly based
/// on how many bands the adapter returns.
class WifiBandSettings {
  final WifiBand band;
  final String ssid;
  final String password;
  final bool isEnabled;

  const WifiBandSettings({
    required this.band,
    required this.ssid,
    required this.password,
    this.isEnabled = true,
  });

  WifiBandSettings copyWith({String? ssid, String? password, bool? isEnabled}) {
    return WifiBandSettings(
      band: band,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class WifiSettings {
  final List<WifiBandSettings> bands;

  const WifiSettings({required this.bands});

  bool get isDualBand => bands.length > 1;
}
