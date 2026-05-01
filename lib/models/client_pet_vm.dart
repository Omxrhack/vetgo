/// Modelo liviano para UI cliente (demo / futura API).
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
}
