import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/vetgo_theme.dart';

/// Variante visual (emojis de acento).
enum AuthScenicVariant {
  login,
  register,
  otp,
  home,
}

class _Spot {
  const _Spot({
    required this.dx,
    required this.dy,
    required this.size,
  });

  final double dx;
  final double dy;
  final double size;
}

/// Fondo decorativo para pantallas de auth: gradiente suave, formas orgánicas y emojis discretos.
class AuthScenicLayer extends StatelessWidget {
  const AuthScenicLayer({
    super.key,
    this.variant = AuthScenicVariant.login,
  });

  final AuthScenicVariant variant;

  static List<String> _emojiPalette(AuthScenicVariant v) {
    return switch (v) {
      AuthScenicVariant.login => ['🐾', '🐕', '🐈', '💚'],
      AuthScenicVariant.register => ['✨', '🐾', '📝', '🎉'],
      AuthScenicVariant.otp => ['📬', '✉️', '🔐', '🐾'],
      AuthScenicVariant.home => ['🏠', '🐾', '💚', '✨'],
    };
  }

  static const List<_Spot> _spots = [
    _Spot(dx: 0.06, dy: 0.10, size: 34),
    _Spot(dx: 0.72, dy: 0.16, size: 40),
    _Spot(dx: 0.08, dy: 0.42, size: 30),
    _Spot(dx: 0.78, dy: 0.52, size: 36),
    _Spot(dx: 0.12, dy: 0.68, size: 32),
    _Spot(dx: 0.70, dy: 0.82, size: 38),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final gradientColors = isDark
        ? const [
            Color(0xFF0A1610),
            Color(0xFF121E18),
            Color(0xFF0D140F),
          ]
        : const [
            Color(0xFFEFF8F2),
            Color(0xFFF5FBF7),
            Color(0xFFE8F4ED),
          ];

    final emojis = _emojiPalette(variant);
    final count = math.min(emojis.length, _spots.length);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -30,
                child: _SoftBlob(
                  color: primary.withValues(alpha: isDark ? 0.12 : 0.18),
                  size: 180,
                ),
              ),
              Positioned(
                bottom: 80,
                left: -50,
                child: _SoftBlob(
                  color: VetgoColors.lightGreen.withValues(alpha: isDark ? 0.08 : 0.12),
                  size: 220,
                ),
              ),
              Positioned(
                top: h * 0.18,
                left: -20,
                child: _SoftBlob(
                  color: primary.withValues(alpha: 0.06),
                  size: 100,
                ),
              ),
              ...List<Widget>.generate(count, (i) {
                final spot = _spots[i];
                final emojiOpacity = isDark ? 0.15 : 0.20;
                Widget child = Text(
                  emojis[i],
                  style: TextStyle(fontSize: spot.size, height: 1),
                );
                child = child
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(
                      begin: 0,
                      end: -6 - (i % 3) * 2.0,
                      duration: (2400 + i * 180).ms,
                      curve: Curves.easeInOut,
                    );
                return Positioned(
                  left: w * spot.dx,
                  top: h * spot.dy,
                  child: Opacity(opacity: emojiOpacity, child: child),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 4.seconds,
          curve: Curves.easeInOut,
        );
  }
}
