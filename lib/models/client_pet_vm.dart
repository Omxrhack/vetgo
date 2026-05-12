/// Modelo liviano para UI cliente (API `/api/pets/:ownerId` o demo).
class ClientPetVm {
  const ClientPetVm({
    required this.id,
    required this.name,
    this.photoUrl,
    this.speciesLabel = 'Mascota',
    this.breedLabel = '',
    this.weightLabel = '- kg',
    this.ageLabel = '',
    this.birthDate,
    this.sex,
    this.weightKg,
    this.isNeutered,
    this.vaccinesUpToDate,
    this.medicalNotes,
    this.temperament,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String speciesLabel;
  final String breedLabel;
  final String weightLabel;
  final String ageLabel;
  final String? birthDate;
  final String? sex;
  final double? weightKg;
  final bool? isNeutered;
  final String? vaccinesUpToDate;
  final String? medicalNotes;
  final String? temperament;

  /// Respuesta fila `pets` del backend (Supabase).
  factory ClientPetVm.fromApiJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final nameRaw = json['name']?.toString().trim() ?? '';
    final name = nameRaw.isEmpty ? 'Mascota' : nameRaw;
    final species = json['species']?.toString().trim();
    final breed = json['breed']?.toString().trim() ?? '';
    final photoUrl = json['photo_url']?.toString();

    final weight = json['weight_kg'] ?? json['weight'];
    double? weightKg;
    var weightLabel = '- kg';
    if (weight is num) {
      weightKg = weight.toDouble();
      weightLabel = weight % 1 == 0
          ? '${weight.toInt()} kg'
          : '${weight.toStringAsFixed(1)} kg';
    } else if (weight is String) {
      final parsed = double.tryParse(weight);
      if (parsed != null) {
        weightKg = parsed;
        weightLabel = parsed % 1 == 0
            ? '${parsed.toInt()} kg'
            : '${parsed.toStringAsFixed(1)} kg';
      }
    }

    var ageLabel = '';
    final birthRaw = json['birth_date'];
    if (birthRaw is String && birthRaw.isNotEmpty) {
      try {
        final d = DateTime.parse(birthRaw);
        final now = DateTime.now();
        var years = now.year - d.year;
        if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
          years--;
        }
        if (years >= 0) {
          ageLabel = years == 1 ? '1 año' : '$years años';
        }
      } catch (_) {}
    }

    return ClientPetVm(
      id: id,
      name: name,
      photoUrl: photoUrl != null && photoUrl.isNotEmpty ? photoUrl : null,
      speciesLabel: species != null && species.isNotEmpty ? species : 'Mascota',
      breedLabel: breed,
      weightLabel: weightLabel,
      ageLabel: ageLabel,
      birthDate: birthRaw is String && birthRaw.isNotEmpty ? birthRaw : null,
      sex: json['sex']?.toString(),
      weightKg: weightKg,
      isNeutered: json['is_neutered'] is bool
          ? json['is_neutered'] as bool
          : null,
      vaccinesUpToDate: json['vaccines_up_to_date']?.toString(),
      medicalNotes: json['medical_notes']?.toString(),
      temperament: json['temperament']?.toString(),
    );
  }

  Map<String, dynamic> toApiPayload() {
    return <String, dynamic>{
      'name': name,
      'species': speciesLabel,
      if (breedLabel.trim().isNotEmpty) 'breed': breedLabel.trim(),
      if (birthDate != null && birthDate!.trim().isNotEmpty)
        'birth_date': birthDate,
      if (weightKg != null) ...<String, dynamic>{
        'weight': weightKg,
        'weight_kg': weightKg,
      },
      if (sex != null && sex!.trim().isNotEmpty) 'sex': sex!.trim(),
      if (isNeutered != null) 'is_neutered': isNeutered,
      if (vaccinesUpToDate != null && vaccinesUpToDate!.trim().isNotEmpty)
        'vaccines_up_to_date': vaccinesUpToDate!.trim(),
      if (medicalNotes != null && medicalNotes!.trim().isNotEmpty)
        'medical_notes': medicalNotes!.trim(),
      if (temperament != null && temperament!.trim().isNotEmpty)
        'temperament': temperament!.trim(),
    };
  }
}
