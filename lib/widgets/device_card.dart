import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/connected_device.dart';

class DeviceCard extends StatelessWidget {
  final ConnectedDevice device;

  const DeviceCard({super.key, required this.device});

  IconData _iconFor(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi2_4:
      case ConnectionType.wifi5:
        return Icons.wifi_rounded;
      case ConnectionType.ethernet:
        return Icons.settings_ethernet_rounded;
      case ConnectionType.unknown:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <String>[
      device.ipAddress,
      if (device.macAddress != null) device.macAddress!,
      if (device.linkSpeedMbps != null) '${device.linkSpeedMbps} Mbps',
    ].join(' · ');

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_iconFor(device.connectionType), size: 20, color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text(device.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(details, style: theme.textTheme.bodySmall),
      trailing: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: device.isOnline ? AppStatusColors.online : theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
