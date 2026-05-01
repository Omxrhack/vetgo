import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario alineado con `vetOnboardingSchema` del backend.
class VetOnboardingForm extends StatefulWidget {
  const VetOnboardingForm({super.key});

  @override
  VetOnboardingFormState createState() => VetOnboardingFormState();
}

class VetOnboardingFormState extends State<VetOnboardingForm> {
  final _formKey = GlobalKey<FormState>();

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

  Map<String, dynamic>? buildPayloadIfValid() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        children: [
          Text('Datos profesionales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefono (con lada)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Requerido';
              if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(s)) return 'Telefono no valido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _avatarUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL de foto de perfil',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Requerido';
              final uri = Uri.tryParse(s);
              if (uri == null || !uri.hasScheme) return 'URL no valida';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cedula,
            decoration: const InputDecoration(
              labelText: 'Cedula profesional',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 5) ? 'Requerido (min 5)' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _university,
            decoration: const InputDecoration(
              labelText: 'Universidad (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _experience,
            decoration: const InputDecoration(
              labelText: 'Anos de experiencia',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: '1-3', child: Text('1-3')),
              DropdownMenuItem(value: '4-7', child: Text('4-7')),
              DropdownMenuItem(value: '8+', child: Text('8+')),
            ],
            onChanged: (v) => setState(() => _experience = v ?? '1-3'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _radius,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Radio de cobertura (km, 1-100)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1 || n > 100) return 'Entre 1 y 100';
              return null;
            },
          ),
          SwitchListTile(
            title: const Text('Tengo vehiculo propio'),
            value: _hasVehicle,
            onChanged: (v) => setState(() => _hasVehicle = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _specialty,
            decoration: const InputDecoration(
              labelText: 'Especialidad',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'medicina_general', child: Text('Medicina general')),
              DropdownMenuItem(value: 'urgencias', child: Text('Urgencias')),
              DropdownMenuItem(value: 'exoticos', child: Text('Exoticos')),
              DropdownMenuItem(value: 'nutricion', child: Text('Nutricion')),
              DropdownMenuItem(value: 'fisioterapia', child: Text('Fisioterapia')),
            ],
            onChanged: (v) => setState(() => _specialty = v ?? 'medicina_general'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _offeredServices,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Servicios ofrecidos (separados por coma)',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Al menos un servicio' : null,
          ),
          SwitchListTile(
            title: const Text('Acepto emergencias'),
            value: _acceptsEmergencies,
            onChanged: (v) => setState(() => _acceptsEmergencies = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _scheduleLabel,
            decoration: const InputDecoration(
              labelText: 'Horario (etiqueta)',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 20),
          Text('Datos bancarios', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clabe,
            keyboardType: TextInputType.number,
            maxLength: 18,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'CLABE (18 digitos)',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length != 18) return 'Deben ser 18 digitos';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankName,
            decoration: const InputDecoration(
              labelText: 'Nombre del banco',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rfc,
            decoration: const InputDecoration(
              labelText: 'RFC (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
