import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/network_controller.dart';
import '../services/open_router.dart';
import '../services/password_store.dart';
import '../widgets/section_card.dart';

class RouterScreen extends StatefulWidget {
  const RouterScreen({super.key});

  @override
  State<RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends State<RouterScreen> {
  final TextEditingController _address = TextEditingController();
  late final NetworkController _net;
  bool _edited = false;
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _net = context.read<NetworkController>();
    _fillFromGateway();
    _net.addListener(_fillFromGateway);
  }

  void _fillFromGateway() {
    final gateway = _net.snapshot?.gatewayIp;
    if (!_edited && gateway != null && _address.text != gateway) {
      _address.text = gateway;
    }
  }

  @override
  void dispose() {
    _net.removeListener(_fillFromGateway);
    _address.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(message);
  }

  Future<void> _addPasswords() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add passwords'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'One password per line'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final items = result.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (items.isEmpty) return;
    await context.read<PasswordStore>().addAll(items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = context.watch<PasswordStore>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Router', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ADMIN PAGE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _address,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => _edited = true,
                  decoration: InputDecoration(
                    labelText: 'Router address',
                    prefixIcon: const Icon(Icons.router_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Copy address',
                      onPressed: () => _copy(_address.text, 'Address copied.'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openRouterPage(context, _address.text),
                    icon: const Icon(Icons.open_in_browser_rounded),
                    label: const Text('Open router page'),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => openRouterPage(context, _address.text, https: true),
                    child: const Text('Try HTTPS instead'),
                  ),
                ),
                Text(
                  'Opens in your phone\'s browser. Log in there to change the Wi-Fi name, password or PPPoE.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'SAVED PASSWORDS',
            trailing: TextButton.icon(
              onPressed: _addPasswords,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (store.items.isEmpty)
                  Text(
                    'No passwords saved yet. Add the admin passwords you usually try, then copy one and '
                    'paste it into the router\'s login page.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  )
                else
                  for (final pw in store.items) _passwordTile(pw),
                const SizedBox(height: 8),
                Text(
                  'Stored encrypted on this phone. Never sent anywhere.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordTile(String pw) {
    final shown = _revealed.contains(pw);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.key_rounded),
      title: Text(shown ? pw : '••••••••••', style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: shown ? 'Hide' : 'Show',
            icon: Icon(shown ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            onPressed: () => setState(() {
              if (shown) {
                _revealed.remove(pw);
              } else {
                _revealed.add(pw);
              }
            }),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copy(pw, 'Password copied. Paste it into the router login page.'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => context.read<PasswordStore>().remove(pw),
          ),
        ],
      ),
    );
  }
}
