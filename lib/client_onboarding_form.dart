import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vetgo/auth/widgets/auth_screen_shell.dart';
import 'package:vetgo/auth/widgets/onboarding_profile_photo_field.dart';
import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/location/onboarding_location_fill.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class ClientOnboardingForm extends StatefulWidget {
  const ClientOnboardingForm({
    super.key,
    required this.loading,
    required this.onSubmit,
  });

  final bool loading;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<ClientOnboardingForm> createState() => ClientOnboardingFormState();
}

class ClientOnboardingFormState extends State<ClientOnboardingForm> {
  static const _totalSteps = 5;

  final _pageController = PageController();
  final _stepKeys = List<GlobalKey<FormState>>.generate(
    _totalSteps,
    (_) => GlobalKey<FormState>(),
  );

  int _step = 0;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _addressNotes = TextEditingController();
  final _defaultContactName = TextEditingController();
  final _defaultContactPhone = TextEditingController();
  final _deliveryNotes = TextEditingController();
  final _petName = TextEditingController();
  final _species = TextEditingController();
  final _breed = TextEditingController();
  final _weightText = TextEditingController();
  final _medicalNotes = TextEditingController();
  final _allergies = TextEditingController();
  final _chronicConditions = TextEditingController();
  final _currentMedications = TextEditingController();
  final _emergencyNotes = TextEditingController();

