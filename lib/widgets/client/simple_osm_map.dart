import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa OpenStreetMap con marcador (sin API key de Google).
///
/// Atribución: datos © colaboradores de OpenStreetMap.
class SimpleOsmMap extends StatefulWidget {
  const SimpleOsmMap({
    super.key,
    required this.center,
    this.zoom = 15,
    required this.height,
    this.markerColor,
  });

  final LatLng center;
  final double zoom;
  final double height;
  final Color? markerColor;

  @override
  State<SimpleOsmMap> createState() => _SimpleOsmMapState();
}

class _SimpleOsmMapState extends State<SimpleOsmMap> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SimpleOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center.latitude != widget.center.latitude ||
        oldWidget.center.longitude != widget.center.longitude ||
        oldWidget.zoom != widget.zoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.move(widget.center, widget.zoom);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pinColor = widget.markerColor ?? scheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
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
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.center,
                  width: 42,
                  height: 42,
                  alignment: Alignment.bottomCenter,
                  child: Icon(Icons.location_pin, color: pinColor, size: 42),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
