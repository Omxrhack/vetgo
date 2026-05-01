import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/widgets/auth_screen_shell.dart';

/// Formulario alineado con `clientOnboardingSchema` del backend.
class ClientOnboardingForm extends StatefulWidget {
  const ClientOnboardingForm({super.key});

  @override
  ClientOnboardingFormState createState() => ClientOnboardingFormState();
}

class ClientOnboardingFormState extends State<ClientOnboardingForm> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _avatarUrl = TextEditingController();
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

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _avatarUrl.dispose();
    _address.dispose();
    _addressNotes.dispose();
    _petName.dispose();
    _species.dispose();
    _breed.dispose();
    _medicalNotes.dispose();
    _weightText.dispose();
    super.dispose();
  }

  Map<String, dynamic>? buildPayloadIfValid() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    final body = <String, dynamic>{
      'role': 'client',
      'full_name': _fullName.text.trim(),
      'phone': _phone.text.trim(),
      'avatar_url': _avatarUrl.text.trim(),
      'client_details': <String, dynamic>{
        'address_text': _address.text.trim(),
        'address_notes': _addressNotes.text.trim(),
        'latitude': null,
        'longitude': null,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          const AuthSectionHeader(eyebrow: 'TUS DATOS', title: 'Sobre ti'),
          const SizedBox(height: 14),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(context, label: 'Nombre completo'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: authInputDecoration(
              context,
              label: 'Telefono',
              hintText: '+521234567890',
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Requerido';
              if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(s)) {
                return 'Telefono no valido';
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
              label: 'URL de foto de perfil (opcional)',
            ),
          ),
          const SizedBox(height: 24),
          const AuthSectionHeader(
            eyebrow: 'DIRECCION',
            title: 'Donde te encontramos',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: authInputDecoration(
              context,
              label: 'Direccion completa',
            ),
            validator: (v) =>
                (v == null || v.trim().length < 5) ? 'Minimo 5 caracteres' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressNotes,
            decoration: authInputDecoration(
              context,
              label: 'Referencias (opcional)',
            ),
          ),
          const SizedBox(height: 24),
          const AuthSectionHeader(
            eyebrow: 'MASCOTA',
            title: 'Datos de tu companero',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _petName,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Nombre de la mascota',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _species,
            textCapitalization: TextCapitalization.words,
            decoration: authInputDecoration(
              context,
              label: 'Especie',
              hintText: 'perro, gato',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _breed,
            decoration: authInputDecoration(
              context,
              label: 'Raza (opcional)',
            ),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          const SizedBox(height: 12),
          AuthOutlinedTile(
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Castrado / esterilizado'),
              value: _neutered,
              onChanged: (v) => setState(() => _neutered = v),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _vaccines,
            decoration: authInputDecoration(context, label: 'Vacunas al dia'),
            items: const [
              DropdownMenuItem(value: 'yes', child: Text('Si')),
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
              label: 'Notas medicas (opcional)',
            ),
          ),
        ],
      ),
    );
  }
}
