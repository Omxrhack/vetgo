import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permisos solicitados durante el splash para reducir fallos en emergencias,
/// citas (mapa / ubicación) y selección de fotos (perfil, mascotas, onboarding).
abstract final class AppStartupPermissions {
  static Future<void> requestAll() async {
    if (kIsWeb) return;
    try {
      await _location();
      await _photos();
    } catch (_) {
      // No bloquear arranque ante errores de plugin o OEM raros.
    }
  }

  static Future<void> _location() async {
    final s = await Permission.locationWhenInUse.status;
    if (s.isGranted || s.isLimited) return;
    await Permission.locationWhenInUse.request();
  }

  static Future<void> _photos() async {
    final s = await Permission.photos.status;
    if (s.isGranted || s.isLimited) return;
    await Permission.photos.request();
  }
}
