import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración leída desde [assets/config/environment.env] y overrides en compilación.
abstract final class AppConfig {
  /// Prioridad: `--dart-define=API_BASE_URL=` > archivo `.env`.
  /// Sin barra final.
  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) {
      return _stripTrailingSlash(fromDefine.trim());
    }

    final fromFile = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (fromFile.isNotEmpty) {
      return _stripTrailingSlash(fromFile);
    }

    throw StateError(
      'API_BASE_URL no definida. Añádela en assets/config/environment.env '
      'o ejecuta con --dart-define=API_BASE_URL=https://tu-servidor',
    );
  }

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
