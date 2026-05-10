import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../auth/auth_storage.dart';
import '../config/app_config.dart';
import 'auth_outcomes.dart';

typedef VetJsonResult = (Map<String, dynamic>? data, String? error);

/// Se invoca cuando el refresh falla y la sesión queda inválida.
/// El app_flow debe registrar este callback para forzar la pantalla de login.
typedef ForceLogoutCallback = void Function();

/// Cliente HTTP para el backend Vetgo.
///
/// Rutas bajo `/api` ([petixfy-backend/src/index.js]). El endpoint `/health` está fuera de `/api`.
class VetgoApiClient {
  VetgoApiClient() {
    _root = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
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
    _api.interceptors.add(_TokenRefreshInterceptor(_api));
  }

  /// Registrar un callback para cuando el refresh falle (sesión expirada sin recuperación).
  static ForceLogoutCallback? onForceLogout;

  late final Dio _root;
  late final Dio _api;

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

  /// `POST /api/auth/refresh`
  Future<AuthSession?> refreshSession({required String refreshToken}) async {
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
      );
      final data = r.data;
      if (data == null) return null;
      return AuthSession.fromJson(data);
    } on DioException {
      return null;
    }
  }

  /// `POST /api/auth/upload-photo` — multipart campo `photo`; actualiza `profiles.avatar_url`.
  Future<(Map<String, dynamic>? profile, String? error)> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/upload-photo',
        data: formData,
        options: opts,
      );
      final data = r.data;
      if (data == null) return (null, 'Respuesta vacía del servidor.');
      return (data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/auth/me`
  Future<AuthSession?> fetchMe({required String accessToken}) async {
    final (session, _) = await fetchMeWithAuthHint(accessToken: accessToken);
    return session;
  }

  /// Igual que [fetchMe], pero indica si el servidor rechazo la sesion (401/403/404).
  Future<(AuthSession? session, bool authRejected)> fetchMeWithAuthHint({required String accessToken}) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      final data = r.data;
      if (data == null) return (null, false);
      return (
        AuthSession(
          accessToken: accessToken,
          user: data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : null,
          profile: data['profile'] is Map<String, dynamic> ? data['profile'] as Map<String, dynamic> : null,
        ),
        false,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final rejected = code == 401 || code == 403 || code == 404;
      return (null, rejected);
    }
  }

  /// `POST /api/auth/onboarding` — cuerpo según schema del backend (client | vet).
  Future<AuthSession?> completeProfileOnboarding({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/auth/onboarding',
        data: body,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      final data = r.data;
      if (data == null) return null;
      return AuthSession(
        accessToken: accessToken,
        user: data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : null,
        profile: data['profile'] is Map<String, dynamic> ? data['profile'] as Map<String, dynamic> : null,
      );
    } on DioException {
      return null;
    }
  }

  /// `GET /api/pets/:ownerId` — solo el dueño autenticado puede listar sus mascotas.
  Future<(List<Map<String, dynamic>>? list, String? error)> listPetsByOwner({
    required String ownerId,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<dynamic>(
        '/pets/$ownerId',
        options: opts,
      );
      final data = r.data;
      if (data is! List<dynamic>) {
        return (null, 'Formato de respuesta inesperado.');
      }
      final out = <Map<String, dynamic>>[];
      for (final e in data) {
        if (e is Map<String, dynamic>) {
          out.add(e);
        } else if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
      return (out, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/products` — catálogo (no requiere token).
  Future<(Map<String, dynamic>? data, String? error)> listProducts({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
  }) async {
    try {
      final q = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      };
      final r = await _api.get<Map<String, dynamic>>(
        '/products',
        queryParameters: q,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/vets` — catalogo veterinarios (cliente autenticado).
  Future<(List<Map<String, dynamic>>? list, String? error)> listVetsCatalog() async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/vets',
        options: opts,
      );
      final raw = r.data?['vets'];
      if (raw is! List<dynamic>) {
        return (null, 'Formato de respuesta inesperado.');
      }
      final out = <Map<String, dynamic>>[];
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          out.add(e);
        } else if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        }
      }
      return (out, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/emergencies`
  Future<VetJsonResult> createEmergency({
    required String petId,
    required String symptoms,
    required double latitude,
    required double longitude,
    String? status,
    String? preferredVetId,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/emergencies',
        data: <String, dynamic>{
          'pet_id': petId,
          'symptoms': symptoms,
          'latitude': latitude,
          'longitude': longitude,
          if (status != null && status.isNotEmpty) 'status': status,
          if (preferredVetId != null && preferredVetId.isNotEmpty) 'preferred_vet_id': preferredVetId,
        },
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/appointments`
  Future<VetJsonResult> createAppointment({
    required String petId,
    required String scheduledAtIso,
    String? notes,
    String? vetId,
    double? visitLatitude,
    double? visitLongitude,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/appointments',
        data: <String, dynamic>{
          'pet_id': petId,
          'scheduled_at': scheduledAtIso,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (vetId != null && vetId.isNotEmpty) 'vet_id': vetId,
          if (visitLatitude != null && visitLongitude != null) ...<String, dynamic>{
            'visit_latitude': visitLatitude,
            'visit_longitude': visitLongitude,
          },
        },
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `PATCH /api/vet/appointments/:id/claim` — asignar al veterinario una cita del pool.
  Future<VetJsonResult> claimVetAppointment({required String appointmentId}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.patch<Map<String, dynamic>>(
        '/vet/appointments/$appointmentId/claim',
        data: <String, dynamic>{},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/vet/appointments` — nueva cita confirmada (mascota vinculada al vet).
  Future<VetJsonResult> createVetAppointment({
    required String petId,
    required String scheduledAtIso,
    String? notes,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/vet/appointments',
        data: <String, dynamic>{
          'pet_id': petId,
          'scheduled_at': scheduledAtIso,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/appointments` — citas del dueño autenticado (incluye veterinario asignado si existe).
  Future<VetJsonResult> listMyAppointments() async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/appointments',
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/appointments/my-vet` — veterinario principal del cliente autenticado.
  Future<VetJsonResult> getMyVet() async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/appointments/my-vet',
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/tracking/:id`
  Future<VetJsonResult> getTrackingSession({required String sessionId}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/tracking/$sessionId',
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `PATCH /api/tracking/:id/location` — veterinario actualiza posición en vivo.
  Future<VetJsonResult> patchTrackingSessionLocation({
    required String sessionId,
    required double vetLat,
    required double vetLng,
    int? etaMinutes,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.patch<Map<String, dynamic>>(
        '/tracking/$sessionId/location',
        data: <String, dynamic>{
          'vet_lat': vetLat,
          'vet_lng': vetLng,
          'eta_minutes': ?etaMinutes,
        },
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  Future<Options?> _authorizedOptions() async {
    final token = await AuthStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    return Options(
      headers: <String, dynamic>{
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// `PATCH /api/vet/availability`
  Future<VetJsonResult> patchVetAvailability({required bool onDuty}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.patch<Map<String, dynamic>>(
        '/vet/availability',
        data: <String, dynamic>{'on_duty': onDuty},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/vet/dashboard`
  Future<VetJsonResult> getVetDashboard({String? date}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/vet/dashboard',
        queryParameters: date != null ? <String, dynamic>{'date': date} : null,
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/vet/schedule`
  Future<VetJsonResult> getVetSchedule({String? date}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/vet/schedule',
        queryParameters: date != null ? <String, dynamic>{'date': date} : null,
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/vet/pets/:id/summary`
  Future<VetJsonResult> getVetPetSummary({required String petId}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/vet/pets/$petId/summary',
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/vet/pets/:id/upload-photo` — veterinario con cita o emergencia asignada.
  Future<(Map<String, dynamic>? pet, String? error)> uploadPetPhotoAsVet({
    required String petId,
    required List<int> bytes,
    required String filename,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final r = await _api.post<Map<String, dynamic>>(
        '/vet/pets/$petId/upload-photo',
        data: formData,
        options: opts,
      );
      final data = r.data;
      if (data == null) return (null, 'Respuesta vacía del servidor.');
      return (data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/pets/:id/upload-photo` — dueño autenticado.
  Future<(Map<String, dynamic>? pet, String? error)> uploadPetPhotoAsOwner({
    required String petId,
    required List<int> bytes,
    required String filename,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final r = await _api.post<Map<String, dynamic>>(
        '/pets/$petId/upload-photo',
        data: formData,
        options: opts,
      );
      final data = r.data;
      if (data == null) return (null, 'Respuesta vacía del servidor.');
      return (data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/vet/emergencies/active`
  Future<VetJsonResult> getVetEmergenciesActive() async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/vet/emergencies/active',
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/vet/emergencies/:id/respond`
  Future<VetJsonResult> respondVetEmergency({
    required String emergencyId,
    required bool accept,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/vet/emergencies/$emergencyId/respond',
        data: <String, dynamic>{'accept': accept},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/tracking/sessions`
  Future<VetJsonResult> createTrackingSession({
    String? appointmentId,
    String? emergencyId,
    required double vetLat,
    required double vetLng,
    int? etaMinutes,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    final body = <String, dynamic>{
      'vet_lat': vetLat,
      'vet_lng': vetLng,
      'appointment_id': ?appointmentId,
      'emergency_id': ?emergencyId,
      'eta_minutes': ?etaMinutes,
    };
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/tracking/sessions',
        data: body,
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  static String _vetDioMessage(DioException e) {
    final map = parseResponseMap(e.response?.data);
    final err = map?['error']?.toString() ?? e.message ?? e.type.toString();
    return err;
  }

  /// `POST /api/auth/resend-otp`. Si [alreadyVerified] es true, el usuario debe ir a login.
  Future<({String? error, bool alreadyVerified})> resendOtp(String email) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: <String, dynamic>{'email': email.trim()},
      );
      return (error: null, alreadyVerified: false);
    } on DioException catch (e) {
      final map = parseResponseMap(e.response?.data);
      final code = map?['code'] as String?;
      final err = map?['error']?.toString() ??
          e.message ??
          'No se pudo reenviar el código.';
      final verified =
          e.response?.statusCode == 409 && code == 'EMAIL_ALREADY_VERIFIED';
      if (e.response?.statusCode == 429 && code == 'EMAIL_RATE_LIMIT') {
        return (error: err, alreadyVerified: false);
      }
      return (error: err, alreadyVerified: verified);
    }
  }

  // ─── Social ────────────────────────────────────────────────────────────────

  /// `GET /api/profiles/:id` — perfil público (auth opcional para is_following).
  Future<VetJsonResult> getPublicProfile(String profileId) async {
    final token = await AuthStorage.readAccessToken();
    final headers = <String, dynamic>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/profiles/$profileId',
        options: Options(headers: headers),
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `PATCH /api/profiles/me`
  Future<VetJsonResult> updateMyProfile({
    String? bio,
    String? location,
    int? yearsExperience,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    final body = <String, dynamic>{};
    if (bio != null) body['bio'] = bio;
    if (location != null) body['location'] = location;
    if (yearsExperience != null) body['years_experience'] = yearsExperience;
    try {
      final r = await _api.patch<Map<String, dynamic>>('/profiles/me', data: body, options: opts);
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/follows`
  Future<VetJsonResult> followUser(String followingId) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/follows',
        data: <String, dynamic>{'following_id': followingId},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `DELETE /api/follows/:id`
  Future<VetJsonResult> unfollowUser(String followingId) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.delete<Map<String, dynamic>>('/follows/$followingId', options: opts);
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/posts` — feed paginado.
  Future<VetJsonResult> getSocialFeed({int page = 1, int limit = 20}) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/posts',
        queryParameters: <String, dynamic>{'page': page, 'limit': limit},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/posts`
  Future<VetJsonResult> createPost({
    required String body,
    List<String> imageUrls = const [],
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    try {
      final r = await _api.post<Map<String, dynamic>>(
        '/posts',
        data: <String, dynamic>{'body': body, 'image_urls': imageUrls},
        options: opts,
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/profiles/:id/posts`
  Future<VetJsonResult> getUserPosts(String profileId, {int page = 1}) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/profiles/$profileId/posts',
        queryParameters: <String, dynamic>{'page': page},
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `POST /api/reviews`
  Future<VetJsonResult> createReview({
    required String revieweeId,
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    final opts = await _authorizedOptions();
    if (opts == null) return (null, 'Sesión no disponible.');
    final body = <String, dynamic>{
      'reviewee_id': revieweeId,
      'appointment_id': appointmentId,
      'rating': rating,
    };
    if (comment != null) body['comment'] = comment;
    try {
      final r = await _api.post<Map<String, dynamic>>('/reviews', data: body, options: opts);
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  /// `GET /api/profiles/:id/reviews`
  Future<VetJsonResult> getProfileReviews(String profileId, {int page = 1}) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/profiles/$profileId/reviews',
        queryParameters: <String, dynamic>{'page': page},
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  Future<VetJsonResult> getSuggestedProfiles({int limit = 10}) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/profiles/suggestions',
        queryParameters: <String, dynamic>{'limit': limit},
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }

  Future<VetJsonResult> getExplorePosts({int limit = 5}) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(
        '/posts/explore',
        queryParameters: <String, dynamic>{'limit': limit},
      );
      return (r.data, null);
    } on DioException catch (e) {
      return (null, _vetDioMessage(e));
    }
  }
}

class HealthCheckResult {
  const HealthCheckResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

/// Interceptor que refresca el access token automáticamente al recibir 401.
/// Usa un Dio auxiliar (sin este interceptor) para llamar a /auth/refresh
/// y evitar recursión infinita.
class _TokenRefreshInterceptor extends Interceptor {
  _TokenRefreshInterceptor(this._api);

  final Dio _api;
  bool _refreshing = false;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['_retried'] == true;

    if (status == 401 && !alreadyRetried && !_refreshing) {
      _refreshing = true;
      try {
        final refreshToken = await AuthStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _forceLogout();
          return handler.next(err);
        }

        // Llamada de refresh con Dio limpio para no entrar en el interceptor de nuevo.
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: _api.options.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              Headers.contentTypeHeader: Headers.jsonContentType,
            },
          ),
        );

        final r = await refreshDio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: <String, dynamic>{'refresh_token': refreshToken},
        );

        final data = r.data;
        if (data == null) {
          await _forceLogout();
          return handler.next(err);
        }

        final newSession = AuthSession.fromJson(data);
        if (!newSession.hasAccessToken) {
          await _forceLogout();
          return handler.next(err);
        }

        await AuthStorage.saveSession(newSession);

        // Reintentar la request original con el nuevo token.
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer ${newSession.accessToken}';
        opts.extra['_retried'] = true;

        final retryResp = await _api.fetch<dynamic>(opts);
        return handler.resolve(retryResp);
      } on DioException {
        await _forceLogout();
        return handler.next(err);
      } finally {
        _refreshing = false;
      }
    }

    return handler.next(err);
  }

  Future<void> _forceLogout() async {
    await AuthStorage.clear();
    VetgoApiClient.onForceLogout?.call();
  }
}
