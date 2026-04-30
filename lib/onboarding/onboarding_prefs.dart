import '../core/storage/vetgo_prefs.dart';

abstract final class OnboardingPrefs {
  static const String _key = 'vetgo_onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await VetgoPrefs.backend;
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await VetgoPrefs.backend;
    await prefs.setBool(_key, true);
  }
}
