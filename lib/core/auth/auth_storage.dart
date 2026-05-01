import 'dart:convert';

import '../storage/vetgo_prefs.dart';
import 'auth_session.dart';

/// Persistencia de sesión (tokens + snapshot user/profile + caducidad access).
abstract final class AuthStorage {
  static const _keyAccess = 'vetgo_access_token';
  static const _keyRefresh = 'vetgo_refresh_token';
  static const _keyExpiresIn = 'vetgo_expires_in';
  static const _keyTokenType = 'vetgo_token_type';
  static const _keyUserJson = 'vetgo_user_json';
  static const _keyProfileJson = 'vetgo_profile_json';
  static const _keyAccessExpiresAtMs = 'vetgo_access_expires_at_ms';

  static const int _expirySkewMs = 60 * 1000;

  static Future<bool> isLoggedIn() async {
    final p = await VetgoPrefs.backend;
    final t = p.getString(_keyAccess);
    return t != null && t.isNotEmpty;
  }

  static Future<String?> readAccessToken() async {
    final p = await VetgoPrefs.backend;
    return p.getString(_keyAccess);
  }

  static Future<String?> readRefreshToken() async {
    final p = await VetgoPrefs.backend;
    return p.getString(_keyRefresh);
  }

  /// `true` si no hay marca de expiración o el access ya venció (con margen).
  static Future<bool> isAccessExpired() async {
    final p = await VetgoPrefs.backend;
    final exp = p.getInt(_keyAccessExpiresAtMs);
    if (exp == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= exp;
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
      final expiresAt = DateTime.now().millisecondsSinceEpoch +
          session.expiresIn! * 1000 -
          _expirySkewMs;
      await p.setInt(_keyAccessExpiresAtMs, expiresAt);
    } else {
      await p.remove(_keyExpiresIn);
      await p.remove(_keyAccessExpiresAtMs);
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
    if (session.profile != null) {
      await p.setString(_keyProfileJson, jsonEncode(session.profile));
    } else {
      await p.remove(_keyProfileJson);
    }
  }

  /// Reconstruye [AuthSession] desde prefs (sin comprobar validez del JWT).
  static Future<AuthSession?> loadSession() async {
    final p = await VetgoPrefs.backend;
    final access = p.getString(_keyAccess);
    final refresh = p.getString(_keyRefresh);
    if ((access == null || access.isEmpty) && (refresh == null || refresh.isEmpty)) {
      return null;
    }

    Map<String, dynamic>? user;
    final rawUser = p.getString(_keyUserJson);
    if (rawUser != null) {
      try {
        user = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {}
    }

    Map<String, dynamic>? profile;
    final rawProfile = p.getString(_keyProfileJson);
    if (rawProfile != null) {
      try {
        profile = jsonDecode(rawProfile) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: p.getInt(_keyExpiresIn),
      tokenType: p.getString(_keyTokenType),
      user: user,
      profile: profile,
    );
  }

  static Future<void> clear() async {
    final p = await VetgoPrefs.backend;
    await p.remove(_keyAccess);
    await p.remove(_keyRefresh);
    await p.remove(_keyExpiresIn);
    await p.remove(_keyTokenType);
    await p.remove(_keyUserJson);
    await p.remove(_keyProfileJson);
    await p.remove(_keyAccessExpiresAtMs);
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
