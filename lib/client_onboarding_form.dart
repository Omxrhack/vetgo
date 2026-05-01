import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vetgo/auth/widgets/auth_screen_shell.dart';
import 'package:vetgo/auth/widgets/onboarding_profile_photo_field.dart';
import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/location/onboarding_location_fill.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Formulario alineado con `clientOnboardingSchema` del backend.
class ClientOnboardingForm extends StatefulWidget {
  const ClientOnboardingForm({
    super.key,
    required this.loading,
    required this.onSubmit,
  });

  final bool loading;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  ClientOnboardingFormState createState() => ClientOnboardingFormState();
}

class ClientOnboardingFormState extends State<ClientOnboardingForm> {
  final _pageController = PageController();
  int _step = 0;

  final _stepKeys = List<GlobalKey<FormState>>.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _addressNotes = TextEditingController();
  final _petName = TextEditingController();
  final _species = TextEditingController();
  final _breed = TextEditingController();
  final _medicalNotes = TextEditingController();
  final _weightText = TextEditingController();

  String _sex = 'male';
  DateTime? _birthDate;
  bool _neutered = false;
  String _vaccines = 'unsure';
  String _temperament = 'friendly';

  String? _profileAvatarUrl;

  double? _pickedLatitude;
  double? _pickedLongitude;
  bool _locationBusy = false;

