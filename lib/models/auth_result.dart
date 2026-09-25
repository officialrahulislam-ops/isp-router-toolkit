class AuthResult {
  final bool success;

  /// The credential that worked, ONLY kept in memory for the duration of
  /// the session object — never persisted unless the technician/admin
  /// explicitly opts to save it via the credential manager.
  final String? workingPassword;
  final String? sessionToken;

  const AuthResult({required this.success, this.workingPassword, this.sessionToken});

  const AuthResult.failure() : this(success: false);
}
