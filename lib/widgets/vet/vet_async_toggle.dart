import 'package:flutter/material.dart';

import 'vet_app_colors.dart';
import 'vet_soft_card.dart';

/// Toggle grande de disponibilidad con estado de carga animado.
class VetDutyToggleCard extends StatelessWidget {
  const VetDutyToggleCard({
    super.key,
    required this.available,
    required this.busy,
    required this.onChanged,
    this.offTitle = 'Fuera de turno',
    this.onTitle = 'Disponible para urgencias',
    this.offSubtitle = 'No recibirás alertas de emergencia.',
    this.onSubtitle = 'Podrás recibir asignaciones urgentes.',
  });

  final bool available;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final String offTitle;
  final String onTitle;
  final String offSubtitle;
  final String onSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = available ? VetAppColors.mintSoft.withValues(alpha: 0.55) : VetAppColors.peach.withValues(alpha: 0.45);

    return VetSoftCard(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: Row(
          key: ValueKey<bool>(available),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    available ? onTitle : offTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    available ? onSubtitle : offSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: VetAppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: busy
                  ? const SizedBox(
                      key: ValueKey<String>('busy'),
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    )
                  : Transform.scale(
                      key: const ValueKey<String>('switch'),
                      scale: 1.15,
                      child: Switch.adaptive(
                        value: available,
                        activeThumbColor: VetAppColors.mintDeep,
                        activeTrackColor: VetAppColors.mintSoft,
                        onChanged: busy ? null : onChanged,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón primario con sustitución por indicador de carga.
class VetAsyncPrimaryButton extends StatelessWidget {
  const VetAsyncPrimaryButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? VetAppColors.mintDeep;
    final fg = foregroundColor ?? Colors.white;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: busy
          ? SizedBox(
              key: const ValueKey<String>('loading'),
              height: 52,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: fg,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey<String>('idle'),
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  elevation: 0,
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
    );
  }
}
