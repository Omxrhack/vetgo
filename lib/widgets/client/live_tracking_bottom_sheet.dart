import 'package:flutter/material.dart';

import '../../theme/client_pastel.dart';
import 'client_soft_card.dart';

/// Panel inferior del rastreo (veterinario, ETA, acciones).
class LiveTrackingBottomSheet extends StatelessWidget {
  const LiveTrackingBottomSheet({
    super.key,
    required this.vetName,
    required this.etaLabel,
    this.vetPhotoUrl,
    this.onCall,
    this.onChat,
  });

  final String vetName;
  final String etaLabel;
  final String? vetPhotoUrl;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  static const double handleBarRadius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return ClientSoftCard(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: ClientPastelColors.mintSoft,
                backgroundImage:
                    vetPhotoUrl != null && vetPhotoUrl!.isNotEmpty ? NetworkImage(vetPhotoUrl!) : null,
                child: vetPhotoUrl == null || vetPhotoUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 38, color: ClientPastelColors.mintDeep)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vetName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18, color: ClientPastelColors.skyDeep),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            etaLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _CircleActionButton(
                  icon: Icons.call_rounded,
                  label: 'Llamar',
                  backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.65),
                  iconColor: ClientPastelColors.mintDeep,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CircleActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chatear',
                  backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.85),
                  iconColor: ClientPastelColors.skyDeep,
                  onTap: onChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
