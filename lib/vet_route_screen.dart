import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/widgets/vet/vet_route_osm_map.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Ruta en vivo: mapa OSM, destino (emergencia/cita), distancia/ETA y PATCH peri\u00F3dico de ubicaci\u00F3n.
class VetRouteScreen extends StatefulWidget {
  const VetRouteScreen({
    super.key,
    required this.trackingSessionId,
    this.title = 'Ruta en curso',
  });

  final String trackingSessionId;
  final String title;

  @override
  State<VetRouteScreen> createState() => _VetRouteScreenState();
}

class _VetRouteScreenState extends State<VetRouteScreen> {
  final VetgoApiClient _api = VetgoApiClient();

  Map<String, dynamic>? _session;
  String? _error;
  bool _loading = true;

  LatLng _vetPoint = const LatLng(19.4326, -99.1332);
  LatLng? _destPoint;

  double? _distanceKm;
  int? _serverEtaMin;
  bool _noDestinationCoords = false;

  bool _locationBusy = false;
  bool _permissionDenied = false;
  Timer? _tickTimer;
  DateTime _lastPatchAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _patchMinIntervalSeconds = 10;
  static const double _urbanSpeedKmh = 28;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadSession();
    if (!mounted || _error != null) return;
    unawaited(_ensureLocationPermission());
    _tickTimer = Timer.periodic(const Duration(seconds: 12), (_) => _pushLocationIfDue());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pushLocationIfDue(force: true));
  }

  Future<void> _loadSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await _api.getTrackingSession(sessionId: widget.trackingSessionId);
    if (!mounted) return;
    if (err != null || data == null) {
      setState(() {
        _loading = false;
        _error = err ?? AppStrings.vetRouteErrorCargaSesion;
      });
      return;
    }

    final vl = _readDouble(data['vet_lat']);
    final vg = _readDouble(data['vet_lng']);
    if (vl != null && vg != null) {
      _vetPoint = LatLng(vl, vg);
    }

    final destMap = data['destination'];
    LatLng? dest;
    if (destMap is Map<String, dynamic>) {
      final dl = _readDouble(destMap['lat']);
      final dg = _readDouble(destMap['lng']);
      if (dl != null && dg != null) {
        dest = LatLng(dl, dg);
      } else {
        _noDestinationCoords = true;
      }
    }

    final etaRaw = data['eta_minutes'];
    final etaParsed = etaRaw is num ? etaRaw.round() : int.tryParse(etaRaw?.toString() ?? '');
    _serverEtaMin = (etaParsed != null && etaParsed >= 0) ? etaParsed : null;

    setState(() {
      _session = data;
      _destPoint = dest;
      _loading = false;
      _updateDistanceLabel();
    });
  }

  double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  void _updateDistanceLabel() {
    final d = _destPoint;
    if (d == null) {
      _distanceKm = null;
      return;
    }
    final m = Geolocator.distanceBetween(
      _vetPoint.latitude,
      _vetPoint.longitude,
      d.latitude,
      d.longitude,
    );
    _distanceKm = m / 1000.0;
  }

  int? _estimateEtaMinutes() {
    final km = _distanceKm;
    if (km == null || km <= 0) return null;
    final minutes = ((km / _urbanSpeedKmh) * 60).round();
    return minutes.clamp(1, 999);
  }

  Future<void> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => _permissionDenied = true);
      return;
    }
    setState(() => _permissionDenied = false);
  }

  Future<void> _pushLocationIfDue({bool force = false}) async {
    if (_session == null || _error != null) return;
    final now = DateTime.now();
    if (!force &&
        now.difference(_lastPatchAt) < const Duration(seconds: _patchMinIntervalSeconds)) {
      return;
    }

    await _ensureLocationPermission();
    if (_permissionDenied) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      if (!mounted) return;

      setState(() {
        _vetPoint = LatLng(pos.latitude, pos.longitude);
        _updateDistanceLabel();
      });

      final etaOpt = _estimateEtaMinutes();
      final (_, err) = await _api.patchTrackingSessionLocation(
        sessionId: widget.trackingSessionId,
        vetLat: pos.latitude,
        vetLng: pos.longitude,
        etaMinutes: etaOpt,
      );

      if (!mounted) return;
      _lastPatchAt = DateTime.now();

      if (err != null && force) {
        VetgoNotice.show(context, message: err, isError: true);
      } else if (err == null && force && mounted) {
        VetgoNotice.show(context, message: AppStrings.vetRouteUbicacionEnviada);
      }

      if (err == null && mounted && etaOpt != null) {
        setState(() => _serverEtaMin = etaOpt);
      }
    } catch (_) {
      if (force && mounted) {
        VetgoNotice.show(context, message: AppStrings.vetRoutePermisoUbicacion, isError: true);
      }
    }
  }

  Future<void> _manualPush() async {
    setState(() => _locationBusy = true);
    await _pushLocationIfDue(force: true);
    if (mounted) setState(() => _locationBusy = false);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _contextSubtitle() {
    final ctx = _session?['context'];
    if (ctx is Map<String, dynamic>) {
      final s = ctx['subtitle']?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return AppStrings.vetRouteContextoDesconocido;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return VetRouteOsmMap(
                              vetPoint: _vetPoint,
                              destinationPoint: _destPoint,
                              height: constraints.maxHeight.isFinite
                                  ? constraints.maxHeight
                                  : 320,
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        AppStrings.mapaOsmAtribucion,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(color: muted),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: VetSoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _contextSubtitle(),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (_noDestinationCoords && _destPoint == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.vetRouteSinCoordenadasDestino,
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                              ),
                            ],
                            if (_distanceKm != null && _destPoint != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.vetRouteDistanciaKm(_distanceKm!),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (_estimateEtaMinutes() != null && _destPoint != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.vetRouteEtaAproxMinutos(_estimateEtaMinutes()!),
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                            if (_serverEtaMin != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.vetRouteEtaServidorMinutos(_serverEtaMin!),
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                            if (_permissionDenied) ...[
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.vetRoutePermisoUbicacion,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.error.withValues(alpha: 0.85),
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _locationBusy ? null : _manualPush,
                              icon: _locationBusy
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded),
                              label: Text(
                                _locationBusy
                                    ? AppStrings.vetRouteEnviandoUbicacion
                                    : AppStrings.vetRouteActualizarUbicacion,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: VetOperatorColors.mintDeep,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
