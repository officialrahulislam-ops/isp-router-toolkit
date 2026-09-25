import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routers/router_manager.dart';
import '../../widgets/loading_view.dart';

class PppoeSettingsScreen extends StatefulWidget {
  const PppoeSettingsScreen({super.key});

  @override
  State<PppoeSettingsScreen> createState() => _PppoeSettingsScreenState();
}

class _PppoeSettingsScreenState extends State<PppoeSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await context.read<RouterManager>().getPppoeSettings();
    _usernameController.text = settings.username;
    _passwordController.text = settings.password;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update PPPoE credentials?'),
        content: const Text(
          'The internet connection may temporarily disconnect while the router applies these changes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final current = await context.read<RouterManager>().getPppoeSettings();
      final updated = current.copyWith(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      await context.read<RouterManager>().savePppoeSettings(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PPPoE settings saved.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PPPoE Settings')),
      body: SafeArea(
        child: _loading
            ? const LoadingView(message: 'Loading PPPoE settings…')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(labelText: 'PPPoE Username'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'PPPoE Password'),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onTertiaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'The internet connection may temporarily disconnect after saving.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _confirmAndSave,
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
