import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/security/credential_manager.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISP / Admin Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _CredentialListSection(),
            SizedBox(height: 16),
            _SupportedRoutersSection(),
          ],
        ),
      ),
    );
  }
}

class _CredentialListSection extends StatefulWidget {
  const _CredentialListSection();

  @override
  State<_CredentialListSection> createState() => _CredentialListSectionState();
}

class _CredentialListSectionState extends State<_CredentialListSection> {
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CredentialManager.instance.load();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _addPassword() async {
    final value = _newPasswordController.text.trim();
    if (value.isEmpty) return;
    await CredentialManager.instance.addCredential(value);
    _newPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CredentialManager.instance,
      builder: (context, _) {
        final credentials = CredentialManager.instance.credentials;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Default Router Passwords', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 4),
                Text(
                  'Tried in order during automatic login. Stored encrypted on this device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final credential in credentials)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.vpn_key_rounded),
                    title: Text(credential),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => CredentialManager.instance.removeCredential(credential),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(hintText: 'Add password'),
                        onSubmitted: (_) => _addPassword(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _addPassword,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupportedRoutersSection extends StatelessWidget {
  const _SupportedRoutersSection();

  @override
  Widget build(BuildContext context) {
    // Static for now — wire up to RouterManager's adapter registry once
    // per-adapter enable/disable persistence is added (spec section 17).
    const supported = <String, bool>{
      'TP-Link': true,
      'Netis': false,
      'Tenda': false,
      'TOTOLINK': false,
      'Xiaomi': false,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported Routers', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 12),
            for (final entry in supported.entries)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: entry.value,
                onChanged: null, // read-only until adapter is fully implemented
                title: Text(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}
