import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/pastel_status_chip.dart';
import 'package:vetgo/widgets/client/timeline_medical_tile.dart';

/// Expediente médico digital de una mascota.
class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.pet});

  final ClientPetVm pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expediente'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ClientSoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                        ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                            child: Icon(Icons.pets_rounded, size: 48, color: ClientPastelColors.skyDeep.withValues(alpha: 0.55)),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pet.speciesLabel}${pet.breedLabel.isNotEmpty ? ' · ${pet.breedLabel}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, size: 18, color: muted),
                          const SizedBox(width: 6),
                          Text(pet.weightLabel, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 16),
                          Icon(Icons.cake_outlined, size: 18, color: muted),
                          const SizedBox(width: 6),
                          Text(
                            pet.ageLabel.isEmpty ? 'Edad —' : pet.ageLabel,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOutCubic).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 22),
          Text('Estado de salud', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PastelStatusChip(
                label: 'Vacunas al día',
                icon: Icons.verified_rounded,
                backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.72),
                foregroundColor: ClientPastelColors.mintDeep,
              ),
              PastelStatusChip(
                label: 'Desparasitación OK',
                icon: Icons.healing_rounded,
                backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                foregroundColor: ClientPastelColors.skyDeep,
              ),
              PastelStatusChip(
                label: 'Control dental pendiente',
                icon: Icons.info_outline_rounded,
                backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.68),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Historial', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ClientSoftCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Column(
              children: [
                TimelineMedicalTile(
                  title: 'Consulta general',
                  subtitle: 'Chequeo anual, presión y escucha cardíaca normal.',
                  dateLabel: '12 marzo 2026',
                  dotColor: ClientPastelColors.mintDeep,
                  isLast: false,
                ),
                TimelineMedicalTile(
                  title: 'Vacuna polivalente',
                  subtitle: 'Refuerzo aplicado sin reacciones adversas.',
                  dateLabel: '02 febrero 2026',
                  dotColor: ClientPastelColors.skyDeep,
                  isLast: false,
                ),
                TimelineMedicalTile(
                  title: 'Desparasitación interna',
                  subtitle: 'Tableta oral; próxima dosis en 90 días.',
                  dateLabel: '18 enero 2026',
                  dotColor: ClientPastelColors.amberSoft.withValues(alpha: 0.95),
                  isLast: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 90.ms, duration: 380.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
