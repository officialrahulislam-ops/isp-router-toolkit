import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routers/router_manager.dart';
import '../../widgets/loading_view.dart';
import '../dashboard/dashboard_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _showManualEntry = false;
  bool _isAttempting = false;
  final _passwordController = TextEditingController();
  bool _savePermanently = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryConfiguredCredentials());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryConfiguredCredentials() async {
    setState(() => _isAttempting = true);
    final manager = context.read<RouterManager>();
    final success = await manager.authenticateWithConfiguredCredentials();
    if (!mounted) return;
    setState(() => _isAttempting = false);
    if (success) {
      _goToDashboard();
    } else {
      setState(() => _showManualEntry = true);
    }
  }

  Future<void> _tryManual() async {
    if (_passwordController.text.isEmpty) return;
    setState(() => _isAttempting = true);
    final manager = context.read<RouterManager>();
    final success = await manager.authenticateManually(
      _passwordController.text,
      savePermanently: _savePermanently,
    );
    if (!mounted) return;
    setState(() => _isAttempting = false);
    if (success) {
      _goToDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log in. Check the password and try again.')),
      );
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<RouterManager>();
    final routerInfo = manager.routerInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('Authenticate')),
      body: SafeArea(
        child: _isAttempting
            ? LoadingView(
                message: 'Authenticating…',
                detail: routerInfo?.displayName,
              )
            : _showManualEntry
                ? _buildManualEntryForm(context, routerInfo?.displayName ?? 'Unknown Router')
                : const LoadingView(message: 'Authenticating…'),
      ),
    );
  }

  Widget _buildManualEntryForm(BuildContext context, String routerName) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Unable to authenticate', style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          Text(
            'The router password is not in your configured list. Enter it manually below.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text(routerName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Router admin password'),
            onSubmitted: (_) => _tryManual(),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _savePermanently,
            onChanged: (v) => setState(() => _savePermanently = v ?? false),
            title: const Text('Save to configured password list'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _tryManual, child: const Text('Log In')),
        ],
      ),
    );
  }
}
