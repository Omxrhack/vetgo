/// Respuesta de login o verify-otp con tokens y usuario.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType,
    this.user,
    this.profile,
  });

  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? tokenType;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? profile;

  bool get hasAccessToken =>
      accessToken != null && accessToken!.isNotEmpty;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      tokenType: json['token_type'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
      profile: json['profile'] is Map<String, dynamic>
          ? json['profile'] as Map<String, dynamic>
          : null,
    );
  }
}
