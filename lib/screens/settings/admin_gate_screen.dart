import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/security/secure_storage_service.dart';
import 'admin_settings_screen.dart';

/// Simple PIN gate so ordinary technicians can't reach admin settings
/// (spec section 17: "Do not allow ordinary technicians to modify these
/// settings"). This is a UX gate, not a cryptographic boundary — the PIN
/// itself is stored via SecureStorageService like everything else
/// sensitive in the app.
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  final _pinController = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    final storedPin = await SecureStorageService.instance.readString(AppConstants.storageKeyAdminPin);

    // First-run: no admin PIN configured yet — let this attempt set one.
    if (storedPin == null) {
      if (_pinController.text.length < 4) {
        setState(() => _error = 'Choose a PIN of at least 4 digits.');
        return;
      }
      await SecureStorageService.instance.writeString(
        AppConstants.storageKeyAdminPin,
        _pinController.text,
      );
      _openAdmin();
      return;
    }

    if (_pinController.text == storedPin) {
      _openAdmin();
    } else {
      setState(() => _error = 'Incorrect PIN.');
    }
  }

  void _openAdmin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Enter Admin PIN', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 20),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(labelText: 'PIN', errorText: _error),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
