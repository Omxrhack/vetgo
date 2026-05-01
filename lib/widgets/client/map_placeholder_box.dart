import 'package:flutter/material.dart';

import 'package:vetgo/theme/client_pastel.dart';

/// Placeholder de mapa hasta integrar SDK de mapas.
class MapPlaceholderBox extends StatelessWidget {
  const MapPlaceholderBox({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_rounded, size: 56, color: ClientPastelColors.skyDeep.withValues(alpha: 0.55)),
          const SizedBox(height: 12),
          Text(
            'Mapa en vivo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClientPastelColors.mutedOn(context),
                ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Aquí verás la ruta del veterinario',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ClientPastelColors.mutedOn(context)),
            ),
          ),
        ],
      ),
    );
  }
}
