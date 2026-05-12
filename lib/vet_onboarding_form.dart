import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vetgo/auth/widgets/auth_screen_shell.dart';
import 'package:vetgo/auth/widgets/onboarding_profile_photo_field.dart';
import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/location/onboarding_location_fill.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class VetOnboardingForm extends StatefulWidget {
  const VetOnboardingForm({
    super.key,
    required this.loading,
    required this.onSubmit,
  });

  final bool loading;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<VetOnboardingForm> createState() => VetOnboardingFormState();
}

class VetOnboardingFormState extends State<VetOnboardingForm> {
  static const _totalSteps = 6;
  static const _serviceOptions = [
    'Consulta general',
    'Vacunación',
    'Urgencias',
    'Nutrición',
    'Desparasitación',
    'Seguimiento postoperatorio',
  ];

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
  final _cedula = TextEditingController();
  final _university = TextEditingController();
  final _vetBaseAddress = TextEditingController();
  final _radius = TextEditingController(text: '15');
  final _emergencyRadius = TextEditingController(text: '8');
  final _customServices = TextEditingController();
  final _scheduleLabel = TextEditingController(text: 'Lunes a viernes 9-18');
  final _storeDisplayName = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _pickupInstructions = TextEditingController();
  final _storeContactPhone = TextEditingController();
  final _accountHolder = TextEditingController();
  final _clabe = TextEditingController();
  final _bankName = TextEditingController();
  final _rfc = TextEditingController();

  final Set<String> _selectedServices = {'Consulta general'};

