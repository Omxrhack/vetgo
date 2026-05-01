import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/client/client_quick_access_hub_screen.dart';
import 'package:vetgo/client/client_strings.dart';
import 'package:vetgo/live_tracking_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/pastel_quick_action_card.dart';

/// Home / dashboard principal del cliente (estetica pastel Vetgo).
class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.pets,
    this.petsLoading = false,
    this.petsError,
    required this.onRefreshPets,
    required this.onLogout,
    required this.onOpenEmergency,
  });

  final String userName;
  final String? profilePhotoUrl;
  final List<ClientPetVm> pets;
  final bool petsLoading;
  final String? petsError;
  final Future<void> Function() onRefreshPets;
  final VoidCallback onLogout;
  final VoidCallback onOpenEmergency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = ClientPastelColors.mutedOn(context);
    final displayName = userName.trim().isEmpty ? 'amigo' : userName.trim();

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: onRefreshPets,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 118,
            actions: [
              IconButton(
                tooltip: ClientStrings.cerrarSesionTooltip,
                icon: const Icon(Icons.logout_rounded),
                onPressed: onLogout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 56, bottom: 14),
              title: Text(
                ClientStrings.holaNombre(displayName),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 56, top: 36),
                  child: Hero(
                    tag: 'client_avatar',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: ClientPastelColors.mintSoft,
                      backgroundImage:
                          profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty ? NetworkImage(profilePhotoUrl!) : null,
                      child: profilePhotoUrl == null || profilePhotoUrl!.isEmpty
                          ? Icon(Icons.person_rounded, color: ClientPastelColors.mintDeep, size: 30)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (petsError != null && petsError!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClientSoftCard(
                        color: scheme.errorContainer.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: scheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${ClientStrings.mascotasErrorParcial} ($petsError)',
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ClientSoftCard(
                    color: ClientPastelColors.amberSoft.withValues(alpha: 0.55),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: ClientPastelColors.skyDeep, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ClientStrings.recordatoriosTitulo,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ClientStrings.recordatoriosCuerpo,
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 22),
                  Text(
                    ClientStrings.accesosRapidos,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ClientQuickAccessHubScreen(pets: pets),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.9),
                              child: Icon(Icons.apps_rounded, color: ClientPastelColors.mintDeep, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ClientStrings.accesosHubTitulo,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ClientStrings.accesosHubSubtitulo,
                                    style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: scheme.outline),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.05, end: 0, delay: 80.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: PastelQuickActionCard(
                          icon: Icons.emergency_rounded,
                          label: 'Urgencia\n24/7',
                          backgroundColor: ClientPastelColors.coralSoft.withValues(alpha: 0.65),
                          iconColor: scheme.error.withValues(alpha: 0.85),
                          onTap: onOpenEmergency,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: PastelQuickActionCard(
                          icon: Icons.storefront_rounded,
                          label: 'Tienda',
                          backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.72),
                          iconColor: scheme.secondary,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.05, end: 0, delay: 120.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ClientStrings.tusMascotas,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: pets.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PetProfileScreen(pet: pets.first),
                                  ),
                                );
                              },
                        child: const Text(ClientStrings.verExpediente),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 128,
                    child: petsLoading && pets.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : pets.isEmpty
                            ? Text(
                                ClientStrings.carouselSinMascotas,
                                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: pets.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (context, i) {
                                  final p = pets[i];
                                  return _PetCarouselTile(
                                    pet: p,
                                    onTap: () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(builder: (_) => PetProfileScreen(pet: p)),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 18),
                  AsyncEndpointButton(
                    label: ClientStrings.simularCitaEnCamino,
                    icon: Icons.location_searching_rounded,
                    loadingLabel: ClientStrings.conectando,
                    style: FilledButton.styleFrom(
                      backgroundColor: ClientPastelColors.skyDeep.withValues(alpha: 0.88),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await Future<void>.delayed(const Duration(milliseconds: 900));
                      if (!context.mounted) return;
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LiveTrackingScreen(
                            vetName: ClientStrings.demoVetNombre,
                            etaLabel: ClientStrings.demoEta,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCarouselTile extends StatelessWidget {
  const _PetCarouselTile({required this.pet, required this.onTap});

  final ClientPetVm pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: ClientPastelColors.mintSoft,
                backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty ? NetworkImage(pet.photoUrl!) : null,
                child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                    ? Icon(Icons.pets_rounded, color: ClientPastelColors.mintDeep)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
