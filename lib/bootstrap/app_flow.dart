import 'package:flutter/material.dart';

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

enum _AppStage { splash, onboarding, home }

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
      case _AppStage.home:
        return const KeyedSubtree(
          key: ValueKey<String>('home'),
          child: HomeScreen(),
        );
    }
  }
}
