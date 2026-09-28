import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../services/latency_monitor.dart';
import '../widgets/latency_chart.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<LatencyMonitor>();
    final theme = Theme.of(context);
    final stats = monitor.stats;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Live Monitor',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              StatusPill(text: stats.status.label, color: statusColor(stats.status)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ProbeTarget>(
              segments: const [
                ButtonSegment(value: ProbeTarget.gateway, label: Text('Router')),
                ButtonSegment(value: ProbeTarget.googleDns, label: Text('Google')),
                ButtonSegment(value: ProbeTarget.cloudflare, label: Text('Cloudflare')),
              ],
              selected: {monitor.target},
              onSelectionChanged: (s) => monitor.setTarget(s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monitor.hasTarget
                ? 'Target: ${monitor.host} · ${monitor.target.detail}'
                : 'Router address unknown. Connect to the customer\'s Wi-Fi first.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'LATENCY (LAST 60 SECONDS)',
            child: LatencyChart(samples: monitor.samples, height: 200, showScale: true),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'STATISTICS',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: MetricTile(label: 'CURRENT', value: fmtMs(stats.lastMs), color: pingColor(stats.lastMs))),
                    Expanded(child: MetricTile(label: 'AVERAGE', value: fmtMs(stats.avgMs), color: pingColor(stats.avgMs))),
                    Expanded(child: MetricTile(label: 'JITTER', value: fmtMs(stats.jitterMs), color: jitterColor(stats.jitterMs))),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: MetricTile(label: 'BEST', value: fmtMs(stats.minMs))),
                    Expanded(child: MetricTile(label: 'WORST', value: fmtMs(stats.maxMs))),
                    Expanded(
                      child: MetricTile(
                        label: 'PACKET LOSS',
                        value: stats.sent == 0 ? '—' : '${fmtPercent(stats.lossPercent)} (${stats.lost}/${stats.sent})',
                        color: stats.sent == 0 ? null : lossColor(stats.lossPercent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: monitor.isRunning ? monitor.stop : monitor.start,
                  icon: Icon(monitor.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(monitor.isRunning ? 'Pause' : 'Resume'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: monitor.clear,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'HOW TO READ THIS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tip(
                  color: AppColors.warn,
                  text: 'Router target is slow or drops packets: the problem is on the customer\'s Wi-Fi '
                      '(weak signal, interference, distance).',
                ),
                const SizedBox(height: 8),
                _Tip(
                  color: AppColors.bad,
                  text: 'Router is fine but Google and Cloudflare fail: the problem is beyond the router '
                      '(PPPoE login, ONU, fibre line or the ISP).',
                ),
                const SizedBox(height: 10),
                Text(
                  'Times are measured from TCP connection speed, not ICMP ping. They follow real ping '
                  'closely but can differ by a few milliseconds.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
