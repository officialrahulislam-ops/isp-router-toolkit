import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'services/latency_monitor.dart';
import 'services/network_controller.dart';
import 'services/password_store.dart';
import 'services/wifi_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IspHelperApp());
}

class IspHelperApp extends StatelessWidget {
  const IspHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkController(WifiService())),
        ChangeNotifierProvider(create: (_) => LatencyMonitor()),
        ChangeNotifierProvider(create: (_) => PasswordStore()..load()),
      ],
      child: MaterialApp(
        title: 'ISP Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
