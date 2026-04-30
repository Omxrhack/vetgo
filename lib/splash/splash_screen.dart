import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

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
          )
              .animate()
              .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.92, 0.92),
                curve: Curves.easeOutBack,
                duration: 800.ms,
              ),
        ),
      ),
    );
  }
}
