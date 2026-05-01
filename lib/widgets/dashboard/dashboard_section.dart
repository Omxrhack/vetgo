import 'package:flutter/material.dart';

/// Encabezado de bloque + contenido (dashboard cliente / veterinario).
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.spacingBeforeChild = 12,
    this.bottomSpacing = 26,
    this.titleStyle,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double spacingBeforeChild;
  final double bottomSpacing;
  final TextStyle? titleStyle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = subtitleColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle ??
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                            height: 1.15,
                          ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: spacingBeforeChild),
          child,
        ],
      ),
    );
  }
}
