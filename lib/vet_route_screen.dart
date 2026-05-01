import 'package:flutter/material.dart';

import 'widgets/vet/vet_soft_card.dart';

/// Pantalla temporal hasta integrar mapa en vivo (Google Maps u otro SDK).
class VetRouteScreen extends StatelessWidget {
  const VetRouteScreen({
    super.key,
    required this.trackingSessionId,
    this.title = 'Ruta en curso',
  });

  final String trackingSessionId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.58);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: VetSoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mapa en construcción',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sesión de seguimiento creada. El mapa en vivo y actualización de ubicación llegarán en una siguiente iteración.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  trackingSessionId,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
