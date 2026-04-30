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
}

class HealthCheckResult {
  const HealthCheckResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
