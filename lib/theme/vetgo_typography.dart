import 'package:flutter/material.dart';

/// Poppins empaquetada en [pubspec.yaml] (sin `google_fonts` → sin `path_provider` en runtime).
abstract final class VetgoTypography {
  static const String family = 'Poppins';

  static TextTheme poppinsTextTheme(TextTheme base) {
    return base.apply(
      fontFamily: family,
    );
  }
}
