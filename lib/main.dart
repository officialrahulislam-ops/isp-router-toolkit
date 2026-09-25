import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routers/router_manager.dart';
import 'screens/discovery/discovery_screen.dart';

void main() {
  runApp(const IspRouterApp());
}

class IspRouterApp extends StatelessWidget {
  const IspRouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouterManager()),
      ],
      child: MaterialApp(
        title: 'ISP Router Toolkit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const DiscoveryScreen(),
      ),
    );
  }
}
