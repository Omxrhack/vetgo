import '../auth/auth_session.dart';

Map<String, dynamic>? _asJsonMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

/// Resultado de `POST /api/auth/login`.
class LoginOutcome {
  const LoginOutcome._({
    required this.kind,
    this.session,
    this.message,
    this.code,
    this.emailForVerification,
    this.statusCode,
  });

  factory LoginOutcome.success(AuthSession session) {
    return LoginOutcome._(kind: LoginKind.success, session: session);
  }

  factory LoginOutcome.failure(
    String message, {
    String? code,
    int? statusCode,
  }) {
    return LoginOutcome._(
      kind: LoginKind.failure,
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  factory LoginOutcome.needsVerification(String email, String message) {
    return LoginOutcome._(
      kind: LoginKind.needsVerification,
      message: message,
      emailForVerification: email,
    );
  }

  final LoginKind kind;
  final AuthSession? session;
  final String? message;
  final String? code;
  final String? emailForVerification;
  final int? statusCode;
}

enum LoginKind { success, failure, needsVerification }

/// Resultado de `POST /api/auth/register`.
class RegisterOutcome {
  const RegisterOutcome._({
    required this.kind,
    this.email = '',
    this.alreadyUnverified = false,
    this.message,
    this.code,
    this.statusCode,
  });

  factory RegisterOutcome.toOtp({
    required String email,
    bool alreadyUnverified = false,
  }) {
    return RegisterOutcome._(
      kind: RegisterKind.goToOtp,
      email: email,
      alreadyUnverified: alreadyUnverified,
    );
  }

  factory RegisterOutcome.emailAlreadyVerified(String message) {
    return RegisterOutcome._(
      kind: RegisterKind.emailAlreadyVerified,
      message: message,
    );
  }

  factory RegisterOutcome.failure(
    String message, {
    String? code,
    int? statusCode,
  }) {
    return RegisterOutcome._(
      kind: RegisterKind.failure,
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  final RegisterKind kind;
  final String email;
  final bool alreadyUnverified;
  final String? message;
  final String? code;
  final int? statusCode;
}

enum RegisterKind { goToOtp, emailAlreadyVerified, failure }

/// Resultado de `POST /api/auth/verify-otp`.
class VerifyOtpOutcome {
  const VerifyOtpOutcome._({
    required this.ok,
    this.session,
    this.message,
  });

  factory VerifyOtpOutcome.success(AuthSession session) {
    return VerifyOtpOutcome._(ok: true, session: session);
  }

  factory VerifyOtpOutcome.failure(String message) {
    return VerifyOtpOutcome._(ok: false, message: message);
  }

  final bool ok;
  final AuthSession? session;
  final String? message;
}

Map<String, dynamic>? parseResponseMap(dynamic data) => _asJsonMap(data);
