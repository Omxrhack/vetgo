import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingPrefs {
  static const String _key = 'vetgo_onboarding_complete';

  /// Tras añadir plugins nuevos hace falta **detener la app** y volver a ejecutarla
  /// (hot reload no registra el canal nativo). Si el canal no existe aún, no crasheamos.
  static Future<bool> isComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> markComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } on MissingPluginException {
      // Sin plugin nativo (ej. solo hot reload): ignorar hasta el próximo run completo.
    }
  }
}