  String _preferredFulfillment = 'delivery';
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
    AuthStorage.loadSession().then((session) {
      if (!mounted) return;
      final profile = session?.profile;
      final avatar = profile?['avatar_url']?.toString().trim();
      final name = profile?['full_name']?.toString().trim();
      final phone = profile?['phone']?.toString().trim();
      final bio = profile?['bio']?.toString().trim();
      final location = profile?['location']?.toString().trim();
      setState(() {
        if (avatar != null && avatar.isNotEmpty) _profileAvatarUrl = avatar;
        if (name != null && name.isNotEmpty) _fullName.text = name;
        if (phone != null && phone.isNotEmpty) {
          _phone.text = phone;
          _defaultContactPhone.text = phone;
        }
        if (bio != null && bio.isNotEmpty) _bio.text = bio;
        if (location != null && location.isNotEmpty) _location.text = location;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in [
      _fullName,
      _phone,
      _bio,
      _location,
      _address,
      _addressNotes,
      _defaultContactName,
      _defaultContactPhone,
      _deliveryNotes,
      _petName,
      _species,
      _breed,
      _weightText,
      _medicalNotes,
      _allergies,
      _chronicConditions,
      _currentMedications,
      _emergencyNotes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final pet = <String, dynamic>{
      'name': _petName.text.trim(),
      'species': _species.text.trim(),
      'breed': _breed.text.trim(),
      'sex': _sex,
      'is_neutered': _neutered,
      'vaccines_up_to_date': _vaccines,
      'temperament': _temperament,
      'medical_notes': _medicalNotes.text.trim(),
      'allergies': _allergies.text.trim(),
      'chronic_conditions': _chronicConditions.text.trim(),
      'current_medications': _currentMedications.text.trim(),
    };

    if (_birthDate != null) {
      final d = _birthDate!;
      pet['birth_date'] =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    final weight = double.tryParse(_weightText.text.replaceAll(',', '.'));
    if (weight != null && weight > 0) {
      pet['weight_kg'] = weight;
    }

    return <String, dynamic>{
      'role': 'client',
      'full_name': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'avatar_url': _profileAvatarUrl?.trim() ?? '',
      'profile_social': <String, dynamic>{
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
      },
      'client_details': <String, dynamic>{
        'address_text': _address.text.trim(),
        'address_notes': _addressNotes.text.trim(),
        'latitude': _pickedLatitude,
        'longitude': _pickedLongitude,
        'default_contact_name': _defaultContactName.text.trim().isEmpty
            ? _fullName.text.trim()
            : _defaultContactName.text.trim(),
        'default_contact_phone': _defaultContactPhone.text.trim().isEmpty
            ? _phone.text.trim()
            : _defaultContactPhone.text.trim(),
        'preferred_fulfillment_method': _preferredFulfillment,
        'delivery_notes': _deliveryNotes.text.trim(),
        'emergency_notes': _emergencyNotes.text.trim(),
      },
      'pet_profile': pet,
    };
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 2),
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  bool _validateStep(int index) {
    return _stepKeys[index].currentState?.validate() ?? false;
  }

  Future<void> _goToStep(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() => _step = index);
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;
    if (_step < _totalSteps - 1) {
      await _goToStep(_step + 1);
      return;
    }
    await widget.onSubmit(_buildPayload());
  }

  Future<void> _back() async {
    if (_step == 0) return;
    await _goToStep(_step - 1);
  }

  Future<void> _useMyLocationForAddress() async {
    setState(() => _locationBusy = true);
    final result = await loadAddressFromDeviceLocation();
    if (!mounted) return;
    setState(() => _locationBusy = false);
    if (!result.ok) {
      VetgoNotice.show(
        context,
        message: result.errorMessage ?? 'No se pudo obtener tu ubicación.',
        isError: true,
      );
      return;
    }
    setState(() {
      _address.text = result.addressText ?? '';
      _pickedLatitude = result.latitude;
      _pickedLongitude = result.longitude;
    });
    VetgoNotice.show(context, message: AppStrings.onboardingUbicacionAplicada);
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Requerido' : null;
  }

  String? _phoneValidator(String? value, {bool required = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Requerido' : null;
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(text)) {
      return 'Teléfono no válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = switch (_step) {
      0 => 'Identidad',
      1 => 'Domicilio y tienda',
      2 => 'Tu mascota',
      3 => 'Salud y emergencia',
      _ => 'Revisa y guarda',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressHeader(step: _step, total: _totalSteps, title: title),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _stepIdentity(),
              _stepAddressStore(),
              _stepPetProfile(),
              _stepHealthEmergency(),
              _stepSummary(theme),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.loading ? null : _back,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                onPressed: widget.loading ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: widget.loading && _step == _totalSteps - 1
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step == _totalSteps - 1
                            ? 'Guardar y continuar'
                            : 'Continuar',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepIdentity() {
    return Form(
      key: _stepKeys[0],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'PERFIL',
            title: 'Cómo te verá Vetgo',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(context, label: 'Nombre completo'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: authInputDecoration(
              context,
              label: 'Teléfono',
              hintText: '+525512345678',
            ),
            validator: _phoneValidator,
            onChanged: (value) {
              if (_defaultContactPhone.text.trim().isEmpty) {
                _defaultContactPhone.text = value.trim();
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Ciudad o zona',
              hintText: 'CDMX, Roma Norte...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            maxLength: 500,
            decoration: authInputDecoration(
              context,
              label: 'Bio social (opcional)',
              hintText: 'Cuéntanos sobre tu familia y mascotas',
            ),
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
    );
  }

  Widget _stepAddressStore() {
    return Form(
      key: _stepKeys[1],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'OPERACIÓN',
            title: 'Domicilio, contacto y entregas',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: widget.loading || _locationBusy
                ? null
                : _useMyLocationForAddress,
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
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Mínimo 5 caracteres'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressNotes,
            decoration: authInputDecoration(
              context,
              label: 'Referencias para visitas',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _defaultContactName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Contacto para pedidos (opcional)',
              hintText: _fullName.text.trim().isEmpty
                  ? null
                  : _fullName.text.trim(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _defaultContactPhone,
            keyboardType: TextInputType.phone,
            decoration: authInputDecoration(
              context,
              label: 'Teléfono de contacto',
            ),
            validator: (v) => _phoneValidator(v, required: false),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _preferredFulfillment,
            decoration: authInputDecoration(
              context,
              label: 'Preferencia de tienda',
            ),
            items: const [
              DropdownMenuItem(
                value: 'delivery',
                child: Text('Entrega a domicilio'),
              ),
              DropdownMenuItem(
                value: 'pickup_contact',
                child: Text('Recoger/contacto'),
              ),
            ],
            onChanged: (v) =>
                setState(() => _preferredFulfillment = v ?? 'delivery'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _deliveryNotes,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Notas de entrega (opcional)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPetProfile() {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _stepKeys[2],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'MASCOTA',
            title: 'Datos base del paciente',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _petName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Nombre de la mascota',
            ),
            validator: _required,
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
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _breed,
            textCapitalization: TextCapitalization.words,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: Text(
                _birthDate == null
                    ? 'Fecha de nacimiento (opcional)'
                    : 'Nacimiento: ${_birthDate!.toString().split(' ').first}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(
                    alpha: _birthDate == null ? 0.7 : 0.95,
                  ),
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: authInputDecoration(
              context,
              label: 'Peso kg (opcional)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepHealthEmergency() {
    return Form(
      key: _stepKeys[3],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'SALUD',
            title: 'Alertas para citas y emergencias',
          ),
          const SizedBox(height: 14),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
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
            controller: _allergies,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Alergias conocidas (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _chronicConditions,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Condiciones crónicas (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _currentMedications,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Medicamentos actuales (opcional)',
            ),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyNotes,
            maxLines: 3,
            decoration: authInputDecoration(
              context,
              label: 'Notas para emergencia (opcional)',
              hintText: 'Cómo cargarlo, qué evitar, contactos rápidos...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepSummary(ThemeData theme) {
    return Form(
      key: _stepKeys[4],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'RESUMEN',
            title: 'Confirma tu perfil inicial',
          ),
          const SizedBox(height: 14),
          _SummaryCard(
            title: 'Tutor',
            rows: [
              ('Nombre', _fullName.text.trim()),
              ('Teléfono', _phone.text.trim()),
              ('Zona', _location.text.trim()),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Operación',
            rows: [
              ('Domicilio', _address.text.trim()),
              (
                'Tienda',
                _preferredFulfillment == 'delivery'
                    ? 'Entrega a domicilio'
                    : 'Recoger/contacto',
              ),
              (
                'Contacto',
                _defaultContactPhone.text.trim().isEmpty
                    ? _phone.text.trim()
                    : _defaultContactPhone.text.trim(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Mascota',
            rows: [
              ('Nombre', _petName.text.trim()),
              ('Especie', _species.text.trim()),
              ('Raza', _breed.text.trim()),
              ('Vacunas', _vaccines),
              ('Temperamento', _temperament),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Puedes volver con Atrás para corregir cualquier dato antes de guardar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.step,
    required this.total,
    required this.title,
  });

  final int step;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PASO ${step + 1} DE $total',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (step + 1) / total,
            minHeight: 6,
            backgroundColor: scheme.outline.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AuthOutlinedTile(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        row.$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2.trim().isEmpty ? 'Sin registrar' : row.$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
