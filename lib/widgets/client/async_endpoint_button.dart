import 'package:flutter/material.dart';

/// Botón que anima a estado de carga mientras [onPressed] (async) está en curso.
class AsyncEndpointButton extends StatefulWidget {
  const AsyncEndpointButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style,
    this.loadingLabel,
    this.height = 52,
    this.borderRadius = 22,
  });

  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final ButtonStyle? style;
  final String? loadingLabel;
  final double height;
  final double borderRadius;

  @override
  State<AsyncEndpointButton> createState() => _AsyncEndpointButtonState();
}

class _AsyncEndpointButtonState extends State<AsyncEndpointButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
      child: _busy
          ? SizedBox(
              key: const ValueKey<String>('loading'),
              height: widget.height,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: scheme.onPrimary,
                      ),
                    ),
                    if (widget.loadingLabel != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.loadingLabel!,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey<String>('idle'),
              height: widget.height,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onPressed == null ? null : _handleTap,
                icon: widget.icon != null ? Icon(widget.icon, size: 22) : const SizedBox.shrink(),
                label: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                style: widget.style ??
                    FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                      ),
                      elevation: 0,
                    ),
              ),
            ),
    );
  }
}
