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
    final bg = selected ? (selectedColor ?? scheme.primaryContainer) : scheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: scheme.outline.withValues(alpha: selected ? 0.35 : 0.18)),
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
