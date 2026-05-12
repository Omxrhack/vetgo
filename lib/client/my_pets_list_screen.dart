import 'package:flutter/material.dart';

import 'package:vetgo/client/pet_form_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';

/// Lista de mascotas del cliente antes de abrir el expediente.
class MyPetsListScreen extends StatelessWidget {
  const MyPetsListScreen({super.key, required this.pets, this.onChanged});

  final List<ClientPetVm> pets;
  final Future<void> Function()? onChanged;

  Future<void> _openCreate(BuildContext context) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(builder: (_) => const PetFormScreen()),
    );
    if (result != null) await onChanged?.call();
  }

  Future<void> _openProfile(BuildContext context, ClientPetVm pet) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PetProfileScreen(pet: pet, onChanged: onChanged),
      ),
    );
    if (changed == true) await onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis mascotas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: pets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'A\u00FAn no hay mascotas sincronizadas desde tu cuenta.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = pets[i];
                return Material(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      _openProfile(context, p);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: ClientPastelColors.mintSoft,
                            backgroundImage:
                                p.photoUrl != null && p.photoUrl!.isNotEmpty
                                ? NetworkImage(p.photoUrl!)
                                : null,
                            child: p.photoUrl == null || p.photoUrl!.isEmpty
                                ? Icon(
                                    Icons.pets_rounded,
                                    color: ClientPastelColors.mintDeep,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.speciesLabel} \u00B7 ${p.weightLabel} \u00B7 ${p.ageLabel.isEmpty ? "edad desconocida" : p.ageLabel}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
