import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'theme/vetgo_theme.dart';

void main() {
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

class _SplashGateState extends State<SplashGate> {
  static const Duration _minSplashTime = Duration(seconds: 3);
  static const Duration _extraSplashTime = Duration(seconds: 1);

  late final Future<void> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _prepareApp();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }

        return const SplashScreen();
      },
    );
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
