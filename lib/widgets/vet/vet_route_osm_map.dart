import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:vetgo/theme/vet_operator_colors.dart';

/// Mapa OSM para ruta veterinario: posición actual + destino (emergencia/cita) y línea entre ambos.
class VetRouteOsmMap extends StatefulWidget {
  const VetRouteOsmMap({
    super.key,
    required this.vetPoint,
    this.destinationPoint,
    required this.height,
    this.vetColor,
    this.destinationColor,
  });

  final LatLng vetPoint;
  final LatLng? destinationPoint;
  final double height;
  final Color? vetColor;
  final Color? destinationColor;

  @override
  State<VetRouteOsmMap> createState() => _VetRouteOsmMapState();
}

class _VetRouteOsmMapState extends State<VetRouteOsmMap> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  @override
  void didUpdateWidget(covariant VetRouteOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameLatLng(oldWidget.vetPoint, widget.vetPoint) ||
        !_sameOptionalLatLng(oldWidget.destinationPoint, widget.destinationPoint)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  bool _sameLatLng(LatLng a, LatLng b) =>
      a.latitude == b.latitude && a.longitude == b.longitude;

  bool _sameOptionalLatLng(LatLng? a, LatLng? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return _sameLatLng(a, b);
  }

  void _fitCamera() {
    if (!mounted) return;
    final vet = widget.vetPoint;
    final dest = widget.destinationPoint;
    if (dest == null) {
      _controller.move(vet, 15);
      return;
    }
    try {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(<LatLng>[vet, dest]),
          padding: const EdgeInsets.fromLTRB(44, 44, 44, 72),
        ),
      );
    } catch (_) {
      _controller.move(vet, 13);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vetPin = widget.vetColor ?? VetOperatorColors.mintDeep;
    final destPin = widget.destinationColor ?? scheme.error.withValues(alpha: 0.88);

    final dest = widget.destinationPoint;
    final markers = <Marker>[
      Marker(
        point: widget.vetPoint,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(Icons.navigation_rounded, color: vetPin, size: 38),
      ),
    ];
    if (dest != null) {
      markers.add(
        Marker(
          point: dest,
          width: 42,
          height: 48,
          alignment: Alignment.bottomCenter,
          child: Icon(Icons.flag_rounded, color: destPin, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.vetPoint,
            initialZoom: dest == null ? 15 : 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.flingAnimation,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vetgo',
              maxNativeZoom: 19,
            ),
            if (dest != null)
              PolylineLayer(
                polylines: <Polyline>[
                  Polyline(
                    points: <LatLng>[widget.vetPoint, dest],
                    color: VetOperatorColors.mintDeep.withValues(alpha: 0.65),
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
