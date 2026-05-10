// Presets de animación Heroine para Social: springs Material 3 / Cupertino y
// cross-fade por color de superficie (modo claro/oscuro).

import 'package:flutter/material.dart';
import 'package:heroine/heroine.dart';

/// Contenido del post (texto + imágenes): trayectoria espacial expresiva M3.
const Motion vetgoSocialHeroPostMotion =
    MaterialSpringMotion.expressiveSpatialDefault();

/// Avatares y fotos circulares: respuesta rápida con ligero rebote.
const Motion vetgoSocialHeroAvatarMotion = CupertinoMotion.snappy();

/// Iconos de barra (repost, etc.): mismo perfil que avatar, trayecto corto.
const Motion vetgoSocialHeroCompactMotion = CupertinoMotion.snappy();

/// Tarjeta citada en repost: espacial estándar (bloque rectangular).
const Motion vetgoSocialHeroQuotedCardMotion =
    MaterialSpringMotion.standardSpatialDefault();

/// Dissolve entre origen y destino pasando por el surface del tema.
HeroineShuttleBuilder vetgoSocialHeroFadeThrough(ColorScheme scheme) {
  return FadeThroughShuttleBuilder(
    fadeColor: scheme.surface,
    curve: Curves.easeOutCubic,
  );
}
