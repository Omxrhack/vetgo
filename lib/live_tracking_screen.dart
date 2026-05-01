import 'package:flutter/material.dart';

import 'package:vetgo/widgets/client/live_tracking_bottom_sheet.dart';
import 'package:vetgo/widgets/client/map_placeholder_box.dart';

/// Rastreo de cita activa (cliente): mapa placeholder + panel inferior.
class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({
    super.key,
    required this.vetName,
    required this.etaLabel,
    this.vetPhotoUrl,
  });

  final String vetName;
  final String etaLabel;
  final String? vetPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tu visita en camino'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
            child: MapPlaceholderBox(),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: LiveTrackingBottomSheet(
              vetName: vetName,
              etaLabel: etaLabel,
              vetPhotoUrl: vetPhotoUrl,
              onCall: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Iniciando llamadaù'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              onChat: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Abriendo chatù'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
