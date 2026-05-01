import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'auth_scenic_layer.dart';

/// Shell minimal flat: scaffold de superficie plana + patron sutil + safe area.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.variant,
    required this.child,
    this.topBar,
  });

  final AuthScenicVariant variant;
  final Widget child;

  /// Barra superior opcional (cuando una pantalla quiere algo encima del padding lateral).
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthQuietBackground(variant: variant),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?topBar,
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca minimal (icono pequeno + nombre uppercase + titulo grande + subtitulo).
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow = 'VETGO',
    this.icon = Icons.pets_rounded,
  });

  final String title;
  final String subtitle;
  final String eyebrow;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              eyebrow,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.1,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// Bloque "tarjeta" minimal: solo padding (sin chrome, sin sombra, sin borde).
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: child,
    );
  }
}

/// Decoracion plana para `TextFormField`: sin fill, borde fino, label siempre visible.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final scheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(14);

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    isDense: false,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: TextStyle(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(
      color: scheme.onSurface.withValues(alpha: 0.35),
    ),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.error, width: 2),
    ),
  );
}

/// Banner de error en superficie de error contenida (sin transparencia).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer, height: 1.35),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: scheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de seccion para formularios largos (eyebrow + titulo discreto).
class AuthSectionHeader extends StatelessWidget {
  const AuthSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
  });

  final String title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        if (eyebrow != null) const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta plana con borde fino que envuelve un hijo (ListTile, Switch, etc.).
class AuthOutlinedTile extends StatelessWidget {
  const AuthOutlinedTile({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }
}

/// Aplica entrada en cascada (fade + slideY) a una lista de hijos.
class AuthStagger extends StatelessWidget {
  const AuthStagger({
    super.key,
    required this.children,
    this.delayStep = const Duration(milliseconds: 60),
    this.fadeDuration = const Duration(milliseconds: 240),
    this.slideDuration = const Duration(milliseconds: 320),
  });

  final List<Widget> children;
  final Duration delayStep;
  final Duration fadeDuration;
  final Duration slideDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(children.length, (i) {
        final delay = delayStep * i;
        return children[i]
            .animate()
            .fadeIn(duration: fadeDuration, delay: delay, curve: Curves.easeOutCubic)
            .slideY(
              begin: 0.06,
              end: 0,
              duration: slideDuration,
              delay: delay,
              curve: Curves.easeOutCubic,
            );
      }),
    );
  }
}
