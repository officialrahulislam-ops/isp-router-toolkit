import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Scrolling line chart of the most recent latency samples.
/// Lost probes (null) appear as red ticks along the bottom.
class LatencyChart extends StatelessWidget {
  const LatencyChart({
    super.key,
    required this.samples,
    this.height = 110,
    this.maxSamples = 60,
    this.showScale = false,
  });

  final List<double?> samples;
  final double height;
  final int maxSamples;
  final bool showScale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: CustomPaint(
            painter: _ChartPainter(
              samples: samples,
              maxSamples: maxSamples,
              showScale: showScale,
              line: AppColors.accent,
              grid: scheme.outlineVariant,
              loss: AppColors.bad,
              label: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.samples,
    required this.maxSamples,
    required this.showScale,
    required this.line,
    required this.grid,
    required this.loss,
    required this.label,
  });

  final List<double?> samples;
  final int maxSamples;
  final bool showScale;
  final Color line;
  final Color grid;
  final Color loss;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 12.0;
    const padBottom = 12.0;
    final plotH = size.height - padTop - padBottom;

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padTop + plotH * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final valid = samples.whereType<double>();
    var maxV = 50.0;
    if (valid.isNotEmpty) {
      maxV = math.max(50.0, valid.reduce(math.max) * 1.25);
    }

    final dx = size.width / (maxSamples - 1);
    final count = samples.length;
    double xOf(int i) => size.width - (count - 1 - i) * dx - 6;
    double yOf(double v) {
      final t = (v / maxV).clamp(0.0, 1.0).toDouble();
      return padTop + plotH * (1 - t);
    }

    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [line.withValues(alpha: 0.35), line.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final dotPaint = Paint()..color = line;
    final lossPaint = Paint()
      ..color = loss
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final segment = <Offset>[];
    void flush() {
      if (segment.isEmpty) return;
      if (segment.length == 1) {
        canvas.drawCircle(segment.first, 2.5, dotPaint);
      } else {
        final path = Path()..moveTo(segment.first.dx, segment.first.dy);
        for (final p in segment.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        final fill = Path.from(path)
          ..lineTo(segment.last.dx, size.height - padBottom)
          ..lineTo(segment.first.dx, size.height - padBottom)
          ..close();
        canvas.drawPath(fill, fillPaint);
        canvas.drawPath(path, linePaint);
      }
      segment.clear();
    }

    Offset? lastPoint;
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      final x = xOf(i);
      if (v == null) {
        flush();
        canvas.drawLine(
          Offset(x, size.height - padBottom - 14),
          Offset(x, size.height - padBottom),
          lossPaint,
        );
        lastPoint = null;
      } else {
        final p = Offset(x, yOf(v));
        segment.add(p);
        lastPoint = p;
      }
    }
    flush();

    if (lastPoint != null) {
      canvas.drawCircle(lastPoint, 5, Paint()..color = Colors.white);
      canvas.drawCircle(lastPoint, 3.5, dotPaint);
    }

    if (showScale) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${maxV.round()} ms',
          style: TextStyle(color: label, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, const Offset(8, 0));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
