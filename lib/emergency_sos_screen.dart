import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';

import 'package:vetgo/client/choose_vet_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/core/storage/preferred_vet_prefs.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// SOS Emergencia 24/7: envia `POST /api/emergencies` con ubicacion y mascota.
class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key, required this.pets});

  final List<ClientPetVm> pets;

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  bool _searching = false;

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

  Future<void> _submitEmergency({required String defaultSymptoms}) async {
    if (widget.pets.isEmpty || _selectedPet == null) {
      if (!mounted) return;
      VetgoNotice.show(context, message: AppStrings.emergencyRegistraMascota, isError: true);
      return;
    }

    final detail = _symptoms.text.trim();
    final symptoms = detail.isNotEmpty ? detail : defaultSymptoms;

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
    VetgoNotice.show(
      context,
      message: id.isNotEmpty ? AppStrings.emergencyRegistradaRef(id) : AppStrings.emergencyRegistrada,
    );
  }

  Future<void> _onSosPressed() async {
    setState(() => _searching = true);
    await _submitEmergency(defaultSymptoms: AppStrings.emergencyDefaultSosBoton);
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ClientPastelColors.skySoft.withValues(alpha: 0.55),
              ClientPastelColors.peachSoft.withValues(alpha: 0.85),
              ClientPastelColors.amberSoft.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.emergencyTitulo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.emergencySubtitulo,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: ClientPastelColors.mutedOn(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  _preferredVetName != null && _preferredVetName!.isNotEmpty
                      ? AppStrings.emergencyVetLinePref(_preferredVetName!)
                      : AppStrings.emergencyVetLineAuto,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ClientPastelColors.mutedOn(context),
                    height: 1.35,
                  ),
                ),
                TextButton(
                  onPressed: _searching
                      ? null
                      : () async {
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) => const ChooseVetScreen(),
                            ),
                          );
                          await _refreshPreferredVet();
                        },
                  child: const Text(AppStrings.emergencyVetElegir),
                ),
                const SizedBox(height: 24),
                Center(
                  child: AnimatedScale(
                    scale: _searching ? 0.94 : 1,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _searching || widget.pets.isEmpty ? null : _onSosPressed,
                        child: Ink(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                ClientPastelColors.coralSoft.withValues(alpha: 0.92),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.error.withValues(alpha: 0.22),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _searching
                                ? Column(
                                    key: const ValueKey<String>('load'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: theme.colorScheme.error.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          AppStrings.emergencyEnviandoAlerta,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey<String>('idle'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.sos_rounded, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.88)),
                                      const SizedBox(height: 10),
                                      Text(
                                        AppStrings.emergencySolicitarAyuda,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 40),
                Text(
                  AppStrings.emergencyDetalleRapido,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClientSoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.pets.isEmpty)
                        Text(
                          AppStrings.emergencySinMascotas,
                          style: theme.textTheme.bodyMedium?.copyWith(color: ClientPastelColors.mutedOn(context)),
                        )
                      else
                        DropdownButtonFormField<ClientPetVm>(
                          // ignore: deprecated_member_use
                          value: _selectedPet,
                          decoration: const InputDecoration(
                            labelText: AppStrings.emergencyLabelMascota,
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
                          ),
                          items: widget.pets
                              .map(
                                (ClientPetVm p) => DropdownMenuItem(value: p, child: Text(p.name)),
                              )
                              .toList(),
                          onChanged: _searching
                              ? null
                              : (v) {
                                  if (v != null) setState(() => _selectedPet = v);
                                },
                        ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _symptoms,
                        enabled: !_searching,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: AppStrings.emergencyLabelSintomas,
                          alignLabelWithHint: true,
                          hintText: AppStrings.emergencyHintSintomas,
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AsyncEndpointButton(
                        label: AppStrings.emergencyEnviarSos,
                        icon: Icons.send_rounded,
                        loadingLabel: AppStrings.emergencyEnviando,
                        style: FilledButton.styleFrom(
                          backgroundColor: ClientPastelColors.mintDeep,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: widget.pets.isEmpty || _searching
                            ? null
                            : () async {
                                await _submitEmergency(defaultSymptoms: AppStrings.emergencyDefaultSosForm);
                              },
                      ),
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
