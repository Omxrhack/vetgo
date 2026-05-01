import 'package:flutter/material.dart';

import '../../theme/vet_operator_colors.dart';
import 'vet_async_toggle.dart';
import 'vet_soft_card.dart';

class VetEmergencyVm {
  VetEmergencyVm({
    required this.id,
    required this.symptoms,
    required this.status,
    required this.petName,
    required this.species,
    this.distanceKm,
  });

  final String id;
  final String symptoms;
  final String status;
  final String petName;
  final String species;
  final double? distanceKm;
}

/// Bottom sheet alta visibilidad para emergencia asignada.
Future<void> showVetEmergencyAlertSheet({
  required BuildContext context,
  required VetEmergencyVm emergency,
  required Future<void> Function() onAccept,
  required Future<void> Function() onReject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EmergencySheetBody(
      emergency: emergency,
      onAccept: onAccept,
      onReject: onReject,
    ),
  );
}

class _EmergencySheetBody extends StatefulWidget {
  const _EmergencySheetBody({
    required this.emergency,
    required this.onAccept,
    required this.onReject,
  });

  final VetEmergencyVm emergency;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_EmergencySheetBody> createState() => _EmergencySheetBodyState();
}

class _EmergencySheetBodyState extends State<_EmergencySheetBody> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<Offset> _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
  );

  bool _acceptBusy = false;
  bool _rejectBusy = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final em = widget.emergency;
    final dist = em.distanceKm != null ? 'A ${em.distanceKm} km' : 'Distancia por confirmar';

    final summary = '¡Emergencia! ${em.species} (${em.petName}) · ${em.symptoms} · $dist';

    return SlideTransition(
      position: _slide,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: VetSoftCard(
          color: Color.alphaBlend(
            VetOperatorColors.coralSoft.withValues(alpha: 0.35),
            scheme.surface,
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.emergency_rounded, color: scheme.error, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Asignación 24/7',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_actionError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _actionError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              VetAsyncPrimaryButton(
                label: 'Aceptar',
                busy: _acceptBusy,
                onPressed: _acceptBusy || _rejectBusy
                    ? null
                    : () async {
                        setState(() {
                          _acceptBusy = true;
                          _actionError = null;
                        });
                        try {
                          await widget.onAccept();
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (mounted) setState(() => _actionError = e.toString());
                        } finally {
                          if (mounted) setState(() => _acceptBusy = false);
                        }
                      },
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _rejectBusy
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _acceptBusy
                            ? null
                            : () async {
                                setState(() {
                                  _rejectBusy = true;
                                  _actionError = null;
                                });
                                try {
                                  await widget.onReject();
                                  if (context.mounted) Navigator.of(context).pop();
                                } catch (e) {
                                  if (mounted) setState(() => _actionError = e.toString());
                                } finally {
                                  if (mounted) setState(() => _rejectBusy = false);
                                }
                              },
                        child: Text(
                          'Rechazar',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
