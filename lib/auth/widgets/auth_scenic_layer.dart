import 'package:flutter/material.dart';

/// Variante visual; controla densidad/forma del patron sutil.
enum AuthScenicVariant { login, register, otp, home }

/// Fondo plano con un patron de puntos muy sutil. Sin gradientes ni emojis.
class AuthQuietBackground extends StatelessWidget {
  const AuthQuietBackground({
    super.key,
    this.variant = AuthScenicVariant.login,
  });

  final AuthScenicVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DotGridPainter(
          color: scheme.outline.withValues(alpha: 0.07),
          spacing: _spacingFor(variant),
          radius: 1.0,
        ),
        size: Size.infinite,
      ),
    );
  }

  static double _spacingFor(AuthScenicVariant v) => switch (v) {
        AuthScenicVariant.login => 28,
        AuthScenicVariant.register => 28,
        AuthScenicVariant.otp => 32,
        AuthScenicVariant.home => 28,
      };
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({
    required this.color,
    required this.spacing,
    required this.radius,
  });

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}

/// Compatibilidad con codigo previo que aun importe `AuthScenicLayer`.
typedef AuthScenicLayer = AuthQuietBackground;
