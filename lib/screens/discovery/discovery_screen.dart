import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/errors/app_exceptions.dart';
import '../../routers/router_manager.dart';
import '../../widgets/loading_view.dart';
import '../authentication/authentication_screen.dart';

/// First screen the technician sees. Walks through:
/// Detect Wi-Fi → Find gateway → Identify router → hand off to auth.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDiscovery());
  }

  Future<void> _runDiscovery() async {
    final manager = context.read<RouterManager>();
    await manager.discoverRouter();
    if (!mounted) return;
    if (manager.routerInfo != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthenticationScreen()),
      );
    }
  }

  String _messageFor(RouterSessionState state) {
    switch (state) {
      case RouterSessionState.detectingNetwork:
        return 'Detecting Wi-Fi network…';
      case RouterSessionState.identifyingRouter:
        return 'Identifying router…';
      default:
        return 'Searching for router…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<RouterManager>(
          builder: (context, manager, _) {
            if (manager.state == RouterSessionState.error) {
              final error = manager.lastError;
              return ErrorStateView(
                title: _titleFor(error),
                message: error?.message ?? 'Something went wrong.',
                actionLabel: 'Try Again',
                onAction: _runDiscovery,
              );
            }
            return LoadingView(
              message: _messageFor(manager.state),
              detail: 'Make sure you\'re connected to the customer\'s Wi-Fi.',
            );
          },
        ),
      ),
    );
  }

  String _titleFor(AppException? error) {
    if (error is NoWifiConnectionException) return 'No Wi-Fi connection';
    if (error is GatewayUnreachableException) return 'Router not found';
    return 'Something went wrong';
  }
}
