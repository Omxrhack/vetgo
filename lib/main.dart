import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'onboarding/onboarding_prefs.dart';
import 'onboarding/vetgo_onboarding_page.dart';
import 'theme/vetgo_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: VetgoTheme.light(),
      darkTheme: VetgoTheme.dark(),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

enum _AppStage { splash, onboarding, home }

class _SplashGateState extends State<SplashGate> {
  static const Duration _minSplashTime = Duration(seconds: 3);
  static const Duration _extraSplashTime = Duration(seconds: 1);

  _AppStage _stage = _AppStage.splash;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _prepareApp() async {
    final startedAt = DateTime.now();

    // Simula carga inicial de recursos/pantallas.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashTime) {
      await Future<void>.delayed(_minSplashTime - elapsed);
    }

    // Tiempo extra para alcanzar a ver la animacion.
    await Future<void>.delayed(_extraSplashTime);
  }

  Future<void> _bootstrap() async {
    await _prepareApp();
    if (!mounted) return;
    final onboardingDone = await OnboardingPrefs.isComplete();
    if (!mounted) return;
    setState(() {
      _stage = onboardingDone ? _AppStage.home : _AppStage.onboarding;
    });
  }

  Future<void> _finishOnboarding() async {
    await OnboardingPrefs.markComplete();
    if (!mounted) return;
    setState(() => _stage = _AppStage.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _AppStage.splash:
        return const SplashScreen();
      case _AppStage.onboarding:
        return VetgoOnboardingPage(onFinished: _finishOnboarding);
      case _AppStage.home:
        return const HomeScreen();
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ColoredBox(
        color: scheme.surface,
        child: Center(
          child: SizedBox(
            width: 230,
            height: 230,
            child: Lottie.asset(
              'assets/lottie/davsan.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Text(
          'Vetgo listo',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
