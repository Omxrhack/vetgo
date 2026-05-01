import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/vet_patient_record_screen.dart';
import 'package:vetgo/vet_route_screen.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';
import 'package:vetgo/widgets/vet/vet_async_toggle.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';

/// Agenda del dùa con lùnea de tiempo e ùtems expansibles.
class VetScheduleScreen extends StatefulWidget {
  const VetScheduleScreen({
    super.key,
    required this.api,
    required this.resolveVetCoordinates,
    required this.onLogout,
  });

  final VetgoApiClient api;
  final (double lat, double lng) Function() resolveVetCoordinates;
  final VoidCallback onLogout;

  @override
  State<VetScheduleScreen> createState() => _VetScheduleScreenState();
}

class _VetScheduleScreenState extends State<VetScheduleScreen> {
  Map<String, dynamic>? _schedule;
  String? _error;
  String? _routeError;
  bool _loading = true;
  final Map<String, bool> _routeBusy = {};
  final Map<String, bool> _claimBusy = {};

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
      vetLat: coords.$1,
      vetLng: coords.$2,
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

  Future<void> _claimAppointment(String appointmentId) async {
    setState(() => _claimBusy[appointmentId] = true);
    final (_, err) = await widget.api.claimVetAppointment(appointmentId: appointmentId);
    if (!mounted) return;
    setState(() => _claimBusy[appointmentId] = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: AppStrings.vetScheduleCitaAsignadaOk);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: scheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: Text(AppStrings.vetScheduleTitulo),
              actions: [
                IconButton(
                  tooltip: AppStrings.cerrarSesionTooltip,
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: widget.onLogout,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _loading
                      ? SizedBox(
                          key: const ValueKey<String>('l'),
                          height: 200,
                          child: Center(child: CircularProgressIndicator(color: scheme.primary)),
                        )
                      : _error != null && (_schedule == null)
                          ? Text(
                              key: const ValueKey<String>('e'),
                              _error!,
                              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
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
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);
    final raw = _schedule?['appointments'];
    final list = raw is List ? raw : const [];
    if (list.isEmpty) {
      return Text(
        key: const ValueKey<String>('empty'),
        AppStrings.vetScheduleSinCitas,
        style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
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
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(
          AppStrings.vetScheduleLineaDelDia,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...List.generate(list.length, (i) {
          final row = list[i] is Map<String, dynamic> ? list[i] as Map<String, dynamic> : {};
          final id = row['id']?.toString() ?? '$i';
          final vetIdAssigned = row['vet_id'];
          final isPoolAppointment = vetIdAssigned == null;
          final scheduledRaw = row['scheduled_at']?.toString();
          final dt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw)?.toLocal() : null;
          final timeLabel = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
          final petMap = row['pet'] is Map<String, dynamic> ? row['pet'] as Map<String, dynamic> : {};
          final petName = petMap['name']?.toString() ?? AppStrings.vetMascota;
          final species = petMap['species']?.toString() ?? '';
          final breed = petMap['breed']?.toString() ?? '';
          final speciesLine = [species, breed].where((s) => s.trim().isNotEmpty).join(' \u00B7 ');
          final addr = row['client_address'] is Map<String, dynamic>
              ? (row['client_address'] as Map<String, dynamic>)['address_text']?.toString()
              : null;
          final vetMap = row['vet'] is Map<String, dynamic> ? row['vet'] as Map<String, dynamic> : {};
          final vetName = vetMap['full_name']?.toString().trim() ?? '';
          final addrNotes = row['client_address'] is Map<String, dynamic>
              ? (row['client_address'] as Map<String, dynamic>)['address_notes']?.toString()
              : null;
          final busy = _routeBusy[id] == true;
          final subtitleAddr = addr?.trim().isNotEmpty == true ? addr!.trim() : AppStrings.vetScheduleSinColonia;
          final notes = row['notes']?.toString().trim() ?? '';
          final statusRaw = row['status']?.toString() ?? '';

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
                          color: VetOperatorColors.mintDeep.withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: VetOperatorColors.mintSoft.withValues(alpha: 0.9),
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
                            color: VetOperatorColors.mintSoft.withValues(alpha: 0.85),
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
                      child: ClipRRect(
                        borderRadius: VetSoftCard.radius,
                        child: ExpansionTile(
                          key: PageStorageKey<String>('appt_$id'),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  timeLabel,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (isPoolAppointment)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      AppStrings.vetScheduleCitaSinAsignar,
                                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    backgroundColor: VetOperatorColors.peach.withValues(alpha: 0.55),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                speciesLine.isNotEmpty ? '$petName \u00B7 $speciesLine' : petName,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (!isPoolAppointment) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.medical_information_outlined,
                                      size: 17,
                                      color: VetOperatorColors.mintDeep.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            AppStrings.vetScheduleVeterinarioTitulo,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: muted,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            vetName.isNotEmpty ? vetName : AppStrings.clienteCitaVeterinarioPendiente,
                                            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              Text(
                                subtitleAddr,
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (addrNotes != null && addrNotes.trim().isNotEmpty)
                                Text(
                                  addrNotes.trim(),
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (statusRaw.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        AppStrings.vetScheduleEstado(statusRaw),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (notes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        notes,
                                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                                      ),
                                    ),
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
                                    label: Text(AppStrings.vetScheduleVerExpediente),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isPoolAppointment) ...[
                                    Text(
                                      AppStrings.vetScheduleRutaRequiereAsignacion,
                                      style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                                    ),
                                    const SizedBox(height: 10),
                                    VetAsyncPrimaryButton(
                                      label: AppStrings.vetScheduleTomarCita,
                                      busy: _claimBusy[id] == true,
                                      onPressed:
                                          _claimBusy[id] == true ? null : () => _claimAppointment(id),
                                    ),
                                  ] else
                                    VetAsyncPrimaryButton(
                                      label: AppStrings.vetScheduleIniciarRuta,
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
