import '../network/auth_outcomes.dart' show LoginKind;
import '../network/vetgo_api_client.dart';
import 'auth_storage.dart';
import 'credential_vault.dart';

enum SilentAuthKind {
  /// Sesión guardada correctamente.
  success,

  /// No hay credenciales en el vault.
  noCredentials,

  /// Correo sin verificar: ir a OTP con [otpEmail].
  needsOtp,

  /// Error de red o credenciales inválidas ya limpiadas cuando aplica.
  failed,
}

/// Resultado de un intento de login silencioso contra `/api/auth/login`.
class SilentAuthResult {
  const SilentAuthResult(
    this.kind, {
    this.otpEmail,
    this.hint,
  });

  final SilentAuthKind kind;
  final String? otpEmail;
  final String? hint;
}

/// Login silencioso al arranque usando [CredentialVault] (tras marcar “recordarme”).
abstract final class SilentAuth {
  /// Llama al backend con correo/contraseña guardados.
  ///
  /// - **200 + token**: persiste [AuthStorage] y devuelve [SilentAuthKind.success].
  /// - **403 EMAIL_NOT_CONFIRMED**: devuelve [SilentAuthKind.needsOtp] (no borra el vault).
  /// - **401**: borra credenciales guardadas (contraseña ya no válida).
  /// - **429 / red**: no borra credenciales para permitir reintento manual.
  static Future<SilentAuthResult> attempt() async {
    final creds = await CredentialVault.read();
    if (creds == null) {
      return const SilentAuthResult(SilentAuthKind.noCredentials);
    }

    final outcome = await VetgoApiClient().login(
      email: creds.email,
      password: creds.password,
    );

    switch (outcome.kind) {
      case LoginKind.success:
        final session = outcome.session;
        if (session != null && session.hasAccessToken) {
          await AuthStorage.saveSession(session);
          return const SilentAuthResult(SilentAuthKind.success);
        }
        await CredentialVault.clear();
        return const SilentAuthResult(SilentAuthKind.failed);
      case LoginKind.needsVerification:
        final email = outcome.emailForVerification?.trim().isNotEmpty == true
            ? outcome.emailForVerification!.trim()
            : creds.email;
        return SilentAuthResult(
          SilentAuthKind.needsOtp,
          otpEmail: email,
          hint: outcome.message,
        );
      case LoginKind.failure:
        final status = outcome.statusCode;
        if (status == 401) {
          await CredentialVault.clear();
        }
        return SilentAuthResult(
          SilentAuthKind.failed,
          hint: outcome.message,
        );
    }
  }
}
