import 'package:flutter_test/flutter_test.dart';
import 'package:isp_router_toolkit/core/latency_stats.dart';
import 'package:isp_router_toolkit/models/wifi_snapshot.dart';

void main() {
  group('LatencyStats', () {
    test('empty sample list is "measuring"', () {
      final s = LatencyStats.fromSamples([]);
      expect(s.sent, 0);
      expect(s.status, LinkStatus.measuring);
    });

    test('steady 20 ms with no loss is stable', () {
      final s = LatencyStats.fromSamples(List<double?>.filled(10, 20.0));
      expect(s.sent, 10);
      expect(s.lost, 0);
      expect(s.avgMs, 20.0);
      expect(s.jitterMs, 0.0);
      expect(s.lossPercent, 0);
      expect(s.status, LinkStatus.stable);
    });

    test('jitter is the mean gap between consecutive samples', () {
      final s = LatencyStats.fromSamples([10.0, 20.0, 10.0]);
      expect(s.jitterMs, 10.0);
    });

    test('three lost probes in a row means down', () {
      final s = LatencyStats.fromSamples([20.0, 20.0, null, null, null]);
      expect(s.lost, 3);
      expect(s.status, LinkStatus.down);
    });

    test('20 percent loss is poor', () {
      final s = LatencyStats.fromSamples([20.0, 20.0, 20.0, 20.0, null]);
      expect(s.lossPercent, 20);
      expect(s.status, LinkStatus.poor);
    });

    test('very high latency is poor', () {
      final s = LatencyStats.fromSamples(List<double?>.filled(6, 200.0));
      expect(s.status, LinkStatus.poor);
    });
  });

  group('WifiSnapshot', () {
    test('maps frequency to band', () {
      expect(const WifiSnapshot(onWifi: true, frequencyMhz: 2437).band, '2.4 GHz');
      expect(const WifiSnapshot(onWifi: true, frequencyMhz: 5180).band, '5 GHz');
      expect(const WifiSnapshot(onWifi: true, frequencyMhz: 5955).band, '6 GHz');
      expect(const WifiSnapshot(onWifi: true).band, isNull);
    });

    test('maps signal strength to quality', () {
      SignalQuality q(int rssi) => WifiSnapshot(onWifi: true, rssiDbm: rssi).signalQuality;
      expect(q(-50), SignalQuality.excellent);
      expect(q(-67), SignalQuality.good);
      expect(q(-72), SignalQuality.fair);
      expect(q(-80), SignalQuality.weak);
      expect(const WifiSnapshot(onWifi: true).signalQuality, SignalQuality.unknown);
    });
  });
}
