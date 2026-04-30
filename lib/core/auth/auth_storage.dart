import 'dart:convert';

import '../storage/vetgo_prefs.dart';
import 'auth_session.dart';

/// Persistencia mínima de sesión (tokens + snapshot de usuario).
abstract final class AuthStorage {
  static const _keyAccess = 'vetgo_access_token';
  static const _keyRefresh = 'vetgo_refresh_token';
  static const _keyExpiresIn = 'vetgo_expires_in';
  static const _keyTokenType = 'vetgo_token_type';
  static const _keyUserJson = 'vetgo_user_json';

  static Future<bool> isLoggedIn() async {
    final p = await VetgoPrefs.backend;
    final t = p.getString(_keyAccess);
    return t != null && t.isNotEmpty;
  }

  static Future<void> saveSession(AuthSession session) async {
    final p = await VetgoPrefs.backend;
    if (session.accessToken != null) {
      await p.setString(_keyAccess, session.accessToken!);
    } else {
      await p.remove(_keyAccess);
    }
    if (session.refreshToken != null) {
      await p.setString(_keyRefresh, session.refreshToken!);
    } else {
      await p.remove(_keyRefresh);
    }
    if (session.expiresIn != null) {
      await p.setInt(_keyExpiresIn, session.expiresIn!);
    } else {
      await p.remove(_keyExpiresIn);
    }
    if (session.tokenType != null) {
      await p.setString(_keyTokenType, session.tokenType!);
    } else {
      await p.remove(_keyTokenType);
    }
    if (session.user != null) {
      await p.setString(_keyUserJson, jsonEncode(session.user));
    } else {
      await p.remove(_keyUserJson);
    }
  }

  static Future<void> clear() async {
    final p = await VetgoPrefs.backend;
    await p.remove(_keyAccess);
    await p.remove(_keyRefresh);
    await p.remove(_keyExpiresIn);
    await p.remove(_keyTokenType);
    await p.remove(_keyUserJson);
  }

  /// Email guardado en el último user snapshot (puede ser null).
  static Future<String?> readEmail() async {
    final p = await VetgoPrefs.backend;
    final raw = p.getString(_keyUserJson);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['email'] as String?;
    } catch (_) {
      return null;
    }
  }
}
