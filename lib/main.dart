import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:vetgo/app_flow.dart';
import 'package:vetgo/core/supabase/vetgo_supabase.dart';
import 'package:vetgo/theme/vetgo_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/environment.env');
  await VetgoSupabase.initializeIfConfigured();
  await initializeDateFormatting('es');
  runApp(const VetgoApp());
}

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
