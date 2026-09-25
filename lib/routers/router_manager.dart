import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/safe_logger.dart';
import '../core/networking/network_info_service.dart';
import '../core/networking/router_prober.dart';
import '../core/security/credential_manager.dart';
import '../models/auth_result.dart';
import '../models/connected_device.dart';
import '../models/pppoe_settings.dart';
import '../models/router_info.dart';
import '../models/wifi_settings.dart';
import 'generic/generic_adapter.dart';
import 'router_adapter.dart';
import 'tplink/tplink_archer_c6_adapter.dart';

enum RouterSessionState {
  idle,
  detectingNetwork,
  identifyingRouter,
  authenticating,
  ready,
  error,
}

/// This is the ONLY class screens should depend on for router
/// interaction. It:
///   1. Detects the gateway (via NetworkInfoService)
///   2. Runs identification by asking each registered adapter
///      "canHandle(gatewayIp)?" until one says yes
///   3. Attempts the configured credential list against the winning
///      adapter, falling back to manual password entry
///   4. Exposes the resulting [RouterAdapter] to the rest of the app
///      behind the same interface regardless of manufacturer
///
/// Adding a new manufacturer means adding one line to [_registerAdapters]
/// — nothing else in the app changes.
class RouterManager extends ChangeNotifier {
  final NetworkInfoService _networkInfo;
  final RouterProber _prober;

  RouterManager({NetworkInfoService? networkInfo, RouterProber? prober})
      : _networkInfo = networkInfo ?? NetworkInfoService(),
        _prober = prober ?? RouterProber();

  RouterSessionState _state = RouterSessionState.idle;
  RouterSessionState get state => _state;

  RouterInfo? _routerInfo;
  RouterInfo? get routerInfo => _routerInfo;

  RouterAdapter? _activeAdapter;
  RouterAdapter? get activeAdapter => _activeAdapter;

  AppException? _lastError;
  AppException? get lastError => _lastError;

  /// Factories rather than instances, so each identification run gets a
  /// fresh adapter object (avoids stale session state between runs).
  List<RouterAdapter Function(String gatewayIp)> _registerAdapters() => [
        (ip) => TpLinkArcherC6Adapter(ip),
        // Add future manufacturers here, e.g.:
        // (ip) => NetisAdapter(ip),
        // (ip) => TendaAdapter(ip),
      ];

  void _setState(RouterSessionState s) {
    _state = s;
    notifyListeners();
  }

  /// Runs the full discovery flow: Wi-Fi check → gateway detection →
  /// identification. Does NOT attempt authentication — call
  /// [authenticateWithConfiguredCredentials] or [authenticateManually]
  /// next once this resolves.
  Future<void> discoverRouter() async {
    _lastError = null;
    try {
      _setState(RouterSessionState.detectingNetwork);
      final snapshot = await _networkInfo.captureSnapshot();
      final gatewayIp = snapshot.gatewayIp;
      if (gatewayIp == null || gatewayIp.isEmpty) {
        throw const GatewayUnreachableException();
      }

      _setState(RouterSessionState.identifyingRouter);
      final probe = await _prober.probe(gatewayIp);
      if (probe == null) {
        throw GatewayUnreachableException(gatewayIp);
      }

      RouterAdapter? winner;
      for (final factory in _registerAdapters()) {
        final candidate = factory(gatewayIp);
        try {
          if (await candidate.canHandle(gatewayIp)) {
            winner = candidate;
            break;
          }
        } catch (e) {
          SafeLogger.w('Adapter canHandle threw', data: {'adapter': candidate.adapterId});
        }
      }

      winner ??= GenericAdapter(gatewayIp);
      _activeAdapter = winner;
      _routerInfo = RouterInfo(
        gatewayIp: gatewayIp,
        manufacturer: winner.manufacturerName == 'Unknown' ? null : winner.manufacturerName,
        model: winner.modelName,
        adapterId: winner.adapterId == 'generic' ? null : winner.adapterId,
      );

      SafeLogger.i('Router identified', data: {
        'gatewayIp': gatewayIp,
        'adapterId': winner.adapterId,
      });

      _setState(RouterSessionState.idle); // caller proceeds to authenticate
    } on AppException catch (e) {
      _lastError = e;
      _setState(RouterSessionState.error);
    } catch (e) {
      _lastError = const GatewayUnreachableException();
      SafeLogger.e('Unexpected error during discovery', error: e);
      _setState(RouterSessionState.error);
    }
  }

