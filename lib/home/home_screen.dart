import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/core/auth/auth_session.dart';
import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/config/app_config.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'vet_dashboard_screen.dart';
import 'vet_route_screen.dart';
import 'vet_schedule_screen.dart';
import '../widgets/vet/emergency_alert_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLoggedOut});

  /// Tras cerrar sesión vuelve al flujo de login ([AuthFlow]).
  final VoidCallback? onLoggedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<HealthCheckResult> _healthFuture;
  AuthSession? _session;
  bool _sessionReady = false;

  @override
  void initState() {
    super.initState();
    _healthFuture = VetgoApiClient().checkHealth();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final s = await AuthStorage.loadSession();
    if (!mounted) return;
    setState(() {
      _session = s;
      _sessionReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_sessionReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _session?.profile?['role']?.toString();
    if (role == 'vet') {
      final vetName = _session?.profile?['full_name']?.toString() ?? '';
      return VetShell(
        profileFirstName: vetName,
        onLoggedOut: () async {
          await AuthStorage.clear();
          widget.onLoggedOut?.call();
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vetgo listo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                  .slideY(
                    begin: 0.06,
                    end: 0,
                    duration: 450.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),
              Text(
                'Backend',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                AppConfig.apiBaseUrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.onLoggedOut != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await AuthStorage.clear();
                      widget.onLoggedOut?.call();
                    },
                    child: const Text('Cerrar sesión'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FutureBuilder<HealthCheckResult>(
                future: _healthFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comprobando /health…',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    );
                  }

                  final result = snapshot.data;
                  if (result == null) {
                    return Text(
                      'Sin resultado',
                      style: theme.textTheme.bodyLarge,
                    );
                  }

                  final icon = result.ok ? Icons.check_circle : Icons.error_outline;
                  final color = result.ok ? Colors.green.shade700 : theme.colorScheme.error;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: color, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                result.ok ? 'API conectada' : 'Sin conexión',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