  @override
  void initState() {
    super.initState();
    AuthStorage.loadSession().then((s) {
      if (!mounted) return;
      final u = s?.profile?['avatar_url']?.toString().trim();
      if (u != null && u.isNotEmpty) {
        setState(() => _profileAvatarUrl = u);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullName.dispose();
    _phone.dispose();
    _address.dispose();
    _addressNotes.dispose();
    _petName.dispose();
    _species.dispose();
    _breed.dispose();
    _medicalNotes.dispose();
    _weightText.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final body = <String, dynamic>{
      'role': 'client',
      'full_name': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'avatar_url': _profileAvatarUrl?.trim() ?? '',
      'client_details': <String, dynamic>{
        'address_text': _address.text.trim(),
        'address_notes': _addressNotes.text.trim(),
        'latitude': _pickedLatitude,
        'longitude': _pickedLongitude,
      },
      'pet_profile': <String, dynamic>{
        'name': _petName.text.trim(),
        'species': _species.text.trim(),
        'breed': _breed.text.trim(),
        'sex': _sex,
        'is_neutered': _neutered,
        'vaccines_up_to_date': _vaccines,
        'temperament': _temperament,
      },
    };

    if (_birthDate != null) {
      final d = _birthDate!;
      (body['pet_profile'] as Map<String, dynamic>)['birth_date'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    final w = double.tryParse(_weightText.text.replaceAll(',', '.'));
    if (w != null && w > 0) {
      (body['pet_profile'] as Map<String, dynamic>)['weight_kg'] = w;
    }
    if (_medicalNotes.text.trim().isNotEmpty) {
      (body['pet_profile'] as Map<String, dynamic>)['medical_notes'] =
          _medicalNotes.text.trim();
    }

    return body;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 2),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (d != null) setState(() => _birthDate = d);
  }

  bool _validateStep(int index) {
    return _stepKeys[index].currentState?.validate() ?? false;
  }

  Future<void> _goToStep(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() => _step = index);
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;
    if (_step < 3) {
      await _goToStep(_step + 1);
      return;
    }
    await widget.onSubmit(_buildPayload());
  }

  Future<void> _useMyLocationForAddress() async {
    setState(() => _locationBusy = true);
    final result = await loadAddressFromDeviceLocation();
    if (!mounted) return;
    setState(() => _locationBusy = false);
    if (!result.ok) {
      VetgoNotice.show(context, message: result.errorMessage ?? 'Error', isError: true);
      return;
    }
    setState(() {
      _address.text = result.addressText ?? '';
      _pickedLatitude = result.latitude;
      _pickedLongitude = result.longitude;
    });
    VetgoNotice.show(context, message: AppStrings.onboardingUbicacionAplicada);
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _goToStep(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (_step) {
      0 => 'Datos personales',
      1 => 'Ubicación',
      2 => 'Perfil de mascota',
      _ => 'Salud y comportamiento',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PASO ${_step + 1} DE 4',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            minHeight: 6,
            backgroundColor: scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Form(
                key: _stepKeys[0],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'TUS DATOS',
                      title: 'Sobre ti',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _fullName,
                      textCapitalization: TextCapitalization.words,
                      decoration: authInputDecoration(context, label: 'Nombre completo'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: authInputDecoration(
                        context,
                        label: 'Teléfono',
                        hintText: '+521234567890',
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Requerido';
                        if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(s)) {
                          return 'Teléfono no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    OnboardingProfilePhotoField(
                      imageUrl: _profileAvatarUrl,
                      allowClear: true,
                      busy: widget.loading,
                      onUrlChanged: (url) => setState(() => _profileAvatarUrl = url),
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[1],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'DIRECCIÓN',
                      title: 'Dónde te encontramos',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: widget.loading || _locationBusy ? null : _useMyLocationForAddress,
                      icon: _locationBusy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(AppStrings.onboardingUsarUbicacion),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: authInputDecoration(
                        context,
                        label: 'Dirección completa',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 5) ? 'Mínimo 5 caracteres' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressNotes,
                      decoration: authInputDecoration(
                        context,
                        label: 'Referencias (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[2],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'MASCOTA',
                      title: 'Perfil de mascota',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _petName,
                      textCapitalization: TextCapitalization.words,
                      decoration: authInputDecoration(context, label: 'Nombre de la mascota'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _species,
                      textCapitalization: TextCapitalization.words,
                      decoration: authInputDecoration(
                        context,
                        label: 'Especie',
                        hintText: 'Perro, gato...',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breed,
                      decoration: authInputDecoration(context, label: 'Raza (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sex,
                      decoration: authInputDecoration(context, label: 'Sexo'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Macho')),
                        DropdownMenuItem(value: 'female', child: Text('Hembra')),
                      ],
                      onChanged: (v) => setState(() => _sex = v ?? 'male'),
                    ),
                    const SizedBox(height: 12),
                    AuthOutlinedTile(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          _birthDate == null
                              ? 'Fecha de nacimiento (opcional)'
                              : 'Nacimiento: ${_birthDate!.toString().split(' ').first}',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: _birthDate == null ? 0.7 : 0.95),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.calendar_today_rounded,
                          color: scheme.primary,
                          size: 20,
                        ),
                        onTap: _pickBirthDate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _weightText,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: authInputDecoration(
                        context,
                        label: 'Peso kg (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[3],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'SALUD',
                      title: 'Salud y comportamiento',
                    ),
                    const SizedBox(height: 14),
                    AuthOutlinedTile(
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: const Text('Castrado / esterilizado'),
                        value: _neutered,
                        onChanged: (v) => setState(() => _neutered = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _vaccines,
                      decoration: authInputDecoration(context, label: 'Vacunas al día'),
                      items: const [
                        DropdownMenuItem(value: 'yes', child: Text('Sí')),
                        DropdownMenuItem(value: 'no', child: Text('No')),
                        DropdownMenuItem(value: 'unsure', child: Text('No estoy seguro')),
                      ],
                      onChanged: (v) => setState(() => _vaccines = v ?? 'unsure'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _temperament,
                      decoration: authInputDecoration(context, label: 'Temperamento'),
                      items: const [
                        DropdownMenuItem(value: 'friendly', child: Text('Amistoso')),
                        DropdownMenuItem(value: 'nervous', child: Text('Nervioso')),
                        DropdownMenuItem(value: 'aggressive', child: Text('Agresivo')),
                      ],
                      onChanged: (v) => setState(() => _temperament = v ?? 'friendly'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicalNotes,
                      maxLines: 3,
                      decoration: authInputDecoration(
                        context,
                        label: 'Notas médicas (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.loading ? null : _back,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: widget.loading ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: widget.loading && _step == 3
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 3 ? 'Guardar y continuar' : 'Continuar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
