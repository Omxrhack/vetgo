import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/vet_patient_record_screen.dart';
import 'package:vetgo/widgets/profile_photo_avatar.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';

typedef VetBaseCallback = void Function(double? lat, double? lng);

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({
    super.key,
    required this.api,
    required this.profileName,
    this.profilePhotoUrl,
    this.onProfilePhotoUpdated,
    required this.onLogout,
    this.onVetBaseResolved,
    this.refreshSignal,
  });

  final VetgoApiClient api;
  final String profileName;
  final String? profilePhotoUrl;
  final VoidCallback? onProfilePhotoUpdated;
  final VoidCallback onLogout;
  final VetBaseCallback? onVetBaseResolved;
  final int? refreshSignal;

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  Map<String, dynamic>? _dash;
  String? _error;
  bool _loading = true;
  bool _dutyBusy = false;
  String? _dutyError;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant VetDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.refreshSignal ?? 0) != (oldWidget.refreshSignal ?? 0)) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await widget.api.getVetDashboard();
    if (!mounted) return;

    if (data != null) {
      widget.onVetBaseResolved?.call(
        (data['vet_base_latitude'] as num?)?.toDouble(),
        (data['vet_base_longitude'] as num?)?.toDouble(),
      );
    }

    setState(() {
      _loading = false;
      _dash = data;
      _error = err;
    });
  }

  Future<void> _onDutyChanged(bool available) async {
    setState(() {
      _dutyBusy = true;
      _dutyError = null;
    });
    final (data, err) = await widget.api.patchVetAvailability(
      onDuty: available,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _dutyBusy = false;
        _dutyError = err;
      });
      return;
    }
    final onDuty = data?['on_duty'] == true;
    setState(() {
      _dutyBusy = false;
      if (_dash != null) {
        _dash = {..._dash!, 'on_duty': onDuty};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);
    final greetingName = widget.profileName.trim();
    final dateLine = DateFormat(
      "EEEE d 'de' MMMM",
      'es',
    ).format(DateTime.now());

    return RefreshIndicator(
      onRefresh: _refresh,
      color: scheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme, muted, greetingName, dateLine),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: _loading
                          ? VetSoftCard(
                              key: const ValueKey<String>('loading'),
                              padding: const EdgeInsets.symmetric(vertical: 56),
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.35,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: scheme.primary,
                                ),
                              ),
                            )
                          : _error != null
                          ? _DashboardErrorCard(message: _error!)
                          : _buildContent(theme, muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    Color muted,
    String greetingName,
    String dateLine,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.holaDoctor(greetingName),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.04,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                dateLine,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        ProfilePhotoAvatar(
          heroTag: 'vet_avatar',
          imageUrl: widget.profilePhotoUrl,
          placeholderBackground: VetOperatorColors.mintSoft,
          placeholderIconColor: VetOperatorColors.mintDeep,
          radius: 34,
          icon: Icons.person_rounded,
          onUploaded: widget.onProfilePhotoUpdated,
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, Color muted) {
    final dash = _dash!;
    final onDuty = dash['on_duty'] == true;
    final pending = (dash['pending_count'] as num?)?.toInt() ?? 0;
    final activeEmergencies =
        (dash['active_emergencies_count'] as num?)?.toInt() ?? 0;
    final pendingOrders =
        (dash['pending_store_orders_count'] as num?)?.toInt() ?? 0;
    final earnings = (dash['earnings_mxn_today'] as num?)?.toDouble() ?? 0;
    final visits = dash['visits'] is List
        ? dash['visits'] as List<dynamic>
        : const [];

    return Column(
          key: const ValueKey<String>('content'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_dutyError != null) ...[
              _DutyErrorCard(message: _dutyError!),
              const SizedBox(height: 14),
            ],
            _OperationalHeroCard(
              onDuty: onDuty,
              busy: _dutyBusy,
              pending: pending,
              activeEmergencies: activeEmergencies,
              pendingOrders: pendingOrders,
              earnings: earnings,
              onChanged: _onDutyChanged,
            ),
            const SizedBox(height: 18),
            _buildMetricsRow(
              theme,
              pending: pending,
              activeEmergencies: activeEmergencies,
              pendingOrders: pendingOrders,
              earnings: earnings,
            ),
            const SizedBox(height: 24),
            _buildVisitSection(theme, muted, visits),
          ],
        )
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildMetricsRow(
    ThemeData theme, {
    required int pending,
    required int activeEmergencies,
    required int pendingOrders,
    required double earnings,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.event_available_rounded,
                label: 'Citas',
                value: '$pending',
                color: VetOperatorColors.mintSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.warning_amber_rounded,
                label: 'Urgencias',
                value: '$activeEmergencies',
                color: theme.colorScheme.errorContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.receipt_long_rounded,
                label: 'Pedidos',
                value: '$pendingOrders',
                color: VetOperatorColors.lilacHint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.payments_rounded,
                label: 'Hoy MXN',
                value: earnings.toStringAsFixed(0),
                color: VetOperatorColors.amberSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitSection(
    ThemeData theme,
    Color muted,
    List<dynamic> visits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.vetProximasVisitas,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                '${visits.length} hoy',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Toca una visita para abrir el expediente del paciente.',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 14),
        if (visits.isEmpty)
          VetSoftCard(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: VetOperatorColors.mintSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    color: VetOperatorColors.mintDeep,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppStrings.vetSinVisitasHoy,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...visits.asMap().entries.map((entry) {
            final value = entry.value;
            final visit = value is Map<String, dynamic>
                ? value
                : <String, dynamic>{};
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == visits.length - 1 ? 0 : 12,
              ),
              child: _VisitAgendaCard(
                visit: visit,
                muted: muted,
                accentColor: entry.key.isEven
                    ? VetOperatorColors.mintSoft
                    : VetOperatorColors.peach,
                onTap: () {
                  final petId = visit['pet_id']?.toString();
                  if (petId == null || petId.isEmpty) return;
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => VetPatientRecordScreen(petId: petId),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return VetSoftCard(
      key: const ValueKey<String>('err'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      color: scheme.errorContainer.withValues(alpha: 0.35),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 36, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            AppStrings.vetDashboardErrorTitulo,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DutyErrorCard extends StatelessWidget {
  const _DutyErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VetSoftCard(
      padding: const EdgeInsets.all(14),
      color: VetOperatorColors.coralSoft.withValues(alpha: 0.48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalHeroCard extends StatelessWidget {
  const _OperationalHeroCard({
    required this.onDuty,
    required this.busy,
    required this.pending,
    required this.activeEmergencies,
    required this.pendingOrders,
    required this.earnings,
    required this.onChanged,
  });

  final bool onDuty;
  final bool busy;
  final int pending;
  final int activeEmergencies;
  final int pendingOrders;
  final double earnings;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.62);
    final heroColor = onDuty
        ? VetOperatorColors.mintSoft.withValues(alpha: 0.6)
        : VetOperatorColors.peach.withValues(alpha: 0.58);

    return VetSoftCard(
      color: heroColor,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(onDuty: onDuty),
              const Spacer(),
              Icon(
                onDuty
                    ? Icons.health_and_safety_rounded
                    : Icons.nightlight_round,
                color: onDuty ? VetOperatorColors.mintDeep : scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            onDuty ? 'Centro operativo activo' : 'Turno pausado',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            onDuty
                ? 'Tienes $pending citas en seguimiento y $activeEmergencies urgencias activas.'
                : 'Activa tu disponibilidad para recibir nuevas asignaciones.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: AppStrings.vetCitasPendientes,
                  value: '$pending',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Pedidos por confirmar',
                  value: '$pendingOrders',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: AppStrings.vetGananciasMxn,
                  value: earnings.toStringAsFixed(0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.vetDisponibilidadSection,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: busy
                      ? SizedBox(
                          key: const ValueKey<String>('busy'),
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: scheme.primary,
                          ),
                        )
                      : Switch.adaptive(
                          key: const ValueKey<String>('switch'),
                          value: onDuty,
                          activeThumbColor: scheme.primary,
                          activeTrackColor: scheme.primaryContainer,
                          onChanged: onChanged,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.onDuty});

  final bool onDuty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: onDuty ? VetOperatorColors.mintDeep : Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            onDuty ? 'Disponible' : 'Fuera de turno',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return VetSoftCard(
      color: color.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(15),
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.66),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary, size: 19),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitAgendaCard extends StatelessWidget {
  const _VisitAgendaCard({
    required this.visit,
    required this.muted,
    required this.accentColor,
    required this.onTap,
  });

  final Map<String, dynamic> visit;
  final Color muted;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeRaw = visit['scheduled_at']?.toString();
    final dt = timeRaw != null ? DateTime.tryParse(timeRaw)?.toLocal() : null;
    final timeLabel = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
    final petName = visit['pet_name']?.toString() ?? AppStrings.vetMascota;
    final neighborhood = visit['neighborhood']?.toString() ?? '';
    final vetIdRaw = visit['vet_id'];
    final hasAssignedVet =
        vetIdRaw != null && vetIdRaw.toString().trim().isNotEmpty;
    final vetAssignedName = visit['vet_name']?.toString().trim() ?? '';
    final assignedLabel = !hasAssignedVet
        ? AppStrings.vetProximaVisitaSinVeterinario
        : (vetAssignedName.isNotEmpty
              ? vetAssignedName
              : AppStrings.clienteCitaVeterinarioPendiente);

    return VetSoftCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                timeLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  neighborhood.isEmpty
                      ? AppStrings.vetDireccionPendiente
                      : neighborhood,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.36),
          ),
        ],
      ),
    );
  }
}
