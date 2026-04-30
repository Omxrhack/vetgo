import 'package:flutter/material.dart';

import '../auth/auth_flow.dart';
import '../core/auth/auth_storage.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_prefs.dart';
import '../onboarding/vetgo_onboarding_page.dart';
import '../splash/splash_screen.dart';

/// Orquesta las etapas iniciales con transición animada entre pantallas.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

enum _AppStage { splash, onboarding, auth, home }

class _AppFlowState extends State<AppFlow> {
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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashTime) {
      await Future<void>.delayed(_minSplashTime - elapsed);
    }
    await Future<void>.delayed(_extraSplashTime);
  }

  Future<void> _bootstrap() async {
    await _prepareApp();
    if (!mounted) return;
    final onboardingDone = await OnboardingPrefs.isComplete();
    final loggedIn = await AuthStorage.isLoggedIn();
    if (!mounted) return;
    setState(() {
      if (!onboardingDone) {
        _stage = _AppStage.onboarding;
      } else if (!loggedIn) {
        _stage = _AppStage.auth;
      } else {
        _stage = _AppStage.home;
      }
    });
  }

  void _onAuthenticated() {
    setState(() => _stage = _AppStage.home);
  }

  void _onLoggedOut() {
    setState(() => _stage = _AppStage.auth);
  }

  Future<void> _finishOnboarding() async {
    await OnboardingPrefs.markComplete();
    if (!mounted) return;
    final loggedIn = await AuthStorage.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _stage = loggedIn ? _AppStage.home : _AppStage.auth;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _stageChild(),
    );
  }

  Widget _stageChild() {
    switch (_stage) {
      case _AppStage.splash:
        return const KeyedSubtree(
          key: ValueKey<String>('splash'),
          child: SplashScreen(),
        );
      case _AppStage.onboarding:
        return KeyedSubtree(
          key: const ValueKey<String>('onboarding'),
          child: VetgoOnboardingPage(onFinished: _finishOnboarding),
        );
      case _AppStage.auth:
        return KeyedSubtree(
          key: const ValueKey<String>('auth'),
          child: AuthFlow(onAuthenticated: _onAuthenticated),
        );
      case _AppStage.home:
        return KeyedSubtree(
          key: const ValueKey<String>('home'),
          child: HomeScreen(onLoggedOut: _onLoggedOut),
        );
    }
  }
}
