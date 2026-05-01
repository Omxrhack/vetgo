import 'package:flutter/material.dart';

import 'vet_app_colors.dart';

/// Tarjeta con borde muy redondeado y sombra suave.
class VetSoftCard extends StatelessWidget {
  const VetSoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.white;

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: VetAppColors.lilacHint.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: VetAppColors.mintDeep.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: decorated),
    );
  }
}
