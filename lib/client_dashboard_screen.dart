import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/vet_profile_screen.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/dashboard/activity_timeline_tile.dart';
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

  Map<String, dynamic>? _assignedVet;
  bool _vetLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadAssignedVet();
  }

  Future<void> _loadAssignedVet() async {
    final (data, _) = await _api.getMyVet();
    if (!mounted) return;
    setState(() {
      _assignedVet = data?['vet'] is Map<String, dynamic>
          ? data!['vet'] as Map<String, dynamic>
          : null;
      _vetLoading = false;
    });
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
      _loadAssignedVet(),
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
            toolbarHeight: 72,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'vetgo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: const Color(0xFF1B8A4E),
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.bell, size: 18),
                color: scheme.onSurfaceVariant,
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_vetLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClientSoftCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 14,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 11,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_assignedVet != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _AssignedVetCard(
                        vet: _assignedVet!,
                        onBookTap: widget.onOpenEmergency,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.03, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Row(
                      children: [
                        _QuickActionChip(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Nueva cita',
                          onTap: widget.onOpenEmergency,
                        ),
                        const SizedBox(width: 10),
                        _QuickActionChip(
                          icon: Icons.history_rounded,
                          label: 'Historial',
                          onTap: () {},
                        ),
                        const SizedBox(width: 10),
                        _QuickActionChip(
                          icon: Icons.map_outlined,
                          label: 'Rastrear',
                          onTap: () {},
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),
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

    final reminder = reminders.first;
    final scheme = theme.colorScheme;

    return _animatedSectionState(
      stateKey: 'health_${reminders.length}_${widget.pets.length}_${upcoming.length}',
      child: ClientSoftCard(
        color: scheme.secondaryContainer.withValues(alpha: 0.32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(reminder.icon, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                reminder.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
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
            for (var i = 0; i < recent.length; i++)
              ActivityTimelineTile(row: recent[i], isLast: i == recent.length - 1),
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
        final first = upcoming.first;
        final rawDt = first['scheduled_at']?.toString();
        final apptDt = rawDt != null ? DateTime.tryParse(rawDt)?.toLocal() : null;
        final dayNum = apptDt != null ? DateFormat('d', 'es').format(apptDt) : '—';
        final monthAbbr = apptDt != null
            ? DateFormat('MMM', 'es').format(apptDt).toUpperCase()
            : '';
        final timeLabel = apptDt != null ? DateFormat('h:mm a', 'es').format(apptDt) : '—';
        final petName = (first['pet'] is Map ? first['pet']['name']?.toString() : null) ??
            AppStrings.vetMascota;
        final vetMap = first['vet'] is Map<String, dynamic>
            ? first['vet'] as Map<String, dynamic>
            : <String, dynamic>{};
        final vetName = vetMap['full_name']?.toString().trim() ?? '';

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card — primera cita
            ClientSoftCard(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthAbbr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        dayNum,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          petName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vetName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            vetName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            // Citas adicionales en scroll horizontal
            if (upcoming.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcoming.length - 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = upcoming[i + 1];
                    final aDt = DateTime.tryParse(
                      a['scheduled_at']?.toString() ?? '',
                    )?.toLocal();
                    final aPet = (a['pet'] is Map
                        ? a['pet']['name']?.toString()
                        : null) ??
                        AppStrings.vetMascota;
                    return ClientSoftCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                aDt != null
                                    ? DateFormat('d MMM · H:mm', 'es')
                                        .format(aDt)
                                    : '—',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                aPet,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
      final upcoming = _upcomingAppointments();
      stateKey = 'pets_list_${widget.pets.length}';
      content = SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.pets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = widget.pets[i];
            final nextAppt = upcoming.where((a) {
              final pid = a['pet'] is Map ? a['pet']['id']?.toString() : null;
              return pid == p.id;
            }).firstOrNull;
            return _PetCarouselTile(
              pet: p,
              nextAppointment: nextAppt,
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


class _AssignedVetCard extends StatelessWidget {
  const _AssignedVetCard({
    required this.vet,
    required this.onBookTap,
  });

  final Map<String, dynamic> vet;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = vet['full_name']?.toString() ?? '';
    final avatarUrl = vet['avatar_url']?.toString();
    final specialty = vet['specialty']?.toString().isNotEmpty == true
        ? vet['specialty'].toString()
        : 'Medicina veterinaria general';
    final since = DateTime.tryParse(vet['relationship_since']?.toString() ?? '');
    final sinceLabel = since != null
        ? 'Cliente desde ${DateFormat('MMMM yyyy', 'es').format(since)}'
        : 'Tu veterinario de confianza';

    return ClientSoftCard(
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VetProfileScreen(
            vetId: vet['id']?.toString() ?? '',
            onBookTap: onBookTap,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: scheme.primaryContainer,
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Icon(Icons.person_rounded, size: 36, color: scheme.primary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu veterinario',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  specialty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, size: 11, color: scheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        sinceLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: scheme.onSurface.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

class _PetCarouselTile extends StatelessWidget {
  const _PetCarouselTile({
    required this.pet,
    required this.onTap,
    this.nextAppointment,
  });

  final ClientPetVm pet;
  final VoidCallback onTap;
  final Map<String, dynamic>? nextAppointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = pet.ageLabel.isNotEmpty ? pet.ageLabel : pet.speciesLabel;

    String? apptChip;
    if (nextAppointment != null) {
      final raw = nextAppointment!['scheduled_at']?.toString();
      final dt = raw != null ? DateTime.tryParse(raw)?.toLocal() : null;
      if (dt != null) apptChip = DateFormat('d MMM', 'es').format(dt);
    }

    return SizedBox(
      width: 172,
      child: ClientSoftCard(
        padding: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 118,
                child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                    ? Image.network(
                        pet.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _petPlaceholder(scheme),
                      )
                    : _petPlaceholder(scheme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (apptChip != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 10, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            apptChip,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petPlaceholder(ColorScheme scheme) => Container(
        color: scheme.primaryContainer,
        child: Center(
          child: Icon(Icons.pets_rounded, color: scheme.primary, size: 40),
        ),
      );
}



class _HealthReminderModel {
  const _HealthReminderModel({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: ClientSoftCard(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 14),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
