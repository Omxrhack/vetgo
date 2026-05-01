import 'client_pet_vm.dart';

/// Datos de demostración para pantallas cliente hasta conectar API.
abstract final class ClientDemoData {
  static const List<ClientPetVm> pets = [
    ClientPetVm(
      id: '1',
      name: 'Luna',
      speciesLabel: 'Perro',
      breedLabel: 'Mestiza',
      weightLabel: '12 kg',
      ageLabel: '3 años',
    ),
    ClientPetVm(
      id: '2',
      name: 'Michi',
      speciesLabel: 'Gato',
      breedLabel: 'Siamés',
      weightLabel: '4 kg',
      ageLabel: '7 años',
    ),
    ClientPetVm(
      id: '3',
      name: 'Rocky',
      speciesLabel: 'Perro',
      breedLabel: 'Bulldog',
      weightLabel: '18 kg',
      ageLabel: '5 años',
    ),
  ];
}
