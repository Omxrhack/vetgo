import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../config/app_config.dart';
import 'auth_outcomes.dart';

/// Cliente HTTP para el backend Vetgo.
///
/// Rutas bajo `/api` ([petixfy-backend/src/index.js]). El endpoint `/health` está fuera de `/api`.
class VetgoApiClient {
  VetgoApiClient()
      : _root = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ),
        _api = Dio(
          BaseOptions(
            baseUrl: '${AppConfig.apiBaseUrl}/api',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              Headers.contentTypeHeader: Headers.jsonContentType,
              Headers.acceptHeader: Headers.jsonContentType,
            },
          ),
        );

  final Dio _root;
  final Dio _api;

  /// Dio para llamadas a `/api/*`.
  Dio get api => _api;

  /// Comprueba `GET /health` en la raíz del servidor (no bajo `/api`).
  Future<HealthCheckResult> checkHealth() async {
    try {
      final response = await _root.get<dynamic>('${AppConfig.apiBaseUrl}/health');
      final data = response.data;
      final bodyOk = data is Map && data['ok'] == true;
      final ok = response.statusCode == 200 && bodyOk;
      return HealthCheckResult(ok: ok, message: ok ? 'API OK' : 'Respuesta inesperada');
    } on DioException catch (e) {
      return HealthCheckResult(
        ok: false,
        message: _dioErrorMessage(e),
      );
    } catch (e) {
      return HealthCheckResult(ok: false, message: e.toString());
    }
  }

  static String _dioErrorMessage(DioException e) {
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    return e.type.toString();
  }

  /// `POST /api/auth/login`
  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      );
      final data = r.data;
      if (data == null) {
        return LoginOutcome.failure('Respuesta vacía del servidor');
      }
      return LoginOutcome.success(AuthSession.fromJson(data));
    } on DioException catch (e) {
      return _loginFromDio(e);
    }
  }

  LoginOutcome _loginFromDio(DioException e) {
    final status = e.response?.statusCode;
    final map = parseResponseMap(e.response?.data);
    final code = map?['code'] as String?;
    final err = map?['error']?.toString() ??
        e.message ??
        'No se pudo conectar. Revisa la red.';
    if (status == 403 && code == 'EMAIL_NOT_CONFIRMED') {
      final user = map?['user'];
      var mail = '';
      if (user is Map && user['email'] != null) {
        mail = user['email'].toString();
      }
      return LoginOutcome.needsVerification(mail, err);
    }
    if (status == 429 && code == 'EMAIL_RATE_LIMIT') {
      return LoginOutcome.failure(err, code: code, statusCode: status);
    }
    if (status == 401) {
      return LoginOutcome.failure(
        'Correo o contraseña incorrectos.',
        code: code,
        statusCode: status,
      );
    }
    return LoginOutcome.failure(err, code: code, statusCode: status);
  }

  /// `POST /api/auth/register`
  Future<RegisterOutcome> register({
    required String email,
    required String password,
  }) async {
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: <String, dynamic>{
          'email': email.trim(),
          'password': password,
        },
      );
      final data = r.data;
      if (data == null) {
        return RegisterOutcome.failure('Respuesta vacía del servidor');
      }
      final vr = data['verification_required'] == true;
      final emailOut = _emailFromRegisterBody(data, fallback: email);
      if (vr && (r.statusCode == 201 || r.statusCode == 200)) {
        return RegisterOutcome.toOtp(
          email: emailOut,
          alreadyUnverified: data['already_registered'] == true,
        );
      }
      return RegisterOutcome.failure(
        'No se pudo iniciar la verificación. Intenta de nuevo.',
      );
    } on DioException catch (e) {
      return _registerFromDio(e, email);
    }
  }

  String _emailFromRegisterBody(Map<String, dynamic> data, {required String fallback}) {
    final user = data['user'];
    if (user is Map && user['email'] != null) {
      return user['email'].toString();
    }
    return fallback.trim();
  }

  RegisterOutcome _registerFromDio(DioException e, String email) {
    final status = e.response?.statusCode;
    final map = parseResponseMap(e.response?.data);
    final code = map?['code'] as String?;
    final err = map?['error']?.toString() ??
        e.message ??
        'Error al registrarse.';
    if (status == 409 && code == 'EMAIL_ALREADY_VERIFIED') {
      return RegisterOutcome.emailAlreadyVerified(err);
    }
    if (status == 429 && code == 'EMAIL_RATE_LIMIT') {
      return RegisterOutcome.failure(err, code: code, statusCode: status);
    }
    return RegisterOutcome.failure(err, code: code, statusCode: status);
  }

  /// `POST /api/auth/verify-otp`
  Future<VerifyOtpOutcome> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: <String, dynamic>{
          'email': email.trim(),
          'token': token.trim(),
        },
      );
      final data = r.data;
      if (data == null) {
        return VerifyOtpOutcome.failure('Respuesta vacía del servidor');
      }
      return VerifyOtpOutcome.success(AuthSession.fromJson(data));
    } on DioException catch (e) {
      final map = parseResponseMap(e.response?.data);
      final err = map?['error']?.toString() ??
          e.message ??
          'Código incorrecto o expirado.';
      return VerifyOtpOutcome.failure(err);
    }
  }

  /// `POST /api/auth/resend-otp` — devuelve `null` si OK, o mensaje de error.
  Future<String?> resendOtp(String email) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: <String, dynamic>{'email': email.trim()},
      );
      return null;
    } on DioException catch (e) {
      final map = parseResponseMap(e.response?.data);
      final code = map?['code'] as String?;
      final err = map?['error']?.toString() ??
          e.message ??
          'No se pudo reenviar el código.';
      if (e.response?.statusCode == 429 && code == 'EMAIL_RATE_LIMIT') {
        return err;
      }
      return err;
    }
  }
}

class HealthCheckResult {
  const HealthCheckResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
