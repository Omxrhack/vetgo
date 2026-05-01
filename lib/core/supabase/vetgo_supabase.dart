import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vetgo/core/config/app_config.dart';

/// Inicializa el cliente Supabase si hay URL y anon key ([AppConfig]).
abstract final class VetgoSupabase {
  static bool _initialized = false;

  static bool get isConfigured =>
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initializeIfConfigured() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  /// Restaura la sesion JWT en el cliente Supabase (Realtime respeta RLS).
  /// Requiere refresh token valido (GotrueClient.setSession).
  static Future<void> syncSession({
    required String? refreshToken,
    required String? accessToken,
  }) async {
    if (!_initialized) return;
    final rt = refreshToken?.trim() ?? '';
    final at = accessToken?.trim();
    if (rt.isEmpty) {
      await signOut();
      return;
    }
    try {
      await Supabase.instance.client.auth.setSession(
        rt,
        accessToken: at != null && at.isNotEmpty ? at : null,
      );
    } catch (_) {
      // Fall back to HTTP polling in VetShell.
    }
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  static SupabaseClient get client => Supabase.instance.client;
}
