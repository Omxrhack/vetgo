import 'package:flutter/material.dart';

import '../bootstrap/app_flow.dart';
import '../theme/vetgo_theme.dart';

/// Raíz de la app: temas (Poppins) y flujo splash → onboarding → inicio.
class VetgoApp extends StatelessWidget {
  const VetgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: VetgoTheme.light(),
      darkTheme: VetgoTheme.dark(),
      home: const AppFlow(),
    );
  }
}
