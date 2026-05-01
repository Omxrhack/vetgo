import 'package:flutter/material.dart';

import 'vet_operator_colors.dart';

/// Paleta pastel cliente: menta, ámbar/naranja suave, azul cielo (alineada con Vetgo existente).
abstract final class ClientPastelColors {
  /// Azul cielo suave (tarjetas / acentos fríos).
  static const Color skySoft = Color(0xFFB8E4F5);
  static const Color skyMuted = Color(0xFF8FCAE8);
  static const Color skyDeep = Color(0xFF5BA3D4);

  /// Mentón confirmación (reutiliza mint existente).
  static Color get mintSoft => VetOperatorColors.mintSoft;
  static Color get mintDeep => VetOperatorColors.mintDeep;

  /// Ámbar / durazno cálido.
  static Color get amberSoft => VetOperatorColors.amberSoft;
  static Color get peachSoft => VetOperatorColors.peach;

  /// Coral suave (alertas sin estridencia).
  static Color get coralSoft => VetOperatorColors.coralSoft;

  static Color mutedOn(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58);
}
