/// Respuesta de login, verify-otp, refresh o onboarding.
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

  /// Flags del snapshot `user` del backend (`userPayload`).
  bool get isVerified => user?['is_verified'] == true;

  bool get onboardingCompleted => user?['onboarding_completed'] == true;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      tokenType: json['token_type'] as String?,
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
      profile: json['profile'] is Map<String, dynamic>
          ? json['profile'] as Map<String, dynamic>
          : null,
    );
  }

  /// Combina tokens existentes con user/profile nuevos (p. ej. `GET /me` u onboarding).
  AuthSession merge({
    String? accessToken,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
    Map<String, dynamic>? user,
    Map<String, dynamic>? profile,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}
