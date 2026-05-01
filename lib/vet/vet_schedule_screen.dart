import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/network/vetgo_api_client.dart';
import 'package:vetgo/vet/vet_patient_record_screen.dart';
import 'package:vetgo/vet/vet_route_screen.dart';
import 'package:vetgo/widgets/vet/vet_app_colors.dart';
import 'package:vetgo/widgets/vet/vet_async_toggle.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';

/// Agenda del dùa con lùnea de tiempo e ùtems expansibles.
class VetScheduleScreen extends StatefulWidget {
  const VetScheduleScreen({
    super.key,
    required this.api,
    required this.resolveVetCoordinates,
  });

  final VetgoApiClient api;
  final (double lat, double lng) Function() resolveVetCoordinates;

  @override
  State<VetScheduleScreen> createState() => _VetScheduleScreenState();
}

class _VetScheduleScreenState extends State<VetScheduleScreen> {
  Map<String, dynamic>? _schedule;
  String? _error;
  String? _routeError;
  bool _loading = true;
  final Map<String, bool> _routeBusy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _routeError = null;
    });
    final (data, err) = await widget.api.getVetSchedule();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _schedule = data;
      _error = err;
    });
  }

  Future<void> _startRoute(String appointmentId) async {
    setState(() => _routeBusy[appointmentId] = true);
    final coords = widget.resolveVetCoordinates();
    final (data, err) = await widget.api.createTrackingSession(
      appointmentId: appointmentId,
      vetLat: coords.lat,
      vetLng: coords.lng,
    );
    if (!mounted) return;
    setState(() => _routeBusy[appointmentId] = false);
    if (err != null || data == null) {
      setState(() => _routeError = err ?? 'No se pudo iniciar la ruta.');
      return;
    }
    final sessionId = data['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) return;
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VetRouteScreen(trackingSessionId: sessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: VetAppColors.bone,
      body: RefreshIndicator(
        onRefresh: _load,
        color: VetAppColors.mintDeep,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: VetAppColors.bone,
              surfaceTintColor: Colors.transparent,
              title: const Text('Agenda y ruta'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _loading
                      ? const SizedBox(
                          key: ValueKey<String>('l'),
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _error != null && (_schedule == null)
                          ? Text(
                              key: const ValueKey<String>('e'),
                              _error!,
                              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                            )
                          : _buildTimeline(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final raw = _schedule?['appointments'];
    final list = raw is List ? raw : const [];
    if (list.isEmpty) {
      return Text(
        key: const ValueKey<String>('empty'),
        'Sin citas para este dùa. Asigna vet_id en una cita para pruebas.',
        style: theme.textTheme.bodyMedium?.copyWith(color: VetAppColors.textMuted),
      );
    }

    return Column(
      key: const ValueKey<String>('tl'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_routeError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _routeError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(
          'LÌnea del dÌa',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...List.generate(list.length, (i) {
          final row = list[i] is Map<String, dynamic> ? list[i] as Map<String, dynamic> : {};
          final id = row['id']?.toString() ?? '$i';
          final scheduledRaw = row['scheduled_at']?.toString();
          final dt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw)?.toLocal() : null;
          final timeLabel = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
          final petMap = row['pet'] is Map<String, dynamic> ? row['pet'] as Map<String, dynamic> : {};
          final petName = petMap['name']?.toString() ?? 'Mascota';
          final addr = row['client_address'] is Map<String, dynamic>
              ? (row['client_address'] as Map<String, dynamic>)['address_text']?.toString()
              : null;
          final busy = _routeBusy[id] == true;

          return Padding(
            padding: EdgeInsets.only(bottom: i == list.length - 1 ? 24 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VetAppColors.mintDeep.withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: VetAppColors.mintSoft.withValues(alpha: 0.9),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (i < list.length - 1)
                        Container(
                          width: 2,
                          height: 56,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: VetAppColors.mintSoft.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: VetSoftCard(
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      child: ClipRRect(
                        borderRadius: VetSoftCard.radius,
                        child: ExpansionTile(
                          key: PageStorageKey<String>('appt_$id'),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          title: Text(
                            timeLabel,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '$petName ù ${addr ?? 'Sin colonia'}',
                            style: theme.textTheme.bodySmall?.copyWith(color: VetAppColors.textMuted),
                          ),
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      final petId = petMap['id']?.toString();
                                      if (petId == null) return;
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => VetPatientRecordScreen(petId: petId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.article_outlined),
                                    label: const Text('Ver expediente'),
                                  ),
                                  const SizedBox(height: 6),
                                  VetAsyncPrimaryButton(
                                    label: 'Iniciar ruta',
                                    busy: busy,
                                    onPressed: busy ? null : () => _startRoute(id),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
