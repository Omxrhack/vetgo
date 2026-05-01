import 'package:flutter/material.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/widgets/client/live_tracking_bottom_sheet.dart';
import 'package:vetgo/widgets/client/map_placeholder_box.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

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
        title: const Text(AppStrings.trackingTitulo),
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
