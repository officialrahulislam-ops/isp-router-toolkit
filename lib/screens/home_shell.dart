import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/latency_monitor.dart';
import '../services/network_controller.dart';
import 'home_screen.dart';
import 'monitor_screen.dart';
import 'router_screen.dart';

/// Bottom-navigation container. Also starts/stops the background probing
/// so nothing runs while the app is not on screen.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  late final NetworkController _net;
  late final LatencyMonitor _monitor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _net = context.read<NetworkController>();
    _monitor = context.read<LatencyMonitor>();
    _net.addListener(_syncGateway);
    // Start after the first frame: both controllers notify listeners
    // immediately, which is not allowed while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _net.start();
      _monitor.start();
    });
  }

  void _syncGateway() => _monitor.setGateway(_net.snapshot?.gatewayIp);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _net.start(askPermission: false);
      _monitor.start();
    } else if (state == AppLifecycleState.paused) {
      _net.stop();
      _monitor.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _net.removeListener(_syncGateway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            onOpenMonitor: () => setState(() => _index = 1),
            onOpenRouter: () => setState(() => _index = 2),
          ),
          const MonitorScreen(),
          const RouterScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed_rounded), label: 'Monitor'),
          NavigationDestination(icon: Icon(Icons.router_outlined), selectedIcon: Icon(Icons.router_rounded), label: 'Router'),
        ],
      ),
    );
  }
}
