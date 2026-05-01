import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/client/client_quick_access_hub_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/live_tracking_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/pastel_quick_action_card.dart';
import 'package:vetgo/widgets/dashboard/dashboard_section.dart';
import 'package:vetgo/widgets/profile_photo_avatar.dart';

/// Home / dashboard principal del cliente (estetica pastel Vetgo).
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.pets,
    this.petsLoading = false,
    this.petsError,
    required this.onRefreshPets,
    required this.onLogout,
    required this.onOpenEmergency,
    this.onProfilePhotoUpdated,
  });

  final String userName;
  final String? profilePhotoUrl;
  final VoidCallback? onProfilePhotoUpdated;
  final List<ClientPetVm> pets;
  final bool petsLoading;
  final String? petsError;
  final Future<void> Function() onRefreshPets;
  final VoidCallback onLogout;
  final VoidCallback onOpenEmergency;

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  List<Map<String, dynamic>> _appointmentsRaw = [];
  bool _apptLoading = true;
  String? _apptError;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _apptLoading = true;
      _apptError = null;
    });
    final (data, err) = await _api.listMyAppointments();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _apptLoading = false;
        _apptError = err;
        _appointmentsRaw = [];
      });
      return;
    }
    final raw = data?['appointments'];
    final list = raw is List
        ? raw.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList()
        : <Map<String, dynamic>>[];
    setState(() {
      _apptLoading = false;
      _apptError = null;
      _appointmentsRaw = list;
    });
  }

  List<Map<String, dynamic>> _upcomingAppointments() {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    return _appointmentsRaw.where((a) {
      final st = a['status']?.toString() ?? '';
      if (st == 'cancelled' || st == 'completed') return false;
      final rawT = a['scheduled_at']?.toString();
      final t = rawT != null ? DateTime.tryParse(rawT)?.toLocal() : null;
      if (t == null) return false;
      return !t.isBefore(startToday);
    }).take(12).toList();
  }

  Future<void> _onRefresh() async {
    await Future.wait<void>([
      widget.onRefreshPets(),
      _loadAppointments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = ClientPastelColors.mutedOn(context);
    final displayName = widget.userName.trim().isEmpty ? 'amigo' : widget.userName.trim();

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 132,
            actions: [
              IconButton(
                tooltip: AppStrings.cerrarSesionTooltip,
                icon: const Icon(Icons.logout_rounded),
                onPressed: widget.onLogout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 52, bottom: 12),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.holaNombre(displayName),
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
                          AppStrings.dashboardClienteTagline,
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
                  ),
                  const SizedBox(width: 12),
                  ProfilePhotoAvatar(
                    heroTag: 'client_avatar',
                    imageUrl: widget.profilePhotoUrl,
                    placeholderBackground: ClientPastelColors.mintSoft,
                    placeholderIconColor: ClientPastelColors.mintDeep,
                    radius: 26,
                    onUploaded: widget.onProfilePhotoUpdated,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.petsError != null && widget.petsError!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClientSoftCard(
                        color: scheme.errorContainer.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: scheme.error, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${AppStrings.mascotasErrorParcial} (${widget.petsError})',
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  DashboardSection(
                    title: AppStrings.recordatoriosTitulo,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 10,
                    child: ClientSoftCard(
                      color: ClientPastelColors.amberSoft.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            color: ClientPastelColors.skyDeep,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.recordatoriosCuerpo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.03, end: 0, duration: 320.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.clienteProximasCitas,
                    subtitleColor: muted,
                    bottomSpacing: 18,
                    spacingBeforeChild: 10,
                    child: _buildClientAppointmentsSection(theme, muted),
                  )
                      .animate()
                      .fadeIn(delay: 25.ms, duration: 340.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.03, end: 0, delay: 25.ms, duration: 340.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.dashboardClienteSeccionAcciones,
                    subtitle: AppStrings.accesosHubSubtitulo,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 14,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.apps_rounded,
                                label: AppStrings.quickActionServiciosLabel,
                                backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.72),
                                iconColor: ClientPastelColors.mintDeep,
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ClientQuickAccessHubScreen(pets: widget.pets),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.storefront_rounded,
                                label: AppStrings.quickActionTiendaLabel,
                                backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.68),
                                iconColor: scheme.secondary,
                                onTap: () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.emergency_rounded,
                                label: AppStrings.quickActionEmergenciaLabel,
                                backgroundColor: ClientPastelColors.coralSoft.withValues(alpha: 0.62),
                                iconColor: scheme.error.withValues(alpha: 0.85),
                                onTap: widget.onOpenEmergency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.location_searching_rounded,
                                label: AppStrings.quickActionTrackingLabel,
                                backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                                iconColor: ClientPastelColors.skyDeep,
                                onTap: () async {
                                  await Future<void>.delayed(const Duration(milliseconds: 420));
                                  if (!context.mounted) return;
                                  await Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LiveTrackingScreen(
                                        vetName: AppStrings.demoVetNombre,
                                        etaLabel: AppStrings.demoEta,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.tusMascotas,
                    subtitleColor: muted,
                    bottomSpacing: 20,
                    spacingBeforeChild: 12,
                    trailing: TextButton(
                      onPressed: widget.pets.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => PetProfileScreen(pet: widget.pets.first),
                                ),
                              );
                            },
                      child: const Text(AppStrings.verExpediente),
                    ),
                    child: SizedBox(
                      height: 148,
                      child: widget.petsLoading && widget.pets.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : widget.pets.isEmpty
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppStrings.carouselSinMascotas,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.pets.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                                  itemBuilder: (context, i) {
                                    final p = widget.pets[i];
                                    return _PetCarouselTile(
                                      pet: p,
                                      onTap: () {
                                        Navigator.of(context).push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) => PetProfileScreen(pet: p),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAppointmentsSection(ThemeData theme, Color muted) {
    if (_apptLoading && _appointmentsRaw.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_apptError != null) {
      return ClientSoftCard(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.28),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: theme.colorScheme.error, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.clienteCitasErrorCarga,
                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    final upcoming = _upcomingAppointments();
    if (upcoming.isEmpty) {
      return ClientSoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          AppStrings.clienteSinCitasProgramadas,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < upcoming.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ClientAppointmentSummaryTile(
            row: upcoming[i],
            muted: muted,
          ),
        ],
      ],
    );
  }
}

class _ClientAppointmentSummaryTile extends StatelessWidget {
  const _ClientAppointmentSummaryTile({
    required this.row,
    required this.muted,
  });

  final Map<String, dynamic> row;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledRaw = row['scheduled_at']?.toString();
    final dt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw)?.toLocal() : null;
    final whenLabel = dt != null
        ? '${DateFormat('EEEE d MMM', 'es').format(dt)} \u00B7 ${DateFormat.Hm('es').format(dt)}'
        : '\u2014';
    final petMap = row['pet'] is Map<String, dynamic> ? row['pet'] as Map<String, dynamic> : {};
    final petName = petMap['name']?.toString().trim().isNotEmpty == true
        ? petMap['name']!.toString().trim()
        : AppStrings.vetMascota;
    final vetMap = row['vet'] is Map<String, dynamic> ? row['vet'] as Map<String, dynamic> : {};
    final vetName = vetMap['full_name']?.toString().trim() ?? '';
    final hasVetId = row['vet_id'] != null && row['vet_id'].toString().trim().isNotEmpty;
    final vetLine = !hasVetId
        ? AppStrings.clienteCitaVeterinarioPendiente
        : (vetName.isNotEmpty ? AppStrings.clienteCitaLineaVeterinario(vetName) : AppStrings.clienteCitaVeterinarioPendiente);

    return ClientSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            whenLabel,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            petName,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_information_outlined, size: 18, color: ClientPastelColors.skyDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vetLine,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetCarouselTile extends StatelessWidget {
  const _PetCarouselTile({required this.pet, required this.onTap});

  final ClientPetVm pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 118,
      child: ClientSoftCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        color: theme.colorScheme.surface,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ClientPastelColors.mintSoft,
              backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty ? NetworkImage(pet.photoUrl!) : null,
              child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                  ? Icon(Icons.pets_rounded, color: ClientPastelColors.mintDeep, size: 28)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              pet.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
