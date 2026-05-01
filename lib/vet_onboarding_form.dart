import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/widgets/auth_screen_shell.dart';

/// Formulario alineado con `vetOnboardingSchema` del backend.
class VetOnboardingForm extends StatefulWidget {
  const VetOnboardingForm({
    super.key,
    required this.loading,
    required this.onSubmit,
  });

  final bool loading;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  VetOnboardingFormState createState() => VetOnboardingFormState();
}

class VetOnboardingFormState extends State<VetOnboardingForm> {
  final _pageController = PageController();
  int _step = 0;

  final _stepKeys = List<GlobalKey<FormState>>.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _avatarUrl = TextEditingController(text: 'https://placehold.co/128/png');
  final _cedula = TextEditingController();
  final _university = TextEditingController();
  final _radius = TextEditingController(text: '15');
  final _offeredServices = TextEditingController();
  final _scheduleLabel = TextEditingController(text: 'Lunes a viernes 9-18');
  final _clabe = TextEditingController();
  final _bankName = TextEditingController();
  final _rfc = TextEditingController();

  String _experience = '1-3';
  bool _hasVehicle = true;
  String _specialty = 'medicina_general';
  bool _acceptsEmergencies = false;

  @override
  void dispose() {
    _pageController.dispose();
    _fullName.dispose();
    _phone.dispose();
    _avatarUrl.dispose();
    _cedula.dispose();
    _university.dispose();
    _radius.dispose();
    _offeredServices.dispose();
    _scheduleLabel.dispose();
    _clabe.dispose();
    _bankName.dispose();
    _rfc.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    final services = _offeredServices.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final radius = int.tryParse(_radius.text.trim()) ?? 15;

    return <String, dynamic>{
      'role': 'vet',
      'full_name': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'avatar_url': _avatarUrl.text.trim(),
      'vet_details': <String, dynamic>{
        'cedula': _cedula.text.trim(),
        'university': _university.text.trim(),
        'experience_years': _experience,
        'base_latitude': null,
        'base_longitude': null,
        'coverage_radius_km': radius.clamp(1, 100),
        'has_vehicle': _hasVehicle,
      },
      'vet_services': <String, dynamic>{
        'specialty': _specialty,
        'offered_services': services,
        'accepts_emergencies': _acceptsEmergencies,
        'schedule_json': <String, dynamic>{
          'label': _scheduleLabel.text.trim(),
        },
      },
      'vet_finances': <String, dynamic>{
        'clabe': _clabe.text.trim(),
        'bank_name': _bankName.text.trim(),
        'rfc': _rfc.text.trim(),
      },
    };
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

  Future<void> _back() async {
    if (_step == 0) return;
    await _goToStep(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (_step) {
      0 => 'Datos personales',
      1 => 'Datos profesionales',
      2 => 'Cobertura y servicios',
      _ => 'Datos bancarios',
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
                    const AuthSectionHeader(eyebrow: 'DATOS', title: 'Sobre ti'),
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
                        hintText: 'Con lada',
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
                    TextFormField(
                      controller: _avatarUrl,
                      keyboardType: TextInputType.url,
                      decoration: authInputDecoration(
                        context,
                        label: 'URL de foto de perfil',
                      ),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Requerido';
                        final uri = Uri.tryParse(s);
                        if (uri == null || !uri.hasScheme) return 'URL no válida';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[1],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'PROFESIONAL',
                      title: 'Información profesional',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _cedula,
                      decoration: authInputDecoration(context, label: 'Cédula profesional'),
                      validator: (v) =>
                          (v == null || v.trim().length < 5) ? 'Requerido (mín 5)' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _university,
                      decoration: authInputDecoration(
                        context,
                        label: 'Universidad (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _experience,
                      decoration: authInputDecoration(context, label: 'Años de experiencia'),
                      items: const [
                        DropdownMenuItem(value: '1-3', child: Text('1-3')),
                        DropdownMenuItem(value: '4-7', child: Text('4-7')),
                        DropdownMenuItem(value: '8+', child: Text('8+')),
                      ],
                      onChanged: (v) => setState(() => _experience = v ?? '1-3'),
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[2],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'COBERTURA',
                      title: 'Cómo atiendes',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _radius,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: authInputDecoration(
                        context,
                        label: 'Radio de cobertura (km)',
                        hintText: '1 a 100',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1 || n > 100) return 'Entre 1 y 100';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthOutlinedTile(
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: const Text('Tengo vehículo propio'),
                        value: _hasVehicle,
                        onChanged: (v) => setState(() => _hasVehicle = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _specialty,
                      decoration: authInputDecoration(context, label: 'Especialidad'),
                      items: const [
                        DropdownMenuItem(value: 'medicina_general', child: Text('Medicina general')),
                        DropdownMenuItem(value: 'urgencias', child: Text('Urgencias')),
                        DropdownMenuItem(value: 'exoticos', child: Text('Exóticos')),
                        DropdownMenuItem(value: 'nutricion', child: Text('Nutrición')),
                        DropdownMenuItem(value: 'fisioterapia', child: Text('Fisioterapia')),
                      ],
                      onChanged: (v) => setState(() => _specialty = v ?? 'medicina_general'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _offeredServices,
                      maxLines: 2,
                      decoration: authInputDecoration(
                        context,
                        label: 'Servicios ofrecidos',
                        hintText: 'Separados por coma',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Al menos un servicio' : null,
                    ),
                    const SizedBox(height: 12),
                    AuthOutlinedTile(
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        label: 'Horario',
                        hintText: 'Etiqueta breve',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              Form(
                key: _stepKeys[3],
                child: ListView(
                  children: [
                    const AuthSectionHeader(
                      eyebrow: 'BANCO',
                      title: 'Datos bancarios',
                    ),
                    const SizedBox(height: 14),
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
                        final s = v?.trim() ?? '';
                        if (s.length != 18) return 'Deben ser 18 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bankName,
                      decoration: authInputDecoration(context, label: 'Nombre del banco'),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rfc,
                      decoration: authInputDecoration(
                        context,
                        label: 'RFC (opcional)',
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
