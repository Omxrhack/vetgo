import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
        )
            .animate()
            .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.06, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}
