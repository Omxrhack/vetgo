import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/vet_dashboard_screen.dart';
import 'package:vetgo/vet_route_screen.dart';
import 'package:vetgo/vet_schedule_screen.dart';
import 'package:vetgo/widgets/vet/emergency_alert_sheet.dart';

/// Contenedor principal del veterinario con pestañas y vigilancia de emergencias.
class VetShell extends StatefulWidget {
  const VetShell({
    super.key,
    required this.profileFirstName,
    required this.onLoggedOut,
  });

  final String profileFirstName;
  final VoidCallback onLoggedOut;

  @override
  State<VetShell> createState() => _VetShellState();
}

class _VetShellState extends State<VetShell> with WidgetsBindingObserver {
  static const double _defaultLat = 19.432608;
  static const double _defaultLng = -99.133209;

  final VetgoApiClient _api = VetgoApiClient();
  int _tabIndex = 0;
  Timer? _emergencyPoll;

  double? _vetLat;
  double? _vetLng;
  String? _emergencySheetLockId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emergencyPoll = Timer.periodic(const Duration(seconds: 25), (_) => _pollEmergencies());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollEmergencies());
  }

  @override
  void dispose() {
    _emergencyPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollEmergencies();
    }
  }

  void _onVetBaseResolved(double? lat, double? lng) {
    setState(() {
      _vetLat = lat;
      _vetLng = lng;
    });
  }

  (double, double) _resolveVetCoordinates() {
    return (_vetLat ?? _defaultLat, _vetLng ?? _defaultLng);
  }

  VetEmergencyVm _mapEmergency(Map<String, dynamic> e) {
    final pet = e['pet'] is Map<String, dynamic> ? e['pet'] as Map<String, dynamic> : {};
    final dist = e['distance_km'];
    return VetEmergencyVm(
      id: e['id']?.toString() ?? '',
      symptoms: e['symptoms']?.toString() ?? '',
      status: e['status']?.toString() ?? '',
      petName: pet['name']?.toString() ?? 'Mascota',
      species: pet['species']?.toString() ?? 'Paciente',
      distanceKm: dist is num ? dist.toDouble() : null,
    );
  }

  Future<void> _pollEmergencies() async {
    if (!mounted) return;
    final (data, _) = await _api.getVetEmergenciesActive();
    if (!mounted || data == null) return;

    final raw = data['emergencies'];
    if (raw is! List) return;

    final open = raw
        .map((e) => e is Map<String, dynamic> ? e : null)
        .whereType<Map<String, dynamic>>()
        .where((e) => e['status'] == 'open')
        .toList();

    if (open.isEmpty) return;

    final first = open.first;
    final id = first['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (_emergencySheetLockId == id) return;
    _emergencySheetLockId = id;

    if (!mounted) return;

    String? routeSessionAfterSheet;

    await showVetEmergencyAlertSheet(
      context: context,
      emergency: _mapEmergency(first),
      onAccept: () async {
        final (_, errRespond) = await _api.respondVetEmergency(emergencyId: id, accept: true);
        if (errRespond != null) {
          throw Exception(errRespond);
        }
        final coords = _resolveVetCoordinates();
        final (track, errTrack) = await _api.createTrackingSession(
          emergencyId: id,
          vetLat: coords.$1,
          vetLng: coords.$2,
        );
        if (errTrack != null) {
          throw Exception(errTrack);
        }
        final sid = track?['id']?.toString();
        if (sid == null || sid.isEmpty) {
          throw Exception('Sesión de ruta sin id.');
        }
        routeSessionAfterSheet = sid;
      },
      onReject: () async {
        final (_, err) = await _api.respondVetEmergency(emergencyId: id, accept: false);
        if (err != null) {
          throw Exception(err);
        }
      },
    );

    if (!mounted) return;
    setState(() => _emergencySheetLockId = null);

    final sid = routeSessionAfterSheet;
    if (sid != null && sid.isNotEmpty) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VetRouteScreen(
            trackingSessionId: sid,
            title: 'Ruta de emergencia',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          VetDashboardScreen(
            api: _api,
            profileName: widget.profileFirstName,
            onVetBaseResolved: _onVetBaseResolved,
            onLogout: widget.onLoggedOut,
          ),
          VetScheduleScreen(
            api: _api,
            resolveVetCoordinates: _resolveVetCoordinates,
            onLogout: widget.onLoggedOut,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
        ],
      ),
    );
  }
}
