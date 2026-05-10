import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:heroine/heroine.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vetgo/app_flow.dart';
import 'package:vetgo/core/social/safe_quill_native_bridge.dart';
import 'package:vetgo/core/supabase/vetgo_supabase.dart';
import 'package:vetgo/theme/vetgo_theme.dart';

/// [flutter_cache_manager] (p. ej. vía [cached_network_image]) usa sqflite; en desktop
/// hay que usar FFI antes de cualquier acceso a la API global de sqflite.
void _configureSqliteForDesktopCache() {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    default:
      break;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureSqliteForDesktopCache();
  registerSafeQuillNativeBridge();
  await dotenv.load(fileName: '.env');
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
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      navigatorObservers: [HeroineController()],
      home: const AppFlow(),
    );
  }
}
