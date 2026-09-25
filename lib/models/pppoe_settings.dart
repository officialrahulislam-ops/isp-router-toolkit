enum PppoeStatus { connected, disconnected, connecting, unknown }

class PppoeSettings {
  final String username;
  final String password;
  final PppoeStatus status;
  final String? wanIp;
  final Duration? uptime;

  const PppoeSettings({
    required this.username,
    required this.password,
    this.status = PppoeStatus.unknown,
    this.wanIp,
    this.uptime,
  });

  PppoeSettings copyWith({String? username, String? password}) {
    return PppoeSettings(
      username: username ?? this.username,
      password: password ?? this.password,
      status: status,
      wanIp: wanIp,
      uptime: uptime,
    );
  }
}
