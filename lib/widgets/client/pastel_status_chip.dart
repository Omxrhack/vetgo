import 'package:flutter/material.dart';

/// Chip pastel para estado de salud / etiquetas en expediente.
class PastelStatusChip extends StatelessWidget {
  const PastelStatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.icon,
    this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final IconData? icon;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foregroundColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
