import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/core/supabase/vetgo_supabase.dart';
import 'package:vetgo/public_profile_screen.dart';
import 'package:vetgo/social_screen.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/vet_dashboard_screen.dart';
import 'package:vetgo/vet_route_screen.dart';
import 'package:vetgo/vet_schedule_screen.dart';
import 'package:vetgo/widgets/vet/emergency_alert_sheet.dart';

/// Contenedor principal del veterinario con pestañas y vigilancia de emergencias.
class VetShell extends StatefulWidget {
  const VetShell({
    super.key,
    required this.profileFirstName,
    required this.ownerUserId,
    this.profilePhotoUrl,
    this.onProfilePhotoUpdated,
    required this.onLoggedOut,
  });

  final String profileFirstName;
  final String ownerUserId;
  final String? profilePhotoUrl;
  final VoidCallback? onProfilePhotoUpdated;
  final VoidCallback onLoggedOut;

  @override
  State<VetShell> createState() => _VetShellState();
}

class _VetShellState extends State<VetShell> with WidgetsBindingObserver {
  static const double _defaultLat = 19.432608;
  static const double _defaultLng = -99.133209;

  /// Sin WebSocket de Supabase, la lista solo se actualiza por polling (intervalo corto).
  static const int _pollSecondsNoRealtime = 8;

  /// Con Realtime activo, igual hacemos polling de respaldo por si falla la red o el canal.
  static const int _pollSecondsRealtimeFallback = 45;

  final VetgoApiClient _api = VetgoApiClient();
  int _tabIndex = 0;
  int _refreshSignal = 0;
  Timer? _emergencyPoll;
  RealtimeChannel? _emergencyRealtimeChannel;

  double? _vetLat;
  double? _vetLng;
  String? _emergencySheetLockId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapEmergencyWatch();
  }

  Future<void> _bootstrapEmergencyWatch() async {
    final session = await AuthStorage.loadSession();
    await VetgoSupabase.syncSession(
      refreshToken: session?.refreshToken,
      accessToken: session?.accessToken,
    );

    final vetId = session?.user?['id']?.toString();
    var pollSeconds = _pollSecondsNoRealtime;
    if (vetId != null && vetId.isNotEmpty && VetgoSupabase.isInitialized) {
      final subscribed = await _subscribeEmergencyRealtime(vetId);
      if (subscribed) {
        pollSeconds = _pollSecondsRealtimeFallback;
      }
    }

    _emergencyPoll?.cancel();
    _emergencyPoll = Timer.periodic(
      Duration(seconds: pollSeconds),
      (_) => _pollEmergencies(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollEmergencies());
  }

  Future<bool> _subscribeEmergencyRealtime(String vetUserId) async {
    try {
      await _emergencyRealtimeChannel?.unsubscribe();
      _emergencyRealtimeChannel = null;

      final channel = VetgoSupabase.client
          .channel('public_emergencies_$vetUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'emergencies',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'assigned_vet_id',
              value: vetUserId,
            ),
            callback: (_) {
              if (!mounted) return;
              _pollEmergencies();
            },
          )
          .subscribe();

      _emergencyRealtimeChannel = channel;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _emergencyPoll?.cancel();
    unawaited(_emergencyRealtimeChannel?.unsubscribe());
    _emergencyRealtimeChannel = null;
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

  void _selectTab(int index) {
    if (_tabIndex == index) return;
    setState(() {
      _tabIndex = index;
      _refreshSignal++;
    });
  }

  (double, double) _resolveVetCoordinates() {
    return (_vetLat ?? _defaultLat, _vetLng ?? _defaultLng);
  }

  VetEmergencyVm _mapEmergency(Map<String, dynamic> e) {
    final pet = e['pet'] is Map<String, dynamic>
        ? e['pet'] as Map<String, dynamic>
        : {};
    final dist = e['distance_km'];
    return VetEmergencyVm(
      id: e['id']?.toString() ?? '',
      symptoms: e['symptoms']?.toString() ?? '',
      status: e['status']?.toString() ?? '',
      petName: pet['name']?.toString() ?? AppStrings.vetMascota,
      species: pet['species']?.toString() ?? AppStrings.vetPacienteEspecie,
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
        final (_, errRespond) = await _api.respondVetEmergency(
          emergencyId: id,
          accept: true,
        );
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
          throw Exception(AppStrings.vetSesionRutaSinId);
        }
        routeSessionAfterSheet = sid;
      },
      onReject: () async {
        final (_, err) = await _api.respondVetEmergency(
          emergencyId: id,
          accept: false,
        );
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
            title: AppStrings.vetRutaEmergencia,
          ),
        ),
      );
      if (mounted) {
        setState(() => _refreshSignal++);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final screenWidth = MediaQuery.sizeOf(context).width;

    Widget buildBarItem({
      required int tabIndex,
      required IconData iconOutlined,
      required IconData iconFilled,
      required String label,
    }) {
      final selected = _tabIndex == tabIndex;
      final color = selected ? scheme.primary : muted;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _selectTab(tabIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      selected ? iconFilled : iconOutlined,
                      size: 23,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: selected ? 14 : 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final screens = <Widget>[
      VetDashboardScreen(
        api: _api,
        profileName: widget.profileFirstName,
        profilePhotoUrl: widget.profilePhotoUrl,
        onProfilePhotoUpdated: widget.onProfilePhotoUpdated,
        onVetBaseResolved: _onVetBaseResolved,
        onLogout: widget.onLoggedOut,
        refreshSignal: _refreshSignal,
      ),
      VetScheduleScreen(
        api: _api,
        resolveVetCoordinates: _resolveVetCoordinates,
        onLogout: widget.onLoggedOut,
        refreshSignal: _refreshSignal,
      ),
      const SocialScreen(),
      const StoreScreen(isVet: true),
      PublicProfileScreen(
        profileId: widget.ownerUserId,
        isOwnProfile: true,
        showBackButton: false,
        onLogout: widget.onLoggedOut,
      ),
    ];

    final content = KeyedSubtree(
      key: ValueKey<int>(_tabIndex),
      child: screens[_tabIndex],
    );

    final barWidget = SizedBox(
      height: 68,
      child: Row(
        children: [
          buildBarItem(
            tabIndex: 0,
            iconOutlined: Icons.home_outlined,
            iconFilled: Icons.home_rounded,
            label: AppStrings.vetNavInicio,
          ),
          buildBarItem(
            tabIndex: 1,
            iconOutlined: Icons.calendar_month_outlined,
            iconFilled: Icons.calendar_month_rounded,
            label: AppStrings.vetNavAgenda,
          ),
          buildBarItem(
            tabIndex: 2,
            iconOutlined: Icons.people_outline_rounded,
            iconFilled: Icons.people_rounded,
            label: 'Social',
          ),
          buildBarItem(
            tabIndex: 3,
            iconOutlined: Icons.storefront_outlined,
            iconFilled: Icons.storefront_rounded,
            label: 'Tienda',
          ),
          buildBarItem(
            tabIndex: 4,
            iconOutlined: Icons.person_outline_rounded,
            iconFilled: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BottomBar(
        body: content,
        showIcon: false,
        layout: BottomBarLayout(
          width: screenWidth - 24,
          offset: 12,
          borderRadius: BorderRadius.circular(32),
          fit: StackFit.expand,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        child: barWidget,
      ),
    );
  }
}
