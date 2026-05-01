/// Modelo liviano para UI cliente (API `/api/pets/:ownerId` o demo).
class ClientPetVm {
  const ClientPetVm({
    required this.id,
    required this.name,
    this.photoUrl,
    this.speciesLabel = 'Mascota',
    this.breedLabel = '',
    this.weightLabel = '— kg',
    this.ageLabel = '',
  });

  final String id;
  final String name;
  final String? photoUrl;
  final String speciesLabel;
  final String breedLabel;
  final String weightLabel;
  final String ageLabel;

  /// Respuesta fila `pets` del backend (Supabase).
  factory ClientPetVm.fromApiJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final nameRaw = json['name']?.toString().trim() ?? '';
    final name = nameRaw.isEmpty ? 'Mascota' : nameRaw;
    final species = json['species']?.toString().trim();
    final breed = json['breed']?.toString().trim() ?? '';
    final photoUrl = json['photo_url']?.toString();

    final weight = json['weight'];
    var weightLabel = '— kg';
    if (weight is num) {
      weightLabel =
          weight % 1 == 0 ? '${weight.toInt()} kg' : '${weight.toStringAsFixed(1)} kg';
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
    );
  }
}
