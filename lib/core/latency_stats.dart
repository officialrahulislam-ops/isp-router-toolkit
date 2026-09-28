import 'dart:math' as math;

enum LinkStatus { measuring, stable, unstable, poor, down }

extension LinkStatusLabel on LinkStatus {
  String get label => switch (this) {
        LinkStatus.measuring => 'Measuring',
        LinkStatus.stable => 'Stable',
        LinkStatus.unstable => 'Unstable',
        LinkStatus.poor => 'Poor',
        LinkStatus.down => 'Down',
      };
}

/// Statistics over a window of latency samples. A `null` sample means the
/// probe got no answer (counted as packet loss).
class LatencyStats {
  const LatencyStats({
    required this.sent,
    required this.lost,
    required this.status,
    this.lastMs,
    this.avgMs,
    this.minMs,
    this.maxMs,
    this.jitterMs,
  });

  final int sent;
  final int lost;
  final LinkStatus status;
  final double? lastMs;
  final double? avgMs;
  final double? minMs;
  final double? maxMs;

  /// Mean absolute difference between consecutive successful samples.
  final double? jitterMs;

  double get lossPercent => sent == 0 ? 0 : lost * 100 / sent;

  static const empty = LatencyStats(sent: 0, lost: 0, status: LinkStatus.measuring);

  factory LatencyStats.fromSamples(List<double?> samples) {
    if (samples.isEmpty) return empty;

    final ok = samples.whereType<double>().toList();
    final sent = samples.length;
    final lost = sent - ok.length;

    double? avg;
    double? minV;
    double? maxV;
    double? jitter;

    if (ok.isNotEmpty) {
      avg = ok.reduce((a, b) => a + b) / ok.length;
      minV = ok.reduce(math.min);
      maxV = ok.reduce(math.max);
    }
    if (ok.length >= 2) {
      var sum = 0.0;
      for (var i = 1; i < ok.length; i++) {
        sum += (ok[i] - ok[i - 1]).abs();
      }
      jitter = sum / (ok.length - 1);
    }

    final recent = samples.length >= 3 ? samples.sublist(samples.length - 3) : samples;
    final recentAllLost = samples.length >= 3 && recent.every((s) => s == null);

    LinkStatus status;
    if (recentAllLost) {
      status = LinkStatus.down;
    } else if (samples.length < 5 || avg == null) {
      status = LinkStatus.measuring;
    } else {
      final loss = lost * 100 / sent;
      final j = jitter ?? 0;
      if (loss >= 10 || avg > 150 || j > 50) {
        status = LinkStatus.poor;
      } else if (loss >= 2 || avg > 80 || j > 20) {
        status = LinkStatus.unstable;
      } else {
        status = LinkStatus.stable;
      }
    }

    return LatencyStats(
      sent: sent,
      lost: lost,
      status: status,
      lastMs: samples.last,
      avgMs: avg,
      minMs: minV,
      maxMs: maxV,
      jitterMs: jitter,
    );
  }
}
