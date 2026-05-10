import 'package:flutter/material.dart';

/// Tarjeta con borde muy redondeado y sombra suave.
class VetSoftCard extends StatefulWidget {
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
  State<VetSoftCard> createState() => _VetSoftCardState();
}

class _VetSoftCardState extends State<VetSoftCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.color ?? scheme.surface;
    final shadowAlpha = _pressed ? 0.035 : 0.06;
    final shadowOffsetY = _pressed ? 4.0 : 10.0;

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: shadowAlpha),
            blurRadius: 22,
            offset: Offset(0, shadowOffsetY),
          ),
        ],
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    final scaled = AnimatedScale(
      scale: _pressed ? 0.988 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: decorated,
    );

    if (widget.onTap == null) return scaled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: VetSoftCard.radius,
        onHighlightChanged: (active) {
          if (_pressed == active) return;
          setState(() => _pressed = active);
        },
        child: scaled,
      ),
    );
  }
}
