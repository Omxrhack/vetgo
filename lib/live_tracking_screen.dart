import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/widgets/client/live_tracking_bottom_sheet.dart';
import 'package:vetgo/widgets/client/simple_osm_map.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Default map center when route coords are not wired yet.
final LatLng _demoMapCenter = LatLng(19.4326, -99.1332);

/// Rastreo de cita activa (cliente): mapa OSM + panel inferior.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.vetName,
    required this.etaLabel,
    this.trackingSessionId,
    this.vetPhotoUrl,
  });

  final String vetName;
  final String etaLabel;
  final String? trackingSessionId;
  final String? vetPhotoUrl;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _api = VetgoApiClient();
  LatLng? _vetPoint;
  String? _etaOverride;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    final id = widget.trackingSessionId;
    if (id == null || id.isEmpty) return;
    final (data, err) = await _api.getTrackingSession(sessionId: id);
    if (!mounted || err != null || data == null) return;
    final lat = _readDouble(data['vet_lat']);
    final lng = _readDouble(data['vet_lng']);
    final etaRaw = data['eta_minutes'];
    final eta = etaRaw is num
        ? etaRaw.round()
        : int.tryParse(etaRaw?.toString() ?? '');
    setState(() {
      if (lat != null && lng != null) _vetPoint = LatLng(lat, lng);
      if (eta != null) _etaOverride = '$eta min';
    });
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapCenter = _vetPoint ?? _demoMapCenter;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text(AppStrings.trackingTitulo)),
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
                    SimpleOsmMap(center: mapCenter, height: mapH, zoom: 13),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.mapaOsmAtribucion,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
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
              vetName: widget.vetName,
              etaLabel: _etaOverride ?? widget.etaLabel,
              vetPhotoUrl: widget.vetPhotoUrl,
              onCall: () {
                VetgoNotice.show(
                  context,
                  message: AppStrings.trackingLlamadaDemo,
                );
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
