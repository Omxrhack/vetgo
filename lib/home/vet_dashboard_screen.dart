import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../core/network/vetgo_api_client.dart';
import '../theme/vet_operator_colors.dart';
import '../widgets/vet/vet_async_toggle.dart';
import '../widgets/vet/vet_section_title.dart';
import '../widgets/vet/vet_soft_card.dart';
import '../vet_patient_record_screen.dart';

typedef VetBaseCallback = void Function(double? lat, double? lng);

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({
    super.key,
    required this.api,
    required this.profileName,
    required this.onLogout,
    this.onVetBaseResolved,
  });

  final VetgoApiClient api;
  final String profileName;
  final VoidCallback onLogout;
  final VetBaseCallback? onVetBaseResolved;

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
    final (data, err) = await widget.api.patchVetAvailability(onDuty: available);
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
    final greetingName = widget.profileName.trim().isEmpty ? 'Doctor(a)' : widget.profileName.trim();
    final dateLine = DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());

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
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout_rounded),
                onPressed: widget.onLogout,
              ),
            ],
            expandedHeight: 132,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
              title: Text(
                'Hola, Dr. $greetingName',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 52),
                  child: Text(
                    dateLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w500,
                    ),
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
                    ? SizedBox(
                        key: const ValueKey<String>('loading'),
                        height: 220,
                        child: Center(child: CircularProgressIndicator(color: scheme.primary)),
                      )
                    : _error != null
                        ? Text(
                            key: const ValueKey<String>('err'),
                            _error!,
                            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
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
    final earnings = (dash['earnings_mxn_today'] as num?)?.toDouble() ?? 0;
    final visits = dash['visits'] is List ? dash['visits'] as List<dynamic> : const [];

    return Column(
      key: const ValueKey<String>('content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dutyError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _dutyError!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        VetDutyToggleCard(
          available: onDuty,
          busy: _dutyBusy,
          onChanged: _onDutyChanged,
        ),
        const SizedBox(height: 22),
        const VetSectionTitle(title: 'Resumen de hoy'),
        Row(
          children: [
            Expanded(
              child: VetSoftCard(
                color: VetOperatorColors.mintSoft.withValues(alpha: 0.45),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Citas pendientes',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Text(
                        '$pending',
                        key: ValueKey<int>(pending),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: VetSoftCard(
                color: VetOperatorColors.amberSoft.withValues(alpha: 0.55),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganancias (MXN)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        earnings.toStringAsFixed(0),
                        key: ValueKey<double>(earnings),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const VetSectionTitle(
          title: 'Próximas visitas',
          subtitle: 'Desliza para ver más',
        ),
        SizedBox(
          height: 148,
          child: visits.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No hay visitas asignadas para hoy.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final v = visits[i] is Map<String, dynamic> ? visits[i] as Map<String, dynamic> : {};
                    final timeRaw = v['scheduled_at']?.toString();
                    final dt = timeRaw != null ? DateTime.tryParse(timeRaw)?.toLocal() : null;
                    final timeLabel = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';
                    final pet = v['pet_name']?.toString() ?? 'Mascota';
                    final col = v['neighborhood']?.toString() ?? '';
                    final apptId = v['appointment_id']?.toString();
                    final petId = v['pet_id'];
                    final petIdStr = petId?.toString();

                    return SizedBox(
                      width: 220,
                      child: VetSoftCard(
                        padding: const EdgeInsets.all(16),
                        onTap: apptId != null && petIdStr != null
                            ? () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => VetPatientRecordScreen(petId: petIdStr),
                                  ),
                                );
                              }
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeLabel,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pet,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              col.isEmpty ? 'Dirección pendiente' : col,
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}