  String _experience = '1-3';
  String _specialty = 'medicina_general';
  bool _hasVehicle = true;
  bool _acceptsEmergencies = false;
  bool _homeVisitEnabled = true;
  bool _telemedicineEnabled = false;
  bool _offersDelivery = true;
  bool _offersPickup = true;
  double? _baseLatitude;
  double? _baseLongitude;
  bool _baseLocationBusy = false;
  String? _profileAvatarUrl;

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
        if (name != null && name.isNotEmpty) {
          _fullName.text = name;
          _storeDisplayName.text = name;
          _accountHolder.text = name;
        }
        if (phone != null && phone.isNotEmpty) {
          _phone.text = phone;
          _storeContactPhone.text = phone;
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
      _cedula,
      _university,
      _vetBaseAddress,
      _radius,
      _emergencyRadius,
      _customServices,
      _scheduleLabel,
      _storeDisplayName,
      _pickupAddress,
      _pickupInstructions,
      _storeContactPhone,
      _accountHolder,
      _clabe,
      _bankName,
      _rfc,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final services = <String>{
      ..._selectedServices,
      ..._customServices.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
    }.toList();
    final radius = int.tryParse(_radius.text.trim()) ?? 15;
    final emergencyRadius = int.tryParse(_emergencyRadius.text.trim());
    final baseAddress = _vetBaseAddress.text.trim();
    final pickupAddress = _pickupAddress.text.trim().isEmpty
        ? baseAddress
        : _pickupAddress.text.trim();

    return <String, dynamic>{
      'role': 'vet',
      'full_name': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'avatar_url': _profileAvatarUrl?.trim() ?? '',
      'profile_social': <String, dynamic>{
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
      },
      'vet_details': <String, dynamic>{
        'cedula': _cedula.text.trim(),
        'university': _university.text.trim(),
        'experience_years': _experience,
        'base_address_text': baseAddress,
        'base_latitude': _baseLatitude,
        'base_longitude': _baseLongitude,
        'coverage_radius_km': radius.clamp(1, 100),
        'has_vehicle': _hasVehicle,
      },
      'vet_services': <String, dynamic>{
        'specialty': _specialty,
        'offered_services': services,
        'accepts_emergencies': _acceptsEmergencies,
        'home_visit_enabled': _homeVisitEnabled,
        'telemedicine_enabled': _telemedicineEnabled,
        'emergency_radius_km': emergencyRadius?.clamp(1, 100),
        'schedule_json': <String, dynamic>{
          'label': _scheduleLabel.text.trim(),
          if (baseAddress.isNotEmpty) 'base_location_note': baseAddress,
        },
      },
      'vet_finances': <String, dynamic>{
        'account_holder': _accountHolder.text.trim(),
        'clabe': _clabe.text.trim(),
        'bank_name': _bankName.text.trim(),
        'rfc': _rfc.text.trim(),
      },
      'vet_store_settings': <String, dynamic>{
        'store_display_name': _storeDisplayName.text.trim(),
        'pickup_address_text': pickupAddress,
        'pickup_instructions': _pickupInstructions.text.trim(),
        'store_contact_phone': _storeContactPhone.text.trim().isEmpty
            ? _phone.text.trim()
            : _storeContactPhone.text.trim(),
        'offers_delivery': _offersDelivery,
        'offers_pickup': _offersPickup,
      },
    };
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
    if (_step == 0) {
      final photo = _profileAvatarUrl?.trim() ?? '';
      if (photo.isEmpty) {
        VetgoNotice.show(
          context,
          message: AppStrings.onboardingVetFotoRequerida,
          isError: true,
        );
        return;
      }
    }
    if (_step == 3 && _allServices().isEmpty) {
      VetgoNotice.show(
        context,
        message: 'Selecciona o escribe al menos un servicio.',
        isError: true,
      );
      return;
    }
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

  Future<void> _useMyLocationForBase() async {
    setState(() => _baseLocationBusy = true);
    final result = await loadAddressFromDeviceLocation();
    if (!mounted) return;
    setState(() => _baseLocationBusy = false);
    if (!result.ok) {
      VetgoNotice.show(
        context,
        message: result.errorMessage ?? 'No se pudo obtener tu ubicación.',
        isError: true,
      );
      return;
    }
    setState(() {
      _vetBaseAddress.text = result.addressText ?? '';
      if (_pickupAddress.text.trim().isEmpty) {
        _pickupAddress.text = result.addressText ?? '';
      }
      _baseLatitude = result.latitude;
      _baseLongitude = result.longitude;
    });
    VetgoNotice.show(context, message: AppStrings.onboardingUbicacionAplicada);
  }

  List<String> _allServices() {
    return <String>{
      ..._selectedServices,
      ..._customServices.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
    }.toList();
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

  String? _radiusValidator(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 1 || number > 100) return 'Entre 1 y 100';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Identidad pública',
      1 => 'Credenciales',
      2 => 'Base y cobertura',
      3 => 'Servicios y agenda',
      4 => 'Tienda veterinaria',
      _ => 'Cobro y revisión',
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
              _stepCredentials(),
              _stepCoverage(),
              _stepServices(),
              _stepStore(),
              _stepFinanceSummary(),
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
            title: 'Tu presencia pública',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(context, label: 'Nombre completo'),
            validator: _required,
            onChanged: (value) {
              if (_storeDisplayName.text.trim().isEmpty) {
                _storeDisplayName.text = value.trim();
              }
              if (_accountHolder.text.trim().isEmpty) {
                _accountHolder.text = value.trim();
              }
            },
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
              if (_storeContactPhone.text.trim().isEmpty) {
                _storeContactPhone.text = value.trim();
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Ciudad o zona visible',
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
              label: 'Bio profesional',
              hintText: 'Especialidad, enfoque y tipo de pacientes',
            ),
          ),
          const SizedBox(height: 12),
          OnboardingProfilePhotoField(
            imageUrl: _profileAvatarUrl,
            allowClear: false,
            busy: widget.loading,
            onUrlChanged: (url) => setState(() => _profileAvatarUrl = url),
          ),
        ],
      ),
    );
  }

  Widget _stepCredentials() {
    return Form(
      key: _stepKeys[1],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'PROFESIONAL',
            title: 'Credenciales veterinarias',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cedula,
            decoration: authInputDecoration(
              context,
              label: 'Cédula profesional',
            ),
            validator: (v) =>
                (v == null || v.trim().length < 5) ? 'Requerido (mín 5)' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _university,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Universidad (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _experience,
            decoration: authInputDecoration(
              context,
              label: 'Años de experiencia',
            ),
            items: const [
              DropdownMenuItem(value: '1-3', child: Text('1-3')),
              DropdownMenuItem(value: '4-7', child: Text('4-7')),
              DropdownMenuItem(value: '8+', child: Text('8+')),
            ],
            onChanged: (v) => setState(() => _experience = v ?? '1-3'),
          ),
        ],
      ),
    );
  }

  Widget _stepCoverage() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Form(
      key: _stepKeys[2],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'COBERTURA',
            title: 'Base, movilidad y radio',
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.onboardingVetBaseDireccionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: widget.loading || _baseLocationBusy
                ? null
                : _useMyLocationForBase,
            icon: _baseLocationBusy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(AppStrings.onboardingUsarUbicacion),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vetBaseAddress,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: AppStrings.onboardingVetBaseDireccionLabel,
            ),
            validator: (v) => (v == null || v.trim().length < 5)
                ? 'Mínimo 5 caracteres'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _radius,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: authInputDecoration(
              context,
              label: 'Radio de cobertura normal (km)',
              hintText: '1 a 100',
            ),
            validator: _radiusValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyRadius,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: authInputDecoration(
              context,
              label: 'Radio para emergencias (km)',
              hintText: '1 a 100',
            ),
            validator: _radiusValidator,
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Tengo vehículo propio'),
              value: _hasVehicle,
              onChanged: (v) => setState(() => _hasVehicle = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepServices() {
    return Form(
      key: _stepKeys[3],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'SERVICIOS',
            title: 'Qué atiendes y cuándo',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _specialty,
            decoration: authInputDecoration(context, label: 'Especialidad'),
            items: const [
              DropdownMenuItem(
                value: 'medicina_general',
                child: Text('Medicina general'),
              ),
              DropdownMenuItem(value: 'urgencias', child: Text('Urgencias')),
              DropdownMenuItem(value: 'exoticos', child: Text('Exóticos')),
              DropdownMenuItem(value: 'nutricion', child: Text('Nutrición')),
              DropdownMenuItem(
                value: 'fisioterapia',
                child: Text('Fisioterapia'),
              ),
            ],
            onChanged: (v) =>
                setState(() => _specialty = v ?? 'medicina_general'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final service in _serviceOptions)
                FilterChip(
                  label: Text(service),
                  selected: _selectedServices.contains(service),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customServices,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Servicios extra',
              hintText: 'Separados por coma',
            ),
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Atiendo a domicilio'),
              value: _homeVisitEnabled,
              onChanged: (v) => setState(() => _homeVisitEnabled = v),
            ),
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Ofrezco teleconsulta'),
              value: _telemedicineEnabled,
              onChanged: (v) => setState(() => _telemedicineEnabled = v),
            ),
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Acepto emergencias'),
              value: _acceptsEmergencies,
              onChanged: (v) => setState(() => _acceptsEmergencies = v),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _scheduleLabel,
            decoration: authInputDecoration(
              context,
              label: 'Horario visible',
              hintText: 'Lunes a viernes 9-18',
            ),
            validator: _required,
          ),
        ],
      ),
    );
  }

  Widget _stepStore() {
    return Form(
      key: _stepKeys[4],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'TIENDA',
            title: 'Cómo operarás productos',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _storeDisplayName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Nombre visible de tienda',
            ),
            validator: (v) => (v == null || v.trim().length < 2)
                ? 'Mínimo 2 caracteres'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pickupAddress,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Dirección de pickup',
              hintText: _vetBaseAddress.text.trim().isEmpty
                  ? null
                  : _vetBaseAddress.text.trim(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pickupInstructions,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Instrucciones de pickup (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _storeContactPhone,
            keyboardType: TextInputType.phone,
            decoration: authInputDecoration(
              context,
              label: 'Teléfono de tienda',
            ),
            validator: (v) => _phoneValidator(v, required: false),
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Ofrecer entrega'),
              value: _offersDelivery,
              onChanged: (v) => setState(() => _offersDelivery = v),
            ),
          ),
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              title: const Text('Ofrecer pickup/contacto'),
              value: _offersPickup,
              onChanged: (v) => setState(() => _offersPickup = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepFinanceSummary() {
    final theme = Theme.of(context);
    return Form(
      key: _stepKeys[5],
      child: ListView(
        children: [
          const AuthSectionHeader(
            eyebrow: 'COBRO',
            title: 'Datos bancarios y resumen',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _accountHolder,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Titular de la cuenta',
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clabe,
            keyboardType: TextInputType.number,
            maxLength: 18,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: authInputDecoration(
              context,
              label: 'CLABE',
              hintText: '18 dígitos',
            ).copyWith(counterText: ''),
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.length != 18) return 'Deben ser 18 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(context, label: 'Nombre del banco'),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rfc,
            textCapitalization: TextCapitalization.characters,
            decoration: authInputDecoration(context, label: 'RFC (opcional)'),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            title: 'Resumen operativo',
            rows: [
              ('Especialidad', _specialty),
              ('Servicios', _allServices().join(', ')),
              ('Cobertura', '${_radius.text.trim()} km'),
              ('Emergencias', _acceptsEmergencies ? 'Sí' : 'No'),
              ('Tienda', _storeDisplayName.text.trim()),
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
                      width: 92,
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
