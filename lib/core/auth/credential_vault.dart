import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Par correo + contraseña guardados de forma **opcional** (login con “recordarme”).
class CredentialPair {
  const CredentialPair({required this.email, required this.password});

  final String email;
  final String password;
}

/// Almacenamiento **cifrado** del dispositivo (Keychain / EncryptedSharedPreferences).
/// No sustituye tokens: solo sirve para reintento de login o login silencioso.
abstract final class CredentialVault {
  static const _kEmail = 'vetgo_credential_email_v1';
  static const _kPassword = 'vetgo_credential_password_v1';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<CredentialPair?> read() async {
    try {
      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      if (email == null ||
          email.trim().isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }
      return CredentialPair(email: email.trim(), password: password);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _kEmail, value: email.trim());
      await _storage.write(key: _kPassword, value: password);
    } catch (_) {
      // Fallo de plugin / permisos: no bloquear login manual.
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    } catch (_) {
      // ignore
    }
  }

  static Future<bool> hasCredentials() async {
    final c = await read();
    return c != null;
  }
}
