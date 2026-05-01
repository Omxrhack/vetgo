import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/widgets/client/live_tracking_bottom_sheet.dart';
import 'package:vetgo/widgets/client/simple_osm_map.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Default map center when route coords are not wired yet.
final LatLng _demoMapCenter = LatLng(19.4326, -99.1332);

/// Rastreo de cita activa (cliente): mapa OSM + panel inferior.
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
        title: const Text(AppStrings.trackingTitulo),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: 8,
            bottom: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalH = constraints.maxHeight;
                const attributionH = 22.0;
                final mapH = (totalH - attributionH).clamp(160.0, 800.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SimpleOsmMap(
                      center: _demoMapCenter,
                      height: mapH,
                      zoom: 13,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.mapaOsmAtribucion,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                );
              },
            ),
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
                VetgoNotice.show(context, message: AppStrings.trackingLlamadaDemo);
              },
              onChat: () {
                VetgoNotice.show(context, message: AppStrings.trackingChatDemo);
              },
            ),
          ),
        ],
      ),
    );
  }
}
