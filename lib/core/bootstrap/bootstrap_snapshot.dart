import '../auth/auth_storage.dart';
import '../../onboarding/onboarding_prefs.dart';

/// Lectura cacheada del estado persistido al arranque.
///
/// - **Onboarding**: [OnboardingPrefs] en disco (o memoria si falla el plugin).
/// - **Sesión**: [AuthStorage] (token de acceso).
///
/// Se usa durante el splash con [load] en paralelo para decidir:
/// onboarding → login ([AuthFlow]) → [HomeScreen].
class BootstrapSnapshot {
  const BootstrapSnapshot({
    required this.onboardingComplete,
    required this.isLoggedIn,
  });

  /// `true` si el usuario ya pasó el onboarding (no volver a mostrarlo).
  final bool onboardingComplete;

  /// `true` si hay sesión válida guardada.
  final bool isLoggedIn;

  /// Lee ambas prefs en paralelo (una sola ventana de espera).
  static Future<BootstrapSnapshot> load() async {
    final results = await Future.wait<Object>([
      OnboardingPrefs.isComplete(),
      AuthStorage.isLoggedIn(),
    ]);
    return BootstrapSnapshot(
      onboardingComplete: results[0] as bool,
      isLoggedIn: results[1] as bool,
    );
  }
}
