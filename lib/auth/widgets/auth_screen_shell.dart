import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'auth_scenic_layer.dart';

/// Fondo con [AuthScenicLayer] y area segura para formularios de auth.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.variant,
    required this.child,
    this.topBar,
  });

  final AuthScenicVariant variant;
  final Widget child;

  /// Barra superior opcional (por ejemplo volver en registro).
  final Widget? topBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthScenicLayer(variant: variant),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (topBar != null) topBar!,
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta principal del formulario (vidrio ligero sobre el gradiente).
class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: scheme.surface.withValues(alpha: isDark ? 0.88 : 0.94),
      elevation: isDark ? 0 : 3,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0 : 0.12),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        child: child,
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, end: 0, duration: 380.ms, curve: Curves.easeOutCubic);
  }
}

/// Cabecera con marca: icono, titulo y subtitulo.
class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.pets_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer,
                scheme.primary.withValues(alpha: 0.22),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 36, color: scheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.72),
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final radius = BorderRadius.circular(18);

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.55 : 0.65),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
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

/// Banner de error reutilizable en login / registro.
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
      color: scheme.errorContainer.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