  /// Tries every password in the technician's configured list, in order,
  /// stopping at the first success.
  Future<bool> authenticateWithConfiguredCredentials() async {
    final adapter = _activeAdapter;
    if (adapter == null || _routerInfo == null) return false;

    _setState(RouterSessionState.authenticating);
    await CredentialManager.instance.load();

    for (final password in CredentialManager.instance.credentials) {
      try {
        final result = await adapter.authenticate(_routerInfo!.gatewayIp, password);
        if (result.success) {
          _setState(RouterSessionState.ready);
          return true;
        }
      } catch (e) {
        // Swallow individual attempt failures and keep trying the list;
        // only surface an error if every candidate fails.
        SafeLogger.w('Credential attempt failed', data: {'adapter': adapter.adapterId});
      }
    }

    _lastError = const AuthenticationFailedException();
    _setState(RouterSessionState.error);
    return false;
  }

  /// Manual fallback when none of the configured credentials worked.
  /// [savePermanently] mirrors spec section 8: manual passwords are
  /// NOT auto-saved unless the technician/admin explicitly asks.
  Future<bool> authenticateManually(String password, {bool savePermanently = false}) async {
    final adapter = _activeAdapter;
    if (adapter == null || _routerInfo == null) return false;

    _setState(RouterSessionState.authenticating);
    try {
      final result = await adapter.authenticate(_routerInfo!.gatewayIp, password);
      if (result.success) {
        if (savePermanently) {
          await CredentialManager.instance.addCredential(password);
        }
        _setState(RouterSessionState.ready);
        return true;
      }
      _lastError = const AuthenticationFailedException();
      _setState(RouterSessionState.error);
      return false;
    } catch (e) {
      _lastError = const AuthenticationFailedException();
      SafeLogger.e('Manual authentication failed', error: e);
      _setState(RouterSessionState.error);
      return false;
    }
  }

  Future<RouterInfo> refreshRouterInfo() async {
    final adapter = _requireReadyAdapter();
    final info = await adapter.getRouterInfo();
    _routerInfo = info;
    notifyListeners();
    return info;
  }

  Future<WifiSettings> getWifiSettings() => _requireReadyAdapter().getWifiSettings();

  Future<void> saveWifiSettings(WifiSettings settings) async {
    try {
      await _requireReadyAdapter().setWifiSettings(settings);
    } catch (e) {
      SafeLogger.e('Failed to save Wi-Fi settings', error: e);
      throw const SaveFailedException();
    }
  }

  Future<PppoeSettings> getPppoeSettings() => _requireReadyAdapter().getPppoeSettings();

  Future<void> savePppoeSettings(PppoeSettings settings) async {
    try {
      await _requireReadyAdapter().setPppoeSettings(settings);
    } catch (e) {
      SafeLogger.e('Failed to save PPPoE settings', error: e);
      throw const SaveFailedException();
    }
  }

  Future<List<ConnectedDevice>> getConnectedDevices() =>
      _requireReadyAdapter().getConnectedDevices();

  Future<void> rebootRouter() => _requireReadyAdapter().rebootRouter();

  bool supports(RouterCapability capability) =>
      _activeAdapter?.supportedCapabilities.contains(capability) ?? false;

  Future<void> reset() async {
    await _activeAdapter?.disconnect();
    _activeAdapter = null;
    _routerInfo = null;
    _lastError = null;
    _setState(RouterSessionState.idle);
  }

  RouterAdapter _requireReadyAdapter() {
    final adapter = _activeAdapter;
    if (adapter == null) {
      throw const GatewayUnreachableException();
    }
    return adapter;
  }
}
