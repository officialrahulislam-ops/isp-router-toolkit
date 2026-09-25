import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/wifi_settings.dart';
import '../../routers/router_manager.dart';
import '../../widgets/loading_view.dart';

class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  WifiSettings? _settings;
  bool _loading = true;
  bool _saving = false;
  final Map<WifiBand, TextEditingController> _ssidControllers = {};
  final Map<WifiBand, TextEditingController> _passwordControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await context.read<RouterManager>().getWifiSettings();
    for (final band in settings.bands) {
      _ssidControllers[band.band] = TextEditingController(text: band.ssid);
      _passwordControllers[band.band] = TextEditingController(text: band.password);
    }
    if (mounted) {
      setState(() {
        _settings = settings;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ssidControllers.values) {
      c.dispose();
    }
    for (final c in _passwordControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);

    final updatedBands = _settings!.bands.map((band) {
      return band.copyWith(
        ssid: _ssidControllers[band.band]!.text.trim(),
        password: _passwordControllers[band.band]!.text,
      );
    }).toList();

    try {
      await context.read<RouterManager>().saveWifiSettings(WifiSettings(bands: updatedBands));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wi-Fi settings saved.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t save changes. The router may have disconnected.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _bandLabel(WifiBand band) {
    switch (band) {
      case WifiBand.band2_4Ghz:
        return '2.4 GHz';
      case WifiBand.band5Ghz:
        return '5 GHz';
      case WifiBand.single:
        return 'Wi-Fi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wi-Fi Settings')),
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Loading Wi-Fi settings…')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final band in _settings!.bands) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_bandLabel(band.band), style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _ssidControllers[band.band],
                              decoration: const InputDecoration(labelText: 'Network Name (SSID)'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordControllers[band.band],
                              decoration: const InputDecoration(labelText: 'Password'),
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
      ),
    );
  }
}
