import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:vetgo/client/choose_vet_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/location/onboarding_location_fill.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/core/storage/preferred_vet_prefs.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/simple_osm_map.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

final LatLng _fallbackVisitMapCenter = LatLng(19.4326, -99.1332);
const List<String> _appointmentTypes = <String>[
  'Consulta general',
  'Vacunación',
  'Seguimiento',
  'Dental',
  'Dermatología',
  'Nutrición',
  'Esterilización',
  'Otro',
];

/// Flujo para agendar visita: mascota, fecha/hora/ubicación en mapa, confirmación y API.
class ScheduleVisitFlowScreen extends StatefulWidget {
  const ScheduleVisitFlowScreen({super.key, required this.pets});

  final List<ClientPetVm> pets;

  @override
  State<ScheduleVisitFlowScreen> createState() =>
      _ScheduleVisitFlowScreenState();
}

class _ScheduleVisitFlowScreenState extends State<ScheduleVisitFlowScreen> {
  final PageController _page = PageController();
  final VetgoApiClient _api = VetgoApiClient();
  final TextEditingController _reason = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  int _step = 0;
  ClientPetVm? _pet;
  String _appointmentType = _appointmentTypes.first;
  DateTime? _visitDate;
  TimeOfDay? _visitTime;
  String? _preferredVetName;
  String? _visitAddressText;

