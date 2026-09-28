import 'package:flutter/material.dart';
import '../models/wifi_snapshot.dart';
import 'latency_stats.dart';
import 'theme.dart';

String fmtMs(double? v) {
  if (v == null) return '—';
  return v < 10 ? '${v.toStringAsFixed(1)} ms' : '${v.round()} ms';
}

String fmtPercent(double v) => v == 0 ? '0%' : '${v.toStringAsFixed(v < 10 ? 1 : 0)}%';

Color pingColor(double? ms) {
  if (ms == null) return AppColors.neutral;
  if (ms < 60) return AppColors.good;
  if (ms < 120) return AppColors.warn;
  return AppColors.bad;
}

Color jitterColor(double? ms) {
  if (ms == null) return AppColors.neutral;
  if (ms < 15) return AppColors.good;
  if (ms < 40) return AppColors.warn;
  return AppColors.bad;
}

Color lossColor(double percent) {
  if (percent == 0) return AppColors.good;
  if (percent < 5) return AppColors.warn;
  return AppColors.bad;
}

Color statusColor(LinkStatus s) => switch (s) {
      LinkStatus.measuring => AppColors.neutral,
      LinkStatus.stable => AppColors.good,
      LinkStatus.unstable => AppColors.warn,
      LinkStatus.poor => AppColors.bad,
      LinkStatus.down => AppColors.bad,
    };

Color signalColor(SignalQuality q) => switch (q) {
      SignalQuality.unknown => AppColors.neutral,
      SignalQuality.excellent => AppColors.good,
      SignalQuality.good => AppColors.good,
      SignalQuality.fair => AppColors.warn,
      SignalQuality.weak => AppColors.bad,
    };
