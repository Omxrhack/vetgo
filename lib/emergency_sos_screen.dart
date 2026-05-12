import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:vetgo/client/choose_vet_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/core/storage/preferred_vet_prefs.dart';
import 'package:vetgo/live_tracking_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// SOS Emergencia 24/7: envía `POST /api/emergencies` con ubicación y mascota.
///
/// Un solo envío desde el CTA principal: si hay texto en síntomas se usa; si no,
/// [AppStrings.emergencyDefaultSosBoton] (un solo endpoint; evita duplicar envíos).
class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key, required this.pets});

  final List<ClientPetVm> pets;

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  bool _searching = false;
  bool _createdEmergency = false;

  ClientPetVm? _selectedPet;
  final TextEditingController _symptoms = TextEditingController();
  String? _preferredVetName;

  @override
  void initState() {
    super.initState();
    if (widget.pets.isNotEmpty) {
      _selectedPet = widget.pets.first;
    }
    _refreshPreferredVet();
  }

  Future<void> _refreshPreferredVet() async {
    final name = await PreferredVetPrefs.readDisplayName();
    if (mounted) setState(() => _preferredVetName = name);
  }

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<(double lat, double lng, String? error)> _resolveLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return (0.0, 0.0, AppStrings.emergencyNecesitaUbicacion);
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (pos.latitude, pos.longitude, null);
  }

  Future<void> _submitEmergency() async {
    if (widget.pets.isEmpty || _selectedPet == null) {
      if (!mounted) return;
      VetgoNotice.show(
        context,
        message: AppStrings.emergencyRegistraMascota,
        isError: true,
      );
      return;
    }

    final detail = _symptoms.text.trim();
    final symptoms = detail.isNotEmpty
        ? detail
        : AppStrings.emergencyDefaultSosBoton;

    final (lat, lng, locErr) = await _resolveLocation();
    if (locErr != null) {
      if (!mounted) return;
      VetgoNotice.show(context, message: locErr, isError: true);
      return;
    }

    final prefId = await PreferredVetPrefs.readId();

    final (data, err) = await _api.createEmergency(
      petId: _selectedPet!.id,
      symptoms: symptoms,
      latitude: lat,
      longitude: lng,
      preferredVetId: prefId,
    );

    if (!mounted) return;

    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }

    final id = data?['id']?.toString() ?? '';
    _createdEmergency = true;
    VetgoNotice.show(
      context,
      message: id.isNotEmpty
          ? AppStrings.emergencyRegistradaRef(id)
          : AppStrings.emergencyRegistrada,
    );
    if (id.isNotEmpty) {
      await _showEmergencyFollowup(id, data);
    }
  }

  Future<void> _showEmergencyFollowup(
    String emergencyId,
    Map<String, dynamic>? data,
  ) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final assigned = data?['assigned_vet_id']?.toString();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Emergencia enviada',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  assigned != null && assigned.isNotEmpty
                      ? 'Ya hay un veterinario asignado. Cuando inicie ruta podrás rastrearlo aquí.'
                      : 'Estamos buscando un veterinario disponible. Mantén la app abierta.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _openEmergencyTracking(emergencyId);
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver estado o rastrear'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEmergencyTracking(String emergencyId) async {
    final (data, err) = await _api.listActiveTrackingSessions();
    if (!mounted) return;
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    final sessions = data?['sessions'];
    Map<String, dynamic>? match;
    if (sessions is List) {
      for (final item in sessions.whereType<Map<String, dynamic>>()) {
        if (item['emergency_id']?.toString() == emergencyId) {
          match = item;
          break;
        }
      }
    }
    final sessionId = match?['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      VetgoNotice.show(
        context,
        message:
            'El veterinario aún no inicia ruta. Intenta de nuevo en unos segundos.',
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveTrackingScreen(
          trackingSessionId: sessionId,
          vetName: 'Veterinario en camino',
          etaLabel: _etaLabel(match),
        ),
      ),
    );
  }

  String _etaLabel(Map<String, dynamic>? session) {
    final raw = session?['eta_minutes'];
    final minutes = raw is num
        ? raw.round()
        : int.tryParse(raw?.toString() ?? '');
    return minutes == null ? 'ETA pendiente' : '$minutes min';
  }

  void _popWithResult() {
    Navigator.of(context).pop(_createdEmergency);
  }

  Future<void> _onSosPressed() async {
    if (_searching) return;
    setState(() => _searching = true);
    await _submitEmergency();
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _openChooseVet() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ChooseVetScreen()),
    );
    await _refreshPreferredVet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: scheme.surfaceTint.withValues(alpha: 0.35),
          foregroundColor: scheme.onSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithResult,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.emergencyTitulo,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.emergencySubtitulo,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PreferredVetRow(
                  preferredName: _preferredVetName,
                  searching: _searching,
                  onChooseVet: _openChooseVet,
                ),
                const SizedBox(height: 18),
                _PrimarySosButton(
                  loading: _searching,
                  hasPets: widget.pets.isNotEmpty,
                  onPressed: _onSosPressed,
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.emergencyUbicacionNota,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppStrings.emergencyDetalleRapido,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ClientSoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.pets.isEmpty)
                        Column(
                          children: [
                            Icon(
                              Icons.pets_outlined,
                              size: 40,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppStrings.emergencySinMascotas,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ClientPastelColors.mutedOn(context),
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        DropdownButtonFormField<ClientPetVm>(
                          // ignore: deprecated_member_use
                          value: _selectedPet,
                          decoration: InputDecoration(
                            labelText: AppStrings.emergencyLabelMascota,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            filled: true,
                            fillColor: scheme.surface,
                          ),
                          items: widget.pets
                              .map(
                                (ClientPetVm p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: _searching
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() => _selectedPet = v);
                                  }
                                },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _symptoms,
                          enabled: !_searching,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: AppStrings.emergencyLabelSintomas,
                            alignLabelWithHint: true,
                            hintText: AppStrings.emergencyHintSintomas,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            filled: true,
                            fillColor: scheme.surface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferredVetRow extends StatelessWidget {
  const _PreferredVetRow({
    required this.preferredName,
    required this.searching,
    required this.onChooseVet,
  });

  final String? preferredName;
  final bool searching;
  final VoidCallback onChooseVet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final line = preferredName != null && preferredName!.isNotEmpty
        ? AppStrings.emergencyVetLinePref(preferredName!)
        : AppStrings.emergencyVetLineAuto;

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 22,
              color: scheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                line,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.3,
                ),
              ),
            ),
            TextButton(
              onPressed: searching ? null : onChooseVet,
              child: const Text(AppStrings.emergencyVetElegir),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimarySosButton extends StatelessWidget {
  const _PrimarySosButton({
    required this.loading,
    required this.hasPets,
    required this.onPressed,
  });

  final bool loading;
  final bool hasPets;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return FilledButton(
      onPressed: !hasPets
          ? null
          : () {
              if (loading) return;
              onPressed();
            },
      style: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
        minimumSize: const Size(double.infinity, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onError,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sos_rounded, size: 26, color: scheme.onError),
                const SizedBox(width: 10),
                Text(
                  AppStrings.emergencyCtaPrincipal,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onError,
                  ),
                ),
              ],
            ),
    );
  }
}
