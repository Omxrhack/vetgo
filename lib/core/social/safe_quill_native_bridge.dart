// ignore_for_file: experimental_member_use

import 'package:flutter/services.dart';
import 'package:flutter_quill/internal.dart';

/// Evita que [QuillNativeBridge.isIOSSimulator] tumbe la app cuando el canal
/// Pigeon de `quill_native_bridge` no está disponible (p. ej. iOS Simulator /
/// hot restart). En ese caso se asume «no simulador» y Quill usa la ruta de
/// visibilidad de teclado estándar.
final class SafeQuillNativeBridge extends QuillNativeBridge {
  @override
  Future<bool> isIOSSimulator() async {
    try {
      return await super.isIOSSimulator();
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Registrar antes de [runApp].
void registerSafeQuillNativeBridge() {
  // El setter está marcado como visible-for-testing en flutter_quill; es el
  // mecanismo previsto para sustituir el bridge en apps que necesiten un fallback.
  // ignore: invalid_use_of_visible_for_testing_member
  QuillNativeProvider.instance = SafeQuillNativeBridge();
}
