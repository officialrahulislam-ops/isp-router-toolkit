import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connected_device.dart';
import '../../routers/router_manager.dart';
import '../../widgets/device_card.dart';
import '../../widgets/loading_view.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<ConnectedDevice>? _devices;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final devices = await context.read<RouterManager>().getConnectedDevices();
    if (mounted) setState(() => _devices = devices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Devices${_devices != null ? ' (${_devices!.length})' : ''}'),
      ),
      body: SafeArea(
        child: _devices == null
            ? const LoadingView(message: 'Loading connected devices…')
            : RefreshIndicator(
                onRefresh: _load,
                child: _devices!.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('No devices found.')),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _devices!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => Card(
                          child: DeviceCard(device: _devices![i]),
                        ),
                      ),
              ),
      ),
    );
  }
}
