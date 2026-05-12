import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.initialPet});

  final ClientPetVm? initialPet;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _api = VetgoApiClient();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _breed;
  late final TextEditingController _birthDate;
  late final TextEditingController _weight;
  late final TextEditingController _sex;
  late final TextEditingController _vaccines;
  late final TextEditingController _temperament;
  late final TextEditingController _medicalNotes;
  bool? _isNeutered;

  bool get _isEditing => widget.initialPet != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPet;
    _name = TextEditingController(text: p?.name ?? '');
    _species = TextEditingController(
      text: p?.speciesLabel == 'Mascota' ? '' : p?.speciesLabel ?? '',
    );
    _breed = TextEditingController(text: p?.breedLabel ?? '');
    _birthDate = TextEditingController(text: p?.birthDate ?? '');
    _weight = TextEditingController(text: p?.weightKg?.toString() ?? '');
    _sex = TextEditingController(text: p?.sex ?? '');
    _vaccines = TextEditingController(text: p?.vaccinesUpToDate ?? '');
    _temperament = TextEditingController(text: p?.temperament ?? '');
    _medicalNotes = TextEditingController(text: p?.medicalNotes ?? '');
    _isNeutered = p?.isNeutered;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _breed.dispose();
    _birthDate.dispose();
    _weight.dispose();
    _sex.dispose();
    _vaccines.dispose();
    _temperament.dispose();
    _medicalNotes.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    String? textOrNull(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    return <String, dynamic>{
      'name': _name.text.trim(),
      'species': _species.text.trim(),
      'breed': textOrNull(_breed),
      'birth_date': textOrNull(_birthDate),
      if (weight != null) ...<String, dynamic>{
        'weight': weight,
        'weight_kg': weight,
      },
      'sex': textOrNull(_sex),
      'is_neutered': _isNeutered,
      'vaccines_up_to_date': textOrNull(_vaccines),
      'temperament': textOrNull(_temperament),
      'medical_notes': textOrNull(_medicalNotes),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final body = _payload();
    final (data, err) = _isEditing
        ? await _api.updatePet(petId: widget.initialPet!.id, body: body)
        : await _api.createPet(body);

    if (!mounted) return;
    if (err != null || data == null) {
      VetgoNotice.show(
        context,
        message: err ?? 'No se pudo guardar la mascota.',
        isError: true,
      );
      return;
    }
    VetgoNotice.show(
      context,
      message: _isEditing ? 'Mascota actualizada.' : 'Mascota registrada.',
    );
    Navigator.of(context).pop(ClientPetVm.fromApiJson(data));
  }

  Future<void> _delete() async {
    final pet = widget.initialPet;
    if (pet == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text(
          'Se eliminará el expediente de ${pet.name}. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final err = await _api.deletePet(petId: pet.id);
    if (!mounted) return;
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: 'Mascota eliminada.');
    Navigator.of(context).pop('deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar mascota' : 'Nueva mascota'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _field(_name, 'Nombre', required: true),
            _field(
              _species,
              'Especie',
              hint: 'Perro, Gato, Conejo...',
              required: true,
            ),
            _field(_breed, 'Raza'),
            _field(_birthDate, 'Fecha de nacimiento', hint: 'YYYY-MM-DD'),
            _field(
              _weight,
              'Peso kg',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _field(_sex, 'Sexo'),
            const SizedBox(height: 6),
            DropdownButtonFormField<bool?>(
              initialValue: _isNeutered,
              decoration: const InputDecoration(labelText: 'Esterilizado'),
              items: const [
                DropdownMenuItem<bool?>(
                  value: null,
                  child: Text('Sin especificar'),
                ),
                DropdownMenuItem<bool?>(value: true, child: Text('Sí')),
                DropdownMenuItem<bool?>(value: false, child: Text('No')),
              ],
              onChanged: (value) => setState(() => _isNeutered = value),
            ),
            const SizedBox(height: 12),
            _field(_vaccines, 'Vacunas', hint: 'Al día, parcial, pendiente...'),
            _field(_temperament, 'Temperamento'),
            _field(_medicalNotes, 'Notas médicas', maxLines: 4),
            const SizedBox(height: 20),
            AsyncEndpointButton(
              label: _isEditing ? 'Guardar cambios' : 'Registrar mascota',
              loadingLabel: 'Guardando...',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label es requerido';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
