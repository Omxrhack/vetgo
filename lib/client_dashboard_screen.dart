import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/client/client_quick_access_hub_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/live_tracking_screen.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/pet_profile_screen.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/pastel_quick_action_card.dart';
import 'package:vetgo/widgets/dashboard/dashboard_section.dart';
import 'package:vetgo/widgets/profile_photo_avatar.dart';

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
    this.onProfilePhotoUpdated,
  });

  final String userName;
  final String? profilePhotoUrl;
  final VoidCallback? onProfilePhotoUpdated;
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
            expandedHeight: 132,
            actions: [
              IconButton(
                tooltip: AppStrings.cerrarSesionTooltip,
                icon: const Icon(Icons.logout_rounded),
                onPressed: onLogout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 52, bottom: 12),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.holaNombre(displayName),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.dashboardClienteTagline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ProfilePhotoAvatar(
                    heroTag: 'client_avatar',
                    imageUrl: profilePhotoUrl,
                    placeholderBackground: ClientPastelColors.mintSoft,
                    placeholderIconColor: ClientPastelColors.mintDeep,
                    radius: 26,
                    onUploaded: onProfilePhotoUpdated,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (petsError != null && petsError!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClientSoftCard(
                        color: scheme.errorContainer.withValues(alpha: 0.35),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: scheme.error, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${AppStrings.mascotasErrorParcial} ($petsError)',
                                style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  DashboardSection(
                    title: AppStrings.recordatoriosTitulo,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 10,
                    child: ClientSoftCard(
                      color: ClientPastelColors.amberSoft.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            color: ClientPastelColors.skyDeep,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.recordatoriosCuerpo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.03, end: 0, duration: 320.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.dashboardClienteSeccionAcciones,
                    subtitle: AppStrings.accesosHubSubtitulo,
                    subtitleColor: muted,
                    bottomSpacing: 22,
                    spacingBeforeChild: 14,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.apps_rounded,
                                label: AppStrings.quickActionServiciosLabel,
                                backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.72),
                                iconColor: ClientPastelColors.mintDeep,
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ClientQuickAccessHubScreen(pets: pets),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.storefront_rounded,
                                label: AppStrings.quickActionTiendaLabel,
                                backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.68),
                                iconColor: scheme.secondary,
                                onTap: () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.emergency_rounded,
                                label: AppStrings.quickActionEmergenciaLabel,
                                backgroundColor: ClientPastelColors.coralSoft.withValues(alpha: 0.62),
                                iconColor: scheme.error.withValues(alpha: 0.85),
                                onTap: onOpenEmergency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PastelQuickActionCard(
                                icon: Icons.location_searching_rounded,
                                label: AppStrings.quickActionTrackingLabel,
                                backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                                iconColor: ClientPastelColors.skyDeep,
                                onTap: () async {
                                  await Future<void>.delayed(const Duration(milliseconds: 420));
                                  if (!context.mounted) return;
                                  await Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LiveTrackingScreen(
                                        vetName: AppStrings.demoVetNombre,
                                        etaLabel: AppStrings.demoEta,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, delay: 50.ms, duration: 380.ms, curve: Curves.easeOutCubic),
                  DashboardSection(
                    title: AppStrings.tusMascotas,
                    subtitleColor: muted,
                    bottomSpacing: 20,
                    spacingBeforeChild: 12,
                    trailing: TextButton(
                      onPressed: pets.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => PetProfileScreen(pet: pets.first),
                                ),
                              );
                            },
                      child: const Text(AppStrings.verExpediente),
                    ),
                    child: SizedBox(
                      height: 148,
                      child: petsLoading && pets.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : pets.isEmpty
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppStrings.carouselSinMascotas,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: pets.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                                  itemBuilder: (context, i) {
                                    final p = pets[i];
                                    return _PetCarouselTile(
                                      pet: p,
                                      onTap: () {
                                        Navigator.of(context).push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) => PetProfileScreen(pet: p),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.04, end: 0, delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic),
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

    return SizedBox(
      width: 118,
      child: ClientSoftCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        color: theme.colorScheme.surface,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ClientPastelColors.mintSoft,
              backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty ? NetworkImage(pet.photoUrl!) : null,
              child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                  ? Icon(Icons.pets_rounded, color: ClientPastelColors.mintDeep, size: 28)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              pet.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
