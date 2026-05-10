import 'package:flutter/material.dart';

/// Categoría horizontal tipo píldora para la tienda.
class StoreCategoryPill extends StatelessWidget {
  const StoreCategoryPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? (selectedColor ?? scheme.primaryContainer.withValues(alpha: 0.72))
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final fg = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.42)
                    : scheme.outline.withValues(alpha: 0.18),
                width: selected ? 1.25 : 1,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
