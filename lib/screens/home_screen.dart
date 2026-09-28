import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/latency_stats.dart';
import '../core/theme.dart';
import '../models/wifi_snapshot.dart';
import '../services/latency_monitor.dart';
import '../services/network_controller.dart';
import '../services/open_router.dart';
import '../widgets/latency_chart.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenMonitor, required this.onOpenRouter});

  final VoidCallback onOpenMonitor;
  final VoidCallback onOpenRouter;

  @override
  Widget build(BuildContext context) {
    final net = context.watch<NetworkController>();
    final monitor = context.watch<LatencyMonitor>();
    final theme = Theme.of(context);
    final snap = net.snapshot;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => net.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ISP Helper',
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text('Network Overview',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: net.loading ? null : () => net.refresh(),
                  icon: net.loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatusCard(net: net),
            const SizedBox(height: 16),
            _PathCard(net: net),
            const SizedBox(height: 16),
            _MonitorCard(monitor: monitor, onTap: onOpenMonitor),
            const SizedBox(height: 16),
            SectionCard(
              title: 'ROUTER SETTINGS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change the Wi-Fi name, password or PPPoE on the router\'s own page.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: snap?.gatewayIp == null ? null : () => openRouterPage(context, snap!.gatewayIp!),
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: Text(snap?.gatewayIp == null ? 'Router address unknown' : 'Open ${snap!.gatewayIp}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onOpenRouter,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Saved passwords'),
                    ),
                  ),
                ],
              ),
            ),
            if (snap != null && snap.onWifi) ...[
              const SizedBox(height: 16),
              _DetailsCard(snap: snap),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.net});

  final NetworkController net;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snap = net.snapshot;

    final (Color color, String headline) = switch (net.health) {
      NetworkHealth.healthy => (AppColors.good, 'INTERNET CONNECTED'),
      NetworkHealth.noInternet => (AppColors.warn, 'NO INTERNET ACCESS'),
      NetworkHealth.routerUnreachable => (AppColors.bad, 'ROUTER NOT RESPONDING'),
      NetworkHealth.notOnWifi => (AppColors.bad, 'NOT CONNECTED TO WI-FI'),
      NetworkHealth.gatewayUnknown => (AppColors.warn, 'ROUTER ADDRESS UNKNOWN'),
      NetworkHealth.checking => (AppColors.neutral, 'CHECKING…'),
    };

    String title;
    if (snap == null) {
      title = 'Checking network…';
    } else if (!snap.onWifi) {
      title = 'Connect to the customer\'s Wi-Fi';
    } else {
      title = snap.ssid ?? 'Wi-Fi network';
    }

    final needsLocationHint = snap != null && snap.onWifi && snap.ssid == null;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (snap?.band != null) StatusPill(text: 'Wi-Fi ${snap!.band}', color: AppColors.good),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (snap?.gatewayIp != null)
            Text('Gateway ${snap!.gatewayIp}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(child: MetricTile(label: 'Router', value: fmtMs(net.routerMs), color: pingColor(net.routerMs))),
              Expanded(child: MetricTile(label: 'Internet', value: fmtMs(net.internetMs), color: pingColor(net.internetMs))),
              Expanded(child: MetricTile(label: 'Band', value: snap?.band ?? '—')),
              Expanded(
                child: MetricTile(
                  label: 'Signal',
                  value: snap?.rssiDbm == null ? '—' : '${snap!.rssiDbm} dBm',
                  color: snap == null ? null : signalColor(snap.signalQuality),
                ),
              ),
            ],
          ),
          if (needsLocationHint) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: AppColors.warn.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, size: 20, color: AppColors.warn),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Allow location access and keep Location turned on to show the Wi-Fi name.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(onPressed: openAppSettings, child: const Text('Settings')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Step { ok, fail, pending }

class _PathCard extends StatelessWidget {
  const _PathCard({required this.net});

  final NetworkController net;

  @override
  Widget build(BuildContext context) {
    final snap = net.snapshot;
    final onWifi = snap?.onWifi ?? false;
    final gateway = snap?.gatewayIp;

    final wifiStep = snap == null ? _Step.pending : (onWifi ? _Step.ok : _Step.fail);

    _Step routerStep;
    if (!onWifi) {
      routerStep = _Step.pending;
    } else if (gateway == null) {
      routerStep = _Step.fail;
    } else if (!net.checked) {
      routerStep = _Step.pending;
    } else {
      routerStep = net.routerMs != null ? _Step.ok : _Step.fail;
    }

    _Step internetStep;
    if (!onWifi || !net.checked) {
      internetStep = _Step.pending;
    } else {
      internetStep = net.internetMs != null ? _Step.ok : _Step.fail;
    }

    return SectionCard(
      title: 'CONNECTION PATH',
      child: Column(
        children: [
          _PathRow(
            label: 'Phone to Wi-Fi',
            detail: snap == null ? 'Checking…' : (onWifi ? (snap.ssid ?? 'Connected') : 'Not connected'),
            step: wifiStep,
            value: snap?.band ?? '',
          ),
          _PathRow(
            label: 'Router',
            detail: gateway ?? (onWifi ? 'Address unknown' : '—'),
            step: routerStep,
            value: routerStep == _Step.ok ? fmtMs(net.routerMs) : '',
          ),
          _PathRow(
            label: 'Internet',
            detail: 'Google DNS / Cloudflare',
            step: internetStep,
            value: internetStep == _Step.ok ? fmtMs(net.internetMs) : '',
          ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.label, required this.detail, required this.step, required this.value});

  final String label;
  final String detail;
  final _Step step;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color) = switch (step) {
      _Step.ok => (Icons.check_circle_rounded, AppColors.good),
      _Step.fail => (Icons.cancel_rounded, AppColors.bad),
      _Step.pending => (Icons.radio_button_unchecked_rounded, AppColors.neutral),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  const _MonitorCard({required this.monitor, required this.onTap});

  final LatencyMonitor monitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = monitor.stats;
    return SectionCard(
      title: 'LIVE NETWORK MONITOR',
      trailing: StatusPill(text: stats.status.label, color: statusColor(stats.status)),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target: ${monitor.target.label} (${monitor.target.detail})',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: MetricTile(label: 'PING', value: fmtMs(stats.lastMs), color: pingColor(stats.lastMs))),
              Expanded(child: MetricTile(label: 'JITTER', value: fmtMs(stats.jitterMs), color: jitterColor(stats.jitterMs))),
              Expanded(
                child: MetricTile(
                  label: 'LOSS',
                  value: stats.sent == 0 ? '—' : fmtPercent(stats.lossPercent),
                  color: stats.sent == 0 ? null : lossColor(stats.lossPercent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LatencyChart(samples: monitor.samples, height: 90),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.snap});

  final WifiSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (snap.phoneIp != null) ('Phone IP', snap.phoneIp!),
      if (snap.subnetMask != null) ('Subnet mask', snap.subnetMask!),
      if (snap.gatewayIp != null) ('Gateway', snap.gatewayIp!),
      if (snap.linkSpeedMbps != null) ('Link speed', '${snap.linkSpeedMbps} Mbps'),
      if (snap.frequencyMhz != null) ('Frequency', '${snap.frequencyMhz} MHz'),
      if (snap.rssiDbm != null) ('Signal quality', snap.signalQuality.label),
      if (snap.bssid != null) ('Router MAC (BSSID)', snap.bssid!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SectionCard(
      title: 'NETWORK DETAILS',
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
