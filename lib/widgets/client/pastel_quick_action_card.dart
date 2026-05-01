import 'package:flutter/material.dart';

import 'client_soft_card.dart';

/// Tarjeta de acceso rápido del dashboard (ícono grande + etiqueta).
class PastelQuickActionCard extends StatelessWidget {
  const PastelQuickActionCard({
    super.key,
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

    return ClientSoftCard(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
