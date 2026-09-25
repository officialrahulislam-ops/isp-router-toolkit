/// Base type for every error the app surfaces. Each subtype maps 1:1 to
/// one of the error states described in the product spec (section 21),
/// so the UI layer can switch on type instead of parsing strings.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Phone is not connected to any Wi-Fi network.
class NoWifiConnectionException extends AppException {
  const NoWifiConnectionException()
      : super('Connect to the customer\'s Wi-Fi and try again.');
}

/// Gateway IP could not be determined or does not respond.
class GatewayUnreachableException extends AppException {
  final String? gatewayIp;
  const GatewayUnreachableException([this.gatewayIp])
      : super('Make sure you are connected to the router\'s Wi-Fi.');
}

/// A gateway was found, but no adapter recognizes it.
class UnsupportedRouterException extends AppException {
  final String gatewayIp;
  const UnsupportedRouterException(this.gatewayIp)
      : super('This router is not currently supported yet.');
}

/// None of the configured credentials worked, and no manual password
/// has been supplied (yet).
class AuthenticationFailedException extends AppException {
  const AuthenticationFailedException()
      : super('The router password may be different from your configured passwords.');
}

/// The router rejected a settings write, or the session dropped mid-save.
class SaveFailedException extends AppException {
  const SaveFailedException()
      : super('The router may have disconnected or rejected the request.');
}

/// A specific capability (e.g. connected devices) isn't implemented for
/// this adapter/firmware version. Distinct from "unsupported router" —
/// here the router itself IS supported, just not this one feature.
class UnsupportedCapabilityException extends AppException {
  final String capability;
  const UnsupportedCapabilityException(this.capability)
      : super('This router does not expose that setting.');
}

class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException() : super('The router took too long to respond.');
}
