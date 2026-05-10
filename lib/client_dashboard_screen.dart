import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/dashboard/dashboard_section.dart';

/// Home / dashboard principal del cliente en estilo clinico-profesional.
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({
    super.key,
    required this.userName,
    required this.pets,
    this.petsLoading = false,
    this.petsError,
    required this.onRefreshPets,
    required this.onOpenEmergency,
  });

  final String userName;
  final List<ClientPetVm> pets;
  final bool petsLoading;
  final String? petsError;
  final Future<void> Function() onRefreshPets;
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

  List<Map<String, dynamic>> _recentAppointments() {
    final cloned = List<Map<String, dynamic>>.from(_appointmentsRaw);
    cloned.sort((a, b) {
      final ad = DateTime.tryParse(a['scheduled_at']?.toString() ?? '')?.toUtc();
      final bd = DateTime.tryParse(b['scheduled_at']?.toString() ?? '')?.toUtc();
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return cloned.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.68);
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
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              title: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.clienteDashboardSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    title: AppStrings.tusMascotas,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 10,
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
                    child: _buildPetsSection(theme, muted),
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
                    title: AppStrings.clienteSaludTitulo,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 10,
                    child: _buildHealthRemindersSection(theme, muted),
                  )
                      .animate()
                      .fadeIn(delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.clienteActividadTitulo,
                    subtitleColor: muted,
                    bottomSpacing: 16,
                    spacingBeforeChild: 10,
                    child: _buildRecentActivitySection(theme, muted),
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

  Widget _buildHealthRemindersSection(ThemeData theme, Color muted) {
    final upcoming = _upcomingAppointments();
    final reminders = <_HealthReminderModel>[];

    if (widget.pets.isEmpty) {
      reminders.add(
        _HealthReminderModel(
          icon: Icons.pets_outlined,
          text: AppStrings.clienteRecordatorioSinMascotas,
        ),
      );
    }

    if (upcoming.isEmpty) {
      reminders.add(
        _HealthReminderModel(
          icon: Icons.calendar_month_outlined,
          text: AppStrings.clienteRecordatorioSinCitas,
        ),
      );
    } else {
      final first = upcoming.first;
      final dt = DateTime.tryParse(first['scheduled_at']?.toString() ?? '')?.toLocal();
      if (dt != null) {
        final pretty =
            '${DateFormat('d MMM', 'es').format(dt)} a las ${DateFormat.Hm('es').format(dt)}';
        reminders.add(
          _HealthReminderModel(
            icon: Icons.health_and_safety_outlined,
            text: AppStrings.clienteRecordatorioConCita(pretty),
          ),
        );
      }
    }

    if (reminders.isEmpty) {
      reminders.add(
        _HealthReminderModel(
          icon: Icons.check_circle_outline_rounded,
          text: AppStrings.recordatoriosCuerpo,
        ),
      );
    }

    return _animatedSectionState(
      stateKey: 'health_${reminders.length}_${widget.pets.length}_${upcoming.length}',
      child: ClientSoftCard(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < reminders.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _HealthReminderTile(reminder: reminders[i], muted: muted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(ThemeData theme, Color muted) {
    final String stateKey;
    final Widget content;

    if (_apptLoading && _appointmentsRaw.isEmpty) {
      stateKey = 'activity_loading';
      content = const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      final recent = _recentAppointments();
      if (recent.isEmpty) {
        stateKey = 'activity_empty';
        content = ClientSoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            AppStrings.clienteActividadVacia,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
          ),
        );
      } else {
        stateKey = 'activity_list_${recent.length}';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < recent.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RecentActivityTile(row: recent[i], muted: muted),
            ],
          ],
        );
      }
    }

    return _animatedSectionState(
      stateKey: stateKey,
      child: content,
    );
  }

  Widget _buildClientAppointmentsSection(ThemeData theme, Color muted) {
    final String stateKey;
    final Widget content;

    if (_apptLoading && _appointmentsRaw.isEmpty) {
      stateKey = 'appointments_loading';
      content = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_apptError != null) {
      stateKey = 'appointments_error';
      content = ClientSoftCard(
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
    } else {
      final upcoming = _upcomingAppointments();
      if (upcoming.isEmpty) {
        stateKey = 'appointments_empty';
        content = ClientSoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            AppStrings.clienteSinCitasProgramadas,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted, height: 1.35),
          ),
        );
      } else {
        stateKey = 'appointments_list_${upcoming.length}';
        content = Column(
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

    return _animatedSectionState(
      stateKey: stateKey,
      child: content,
    );
  }

  Widget _buildPetsSection(ThemeData theme, Color muted) {
    final String stateKey;
    final Widget content;

    if (widget.petsLoading && widget.pets.isEmpty) {
      stateKey = 'pets_loading';
      content = const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (widget.pets.isEmpty) {
      stateKey = 'pets_empty';
      content = SizedBox(
        height: 160,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppStrings.carouselSinMascotas,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      );
    } else {
      stateKey = 'pets_list_${widget.pets.length}';
      content = SizedBox(
        height: 160,
        child: ListView.separated(
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
      );
    }

    return _animatedSectionState(
      stateKey: stateKey,
      child: content,
    );
  }

  Widget _animatedSectionState({required String stateKey, required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(stateKey),
        child: child,
      ),
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
    final scheme = theme.colorScheme;
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
              Icon(Icons.medical_information_outlined, size: 18, color: scheme.primary),
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
    final scheme = theme.colorScheme;
    final secondary = pet.ageLabel.isNotEmpty ? pet.ageLabel : pet.speciesLabel;

    return SizedBox(
      width: 148,
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
              backgroundColor: scheme.primaryContainer,
              backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty ? NetworkImage(pet.photoUrl!) : null,
              child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                  ? Icon(Icons.pets_rounded, color: scheme.primary, size: 28)
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
            const SizedBox(height: 5),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _HealthReminderModel {
  const _HealthReminderModel({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _HealthReminderTile extends StatelessWidget {
  const _HealthReminderTile({required this.reminder, required this.muted});

  final _HealthReminderModel reminder;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(reminder.icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            reminder.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.row, required this.muted});

  final Map<String, dynamic> row;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final scheduledRaw = row['scheduled_at']?.toString();
    final dt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw)?.toLocal() : null;
    final whenLabel = dt != null
        ? '${DateFormat('d MMM yyyy', 'es').format(dt)} \u00B7 ${DateFormat.Hm('es').format(dt)}'
        : '\u2014';

    final petMap = row['pet'] is Map<String, dynamic> ? row['pet'] as Map<String, dynamic> : {};
    final petName = petMap['name']?.toString().trim().isNotEmpty == true
        ? petMap['name']!.toString().trim()
        : AppStrings.vetMascota;

    final status = row['status']?.toString().trim();
    final statusLabel = status == null || status.isEmpty ? 'pendiente' : status;

    return ClientSoftCard(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  whenLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estado: $statusLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
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
