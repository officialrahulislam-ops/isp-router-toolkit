import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors/app_exceptions.dart';
import '../../models/pppoe_settings.dart';
import '../../models/router_info.dart';
import '../../models/wifi_settings.dart';
import '../../routers/router_adapter.dart';
import '../../routers/router_manager.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/setting_card.dart';
import '../../widgets/status_card.dart';
import '../devices/devices_screen.dart';
import '../discovery/discovery_screen.dart';
import '../pppoe/pppoe_settings_screen.dart';
import '../wifi/wifi_settings_screen.dart';

/// The unified, manufacturer-agnostic dashboard (spec section 9/16).
/// Everything here reads through RouterManager — it never knows or
/// cares which adapter is behind it.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  WifiSettings? _wifi;
  PppoeSettings? _pppoe;
  int? _deviceCount;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final manager = context.read<RouterManager>();
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await manager.refreshRouterInfo();

      if (manager.supports(RouterCapability.wifiSettings)) {
        _wifi = await manager.getWifiSettings();
      }
      if (manager.supports(RouterCapability.pppoeSettings)) {
        _pppoe = await manager.getPppoeSettings();
      }
      if (manager.supports(RouterCapability.connectedDevices)) {
        final devices = await manager.getConnectedDevices();
        _deviceCount = devices.length;
      }
    } on AppException catch (e) {
      _loadError = e.message;
    } catch (e) {
      _loadError = 'Could not load router information.';
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmReboot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restart router?'),
        content: const Text('Internet connection will temporarily disconnect.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restart')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<RouterManager>().rebootRouter();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reboot command sent.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t restart the router. Try again.')),
      );
    }
  }

  Future<void> _disconnectAndRestart() async {
    await context.read<RouterManager>().reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DiscoveryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<RouterManager>();
    final RouterInfo? info = manager.routerInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Router'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Disconnect',
            onPressed: _disconnectAndRestart,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Loading router information…')
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    StatusCard(
                      title: info?.displayName ?? 'Unknown Router',
                      subtitle: info?.gatewayIp ?? '',
                      isOnline: _pppoe?.status != PppoeStatus.disconnected,
                    ),
                    const SizedBox(height: 16),
                    if (_loadError != null) _buildPartialErrorBanner(),
                    if (_wifi != null) ...[
                      _buildWifiSummaryCard(context, _wifi!),
                      const SizedBox(height: 16),
                    ],
                    if (_pppoe != null) ...[
                      _buildPppoeSummaryCard(context, _pppoe!),
                      const SizedBox(height: 16),
                    ],
                    if (manager.supports(RouterCapability.connectedDevices)) ...[
                      _buildDevicesRow(context, _deviceCount ?? 0),
                      const SizedBox(height: 16),
                    ],
                    _buildRouterInfoCard(context, info),
                    const SizedBox(height: 16),
                    if (manager.supports(RouterCapability.reboot))
                      OutlinedButton.icon(
                        onPressed: _confirmReboot,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reboot Router'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPartialErrorBanner() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_loadError!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiSummaryCard(BuildContext context, WifiSettings wifi) {
    return SettingSectionCard(
      title: 'Wi-Fi',
      children: [
        for (final band in wifi.bands) ...[
          SettingRow(
            label: _bandLabel(band.band),
            value: band.ssid,
            onEdit: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WifiSettingsScreen()),
            ),
          ),
        ],
        if (wifi.bands.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No Wi-Fi settings available for this router yet.'),
          ),
      ],
    );
  }

  String _bandLabel(WifiBand band) {
    switch (band) {
      case WifiBand.band2_4Ghz:
        return '2.4 GHz';
      case WifiBand.band5Ghz:
        return '5 GHz';
      case WifiBand.single:
        return 'Wi-Fi Name';
    }
  }

  Widget _buildPppoeSummaryCard(BuildContext context, PppoeSettings pppoe) {
    return SettingSectionCard(
      title: 'PPPoE',
      children: [
        SettingRow(
          label: 'Username',
          value: pppoe.username,
          onEdit: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PppoeSettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesRow(BuildContext context, int count) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.devices_rounded),
        title: const Text('Connected Devices'),
        trailing: Text('$count', style: Theme.of(context).textTheme.titleMedium),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DevicesScreen()),
        ),
      ),
    );
  }

  Widget _buildRouterInfoCard(BuildContext context, RouterInfo? info) {
    if (info == null) return const SizedBox.shrink();
    return SettingSectionCard(
      title: 'Router',
      children: [
        SettingRow(label: 'Manufacturer', value: info.manufacturer ?? '—'),
        if (info.model != null) SettingRow(label: 'Model', value: info.model!),
        if (info.firmwareVersion != null) SettingRow(label: 'Firmware', value: info.firmwareVersion!),
        SettingRow(label: 'Gateway', value: info.gatewayIp),
        if (info.macAddress != null) SettingRow(label: 'MAC', value: info.macAddress!),
      ],
    );
  }
}
