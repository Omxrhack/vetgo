import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/vet_patient_record_screen.dart';
import 'package:vetgo/widgets/dashboard/dashboard_section.dart';
import 'package:vetgo/widgets/profile_photo_avatar.dart';
import 'package:vetgo/widgets/vet/vet_async_toggle.dart';
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
    required this.refreshSignal,
  });

  final VetgoApiClient api;
  final String profileName;
  final String? profilePhotoUrl;
  final VoidCallback? onProfilePhotoUpdated;
  final VoidCallback onLogout;
  final VetBaseCallback? onVetBaseResolved;
  final int refreshSignal;

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
    if (widget.refreshSignal != oldWidget.refreshSignal) {
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
    final od = data?['on_duty'] == true;
    setState(() {
      _dutyBusy = false;
      if (_dash != null) {
        _dash = {..._dash!, 'on_duty': od};
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
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: AppStrings.cerrarSesionTooltip,
                icon: const Icon(Icons.logout_rounded),
                onPressed: widget.onLogout,
              ),
            ],
            expandedHeight: 132,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 20,
                right: 72,
                bottom: 12,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.holaDoctor(greetingName),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              background: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 56, top: 36),
                  child: ProfilePhotoAvatar(
                    heroTag: 'vet_avatar',
                    imageUrl: widget.profilePhotoUrl,
                    placeholderBackground: VetOperatorColors.mintSoft,
                    placeholderIconColor: VetOperatorColors.mintDeep,
                    radius: 28,
                    icon: Icons.person_rounded,
                    onUploaded: widget.onProfilePhotoUpdated,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _loading
                    ? VetSoftCard(
                        key: const ValueKey<String>('loading'),
                        padding: const EdgeInsets.symmetric(vertical: 48),
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
                    ? VetSoftCard(
                        key: const ValueKey<String>('err'),
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                        color: scheme.errorContainer.withValues(alpha: 0.35),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 36,
                              color: scheme.error,
                            ),
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
                              _error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildContent(theme, muted),
              ),
            ),
          ),
        ],
      ),
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

    const kpiHeight = 118.0;

    return Column(
          key: const ValueKey<String>('content'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSection(
              title: AppStrings.vetDisponibilidadSection,
              spacingBeforeChild: 14,
              bottomSpacing: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_dutyError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VetSoftCard(
                        padding: const EdgeInsets.all(14),
                        color: VetOperatorColors.coralSoft.withValues(
                          alpha: 0.48,
                        ),
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
                                _dutyError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.85,
                                  ),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  VetDutyToggleCard(
                    available: onDuty,
                    busy: _dutyBusy,
                    onChanged: _onDutyChanged,
                    offTitle: AppStrings.vetDutyOffTitle,
                    onTitle: AppStrings.vetDutyOnTitle,
                    offSubtitle: AppStrings.vetDutyOffSubtitle,
                    onSubtitle: AppStrings.vetDutyOnSubtitle,
                  ),
                ],
              ),
            ),
            DashboardSection(
              title: AppStrings.vetResumenHoy,
              spacingBeforeChild: 14,
              bottomSpacing: 22,
              child: SizedBox(
                height: kpiHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: VetSoftCard(
                        color: VetOperatorColors.mintSoft.withValues(
                          alpha: 0.48,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  size: 18,
                                  color: VetOperatorColors.mintDeep,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.vetCitasPendientes,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (c, a) =>
                                  ScaleTransition(scale: a, child: c),
                              child: Text(
                                '$pending',
                                key: ValueKey<int>(pending),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: VetSoftCard(
                        color: VetOperatorColors.amberSoft.withValues(
                          alpha: 0.52,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStrings.vetGananciasMxn,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: muted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                earnings.toStringAsFixed(0),
                                key: ValueKey<double>(earnings),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DashboardSection(
              title: 'Operación pendiente',
              spacingBeforeChild: 14,
              bottomSpacing: 22,
              child: Row(
                children: [
                  Expanded(
                    child: _SmallOpsCard(
                      icon: Icons.emergency_outlined,
                      label: 'Emergencias',
                      value: '$activeEmergencies',
                      color: theme.colorScheme.errorContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallOpsCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pedidos tienda',
                      value: '$pendingOrders',
                      color: VetOperatorColors.mintSoft,
                    ),
                  ),
                ],
              ),
            ),
            DashboardSection(
              title: AppStrings.vetProximasVisitas,
              subtitle: AppStrings.vetDeslizaMas,
              subtitleColor: muted,
              spacingBeforeChild: 14,
              bottomSpacing: 8,
              child: SizedBox(
                height: 192,
                child: visits.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.vetSinVisitasHoy,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: visits.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, i) {
                          final v = visits[i] is Map<String, dynamic>
                              ? visits[i] as Map<String, dynamic>
                              : {};
                          final timeRaw = v['scheduled_at']?.toString();
                          final dt = timeRaw != null
                              ? DateTime.tryParse(timeRaw)?.toLocal()
                              : null;
                          final timeLabel = dt != null
                              ? DateFormat('HH:mm').format(dt)
                              : '--:--';
                          final pet =
                              v['pet_name']?.toString() ??
                              AppStrings.vetMascota;
                          final col = v['neighborhood']?.toString() ?? '';
                          final apptId = v['appointment_id']?.toString();
                          final petId = v['pet_id'];
                          final petIdStr = petId?.toString();
                          final chipMint = i.isEven;
                          final vetIdRaw = v['vet_id'];
                          final hasAssignedVet =
                              vetIdRaw != null &&
                              vetIdRaw.toString().trim().isNotEmpty;
                          final vetAssignedName =
                              v['vet_name']?.toString().trim() ?? '';

                          return SizedBox(
                            width: 226,
                            child: VetSoftCard(
                              padding: const EdgeInsets.all(14),
                              onTap: apptId != null && petIdStr != null
                                  ? () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              VetPatientRecordScreen(
                                                petId: petIdStr,
                                              ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chipMint
                                          ? VetOperatorColors.mintSoft
                                                .withValues(alpha: 0.65)
                                          : VetOperatorColors.peach.withValues(
                                              alpha: 0.75,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      timeLabel,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.82),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    pet,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    !hasAssignedVet
                                        ? AppStrings
                                              .vetProximaVisitaSinVeterinario
                                        : (vetAssignedName.isNotEmpty
                                              ? vetAssignedName
                                              : AppStrings
                                                    .clienteCitaVeterinarioPendiente),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      col.isEmpty
                                          ? AppStrings.vetDireccionPendiente
                                          : col,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: muted,
                                            height: 1.35,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
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
}

class _SmallOpsCard extends StatelessWidget {
  const _SmallOpsCard({
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