  LatLng _visitLocation = _fallbackVisitMapCenter;
  bool _triedLocation = false;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.pets.isNotEmpty) {
      _pet = widget.pets.first;
    }
    _refreshPreferredVet();
  }

  Future<void> _refreshPreferredVet() async {
    final name = await PreferredVetPrefs.readDisplayName();
    if (mounted) setState(() => _preferredVetName = name);
  }

  @override
  void dispose() {
    _page.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _ensureVisitDefaults() {
    final base = DateTime.now().add(const Duration(days: 1));
    _visitDate ??= DateTime(base.year, base.month, base.day);
    _visitTime ??= const TimeOfDay(hour: 10, minute: 0);
  }

  DateTime _combinedLocalDateTime() {
    _ensureVisitDefaults();
    final d = _visitDate!;
    final t = _visitTime!;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool _visitDateTimeIsFuture() {
    return _combinedLocalDateTime().isAfter(DateTime.now());
  }

  Future<void> _tryLoadVisitLocation({bool showNotice = false}) async {
    if (_triedLocation) return;
    _triedLocation = true;
    await _loadVisitAddress(showNotice: showNotice);
  }

  Future<void> _loadVisitAddress({bool showNotice = true}) async {
    if (_loadingAddress) return;
    setState(() => _loadingAddress = true);
    try {
      final result = await loadAddressFromDeviceLocation();
      if (!mounted) {
        return;
      }
      if (!result.ok ||
          result.latitude == null ||
          result.longitude == null ||
          result.addressText == null) {
        if (showNotice) {
          VetgoNotice.show(
            context,
            message: result.errorMessage ?? 'No se pudo obtener el domicilio.',
            isError: true,
          );
        }
        return;
      }
      setState(() {
        _visitLocation = LatLng(result.latitude!, result.longitude!);
        _visitAddressText = result.addressText!.trim();
      });
      if (showNotice) {
        VetgoNotice.show(context, message: 'Domicilio obtenido.');
      }
    } catch (_) {
      if (mounted && showNotice) {
        VetgoNotice.show(
          context,
          message: 'No se pudo obtener el domicilio. Intenta de nuevo.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAddress = false);
      }
    }
  }

  Future<void> _pickDate() async {
    _ensureVisitDefaults();
    final now = DateTime.now();
    final last = now.add(const Duration(days: 365));
    final d = await showDatePicker(
      context: context,
      initialDate: _visitDate!,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: last,
    );
    if (d != null) {
      setState(() => _visitDate = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _pickTime() async {
    _ensureVisitDefaults();
    final t = await showTimePicker(context: context, initialTime: _visitTime!);
    if (t != null) setState(() => _visitTime = t);
  }

  bool _canAdvanceFromPetStep() {
    if (widget.pets.isEmpty) return false;
    return _pet != null;
  }

  bool _canAdvanceFromReasonStep() {
    return _appointmentType.isNotEmpty && _reason.text.trim().isNotEmpty;
  }

  void _next() {
    if (_step == 1 && !_canAdvanceFromPetStep()) return;
    if (_step == 2 && !_canAdvanceFromReasonStep()) {
      VetgoNotice.show(
        context,
        message: 'Cuéntanos el motivo de la cita programada.',
        isError: true,
      );
      return;
    }
    if (_step == 3) {
      _ensureVisitDefaults();
      if (!_visitDateTimeIsFuture()) {
        VetgoNotice.show(
          context,
          message: AppStrings.scheduleFechaPasada,
          isError: true,
        );
        return;
      }
    }
    if (_step < 4) {
      final nextStep = _step + 1;
      setState(() => _step = nextStep);
      _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      if (nextStep == 3) {
        _ensureVisitDefaults();
        _tryLoadVisitLocation();
      }
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _page.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formattedVisitSummary() {
    final dt = _combinedLocalDateTime();
    final datePart = DateFormat('EEEE d MMM y', 'es').format(dt);
    final timePart = DateFormat.Hm('es').format(dt);
    return '$datePart · $timePart';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.schedulePasoNDeM(_step + 1, 5)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: List.generate(5, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: active
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepIntro(context),
                _stepPet(context),
                _stepReason(context),
                _stepWhenWhere(context),
                _stepConfirm(context),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _back,
                      child: Text(AppStrings.scheduleAtras),
                    ),
                  const Spacer(),
                  if (_step < 4)
                    FilledButton(
                      onPressed: _step == 0
                          ? _next
                          : _step == 1
                          ? (_canAdvanceFromPetStep() ? _next : null)
                          : _step == 2
                          ? (_canAdvanceFromReasonStep() ? _next : null)
                          : _step == 3
                          ? _next
                          : null,
                      child: Text(
                        _step == 0
                            ? AppStrings.scheduleContinuar
                            : AppStrings.scheduleSiguiente,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepReason(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = ClientPastelColors.mutedOn(context);

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          '¿Qué tipo de cita quieres agendar?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto ayuda al veterinario a prepararse. Para síntomas graves usa SOS.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: muted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _appointmentTypes)
              ChoiceChip(
                label: Text(type),
                selected: _appointmentType == type,
                onSelected: (_) => setState(() => _appointmentType = type),
                selectedColor: scheme.primaryContainer,
              ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _reason,
          onChanged: (_) => setState(() {}),
          maxLength: 160,
          decoration: InputDecoration(
            labelText: 'Motivo de la visita',
            hintText: 'Ej. refuerzo de vacuna, control dental, seguimiento...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _stepIntro(BuildContext context) {
    final muted = ClientPastelColors.mutedOn(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ClientSoftCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.scheduleAgendarVisitaTitulo,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.scheduleIntroBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepPet(BuildContext context) {
    if (widget.pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.scheduleSinMascotas,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          AppStrings.schedulePasoMascotaTitulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...widget.pets.map(
          (ClientPetVm p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _pet = p),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _pet?.id == p.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${p.speciesLabel} \u00B7 ${p.breedLabel}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ClientPastelColors.mutedOn(context),
                                  ),
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
        ),
      ],
    );
  }

  Widget _stepWhenWhere(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = ClientPastelColors.mutedOn(context);
    _ensureVisitDefaults();

    final timeDisplay = DateFormat.Hm(
      'es',
    ).format(DateTime(1970, 1, 1, _visitTime!.hour, _visitTime!.minute));

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          AppStrings.scheduleCuandoUbicacionTitulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.scheduleMapaHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(DateFormat.yMMMd('es').format(_visitDate!)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(timeDisplay),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SimpleOsmMap(
          center: _visitLocation,
          height: 220,
          zoom: 15,
          markerColor: scheme.primary,
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.mapaOsmAtribucion,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loadingAddress ? null : () => _loadVisitAddress(),
          icon: _loadingAddress
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(
            _loadingAddress ? 'Obteniendo domicilio...' : 'Obtener domicilio',
          ),
        ),
        if (_visitAddressText != null && _visitAddressText!.isNotEmpty) ...[
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.home_outlined, size: 19, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _visitAddressText!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: _notes,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: AppStrings.scheduleNotasOpcional,
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _stepConfirm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    _ensureVisitDefaults();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ClientSoftCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.scheduleConfirmacionTitulo,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${AppStrings.scheduleResumenMascota} ${_pet?.name ?? '\u2014'}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: $_appointmentType',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: ${_reason.text.trim()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.scheduleResumenCuando} ${_formattedVisitSummary()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            if (_visitAddressText != null && _visitAddressText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Domicilio: $_visitAddressText',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ClientPastelColors.mutedOn(context),
                  height: 1.35,
                ),
              ),
            ],
            if (_notes.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.scheduleResumenNotas} ${_notes.text.trim()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ClientPastelColors.mutedOn(context),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _preferredVetName != null && _preferredVetName!.isNotEmpty
                  ? AppStrings.scheduleVetLinePref(_preferredVetName!)
                  : AppStrings.scheduleVetLineAuto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ClientPastelColors.mutedOn(context),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const ChooseVetScreen(),
                    ),
                  );
                  await _refreshPreferredVet();
                },
                child: const Text(AppStrings.scheduleVetElegir),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: SimpleOsmMap(
                  center: _visitLocation,
                  height: 120,
                  zoom: 14,
                  markerColor: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AsyncEndpointButton(
              label: AppStrings.scheduleEnviarSolicitud,
              icon: Icons.check_rounded,
              loadingLabel: AppStrings.scheduleEnviando,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
              onPressed: _pet == null
                  ? null
                  : () async {
                      final at = _combinedLocalDateTime().toUtc();
                      final vetId = await PreferredVetPrefs.readId();
                      final notes = _notes.text.trim();
                      final reason = _reason.text.trim();
                      final (data, err) = await _api.createAppointment(
                        petId: _pet!.id,
                        scheduledAtIso: at.toIso8601String(),
                        appointmentType: _appointmentType,
                        reason: reason.isEmpty ? null : reason,
                        vetId: vetId,
                        notes: notes.isEmpty ? null : notes,
                        visitLatitude: _visitLocation.latitude,
                        visitLongitude: _visitLocation.longitude,
                        visitAddressText: _visitAddressText,
                      );
                      if (!context.mounted) return;
                      if (err != null) {
                        VetgoNotice.show(context, message: err, isError: true);
                        return;
                      }
                      final id = data?['id']?.toString() ?? '';
                      VetgoNotice.show(
                        context,
                        message: id.isNotEmpty
                            ? AppStrings.scheduleCitaRegistrada(id)
                            : AppStrings.scheduleCitaOkSinRef,
                      );
                      Navigator.of(context).pop(true);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
