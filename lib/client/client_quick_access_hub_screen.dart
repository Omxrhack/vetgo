import 'package:flutter/material.dart';

import 'package:vetgo/client/choose_vet_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/emergency_sos_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';

import 'my_pets_list_screen.dart';
import 'schedule_visit_flow_screen.dart';

/// Punto de entrada al flujo progresivo de accesos (varias pantallas).
class ClientQuickAccessHubScreen extends StatelessWidget {
  const ClientQuickAccessHubScreen({
    super.key,
    required this.pets,
  });

  final List<ClientPetVm> pets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hubServiciosTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            AppStrings.hubElige,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.hubTeGuiamos,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 24),
          _HubTile(
            icon: Icons.medical_services_rounded,
            iconColor: ClientPastelColors.skyDeep,
            title: AppStrings.hubTileVetTitulo,
            subtitle: AppStrings.hubTileVetSubtitulo,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ChooseVetScreen(),
                ),
              );
            },
          ),
          _HubTile(
            icon: Icons.emergency_rounded,
            iconColor: theme.colorScheme.error,
            title: 'Urgencia 24/7',
            subtitle: 'Alerta inmediata con tu ubicaci\u00F3n y mascota.',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencySOSScreen(pets: pets),
                ),
              );
            },
          ),
          _HubTile(
            icon: Icons.calendar_month_rounded,
            iconColor: ClientPastelColors.mintDeep,
            title: AppStrings.hubTileAgendarVisitaTitulo,
            subtitle: AppStrings.hubTileAgendarVisitaSubtitulo,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ScheduleVisitFlowScreen(pets: pets),
                ),
              );
            },
          ),
          _HubTile(
            icon: Icons.pets_rounded,
            iconColor: ClientPastelColors.mintDeep,
            title: 'Mis mascotas',
            subtitle: 'Lista completa y expediente por mascota.',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => MyPetsListScreen(pets: pets),
                ),
              );
            },
          ),
          _HubTile(
            icon: Icons.storefront_rounded,
            iconColor: theme.colorScheme.secondary,
            title: 'Tienda',
            subtitle: 'Cat\u00E1logo de productos.',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const StoreScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: iconColor.withValues(alpha: 0.18),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ClientPastelColors.mutedOn(context),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
