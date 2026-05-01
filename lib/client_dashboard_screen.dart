import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'emergency_sos_screen.dart';
import 'live_tracking_screen.dart';
import 'models/client_demo_data.dart';
import 'models/client_pet_vm.dart';
import 'pet_profile_screen.dart';
import 'store_screen.dart';
import 'theme/client_pastel.dart';
import 'widgets/client/async_endpoint_button.dart';
import 'widgets/client/client_soft_card.dart';
import 'widgets/client/pastel_quick_action_card.dart';

/// Home / dashboard principal del cliente (estùtica pastel Vetgo).
class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.pets,
    required this.onLogout,
  });

  final String userName;
  final String? profilePhotoUrl;
  final List<ClientPetVm> pets;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = ClientPastelColors.mutedOn(context);
    final displayName = userName.trim().isEmpty ? 'amigo' : userName.trim();

    return RefreshIndicator(
      color: scheme.primary,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 650));
      },
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
                tooltip: 'Cerrar sesiùn',
                icon: const Icon(Icons.logout_rounded),
                onPressed: onLogout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 56, bottom: 14),
              title: Text(
                'ùHola, $displayName!',
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
                                'Recordatorios',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Vacuna anual de Luna en 6 dùas ù Cita de revisiùn Michi el jueves',
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
                    'Accesos rùpidos',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      PastelQuickActionCard(
                        icon: Icons.emergency_rounded,
                        label: 'Urgencia\n24/7',
                        backgroundColor: ClientPastelColors.coralSoft.withValues(alpha: 0.65),
                        iconColor: scheme.error.withValues(alpha: 0.85),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const EmergencySOSScreen()),
                        ),
                      ),
                      PastelQuickActionCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Agendar\nVisita',
                        backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.55),
                        iconColor: ClientPastelColors.mintDeep,
                        onTap: () => _showScheduleDemo(context),
                      ),
                      PastelQuickActionCard(
                        icon: Icons.pets_rounded,
                        label: 'Mis\nMascotas',
                        backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.72),
                        iconColor: ClientPastelColors.skyDeep,
                        onTap: () {
                          final first = pets.isNotEmpty ? pets.first : ClientDemoData.pets.first;
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => PetProfileScreen(pet: first)),
                          );
                        },
                      ),
                      PastelQuickActionCard(
                        icon: Icons.storefront_rounded,
                        label: 'Tienda',
                        backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.72),
                        iconColor: scheme.secondary,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const StoreScreen()),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.05, end: 0, delay: 80.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tus mascotas',
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
                        child: const Text('Ver expediente'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 112,
                    child: pets.isEmpty
                        ? Text(
                            'Aùade una mascota para verla aquù.',
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
                    label: 'Simular cita en camino',
                    icon: Icons.location_searching_rounded,
                    loadingLabel: 'Conectandoù',
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
                            vetName: 'Dra. Hernùndez',
                            etaLabel: 'Llegada estimada: 14 min',
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

  void _showScheduleDemo(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom + 16, left: 16, right: 16),
          child: ClientSoftCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Agendar visita',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige fecha sugerida. Esta acciùn simula una llamada al servidor.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: ClientPastelColors.mutedOn(ctx),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 20),
                AsyncEndpointButton(
                  label: 'Confirmar solicitud',
                  icon: Icons.check_rounded,
                  loadingLabel: 'Agendandoù',
                  style: FilledButton.styleFrom(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary),
                  onPressed: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 1400));
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ClientPastelColors.mintSoft,
                backgroundImage: pet.photoUrl != null && pet.photoUrl!.isNotEmpty ? NetworkImage(pet.photoUrl!) : null,
                child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                    ? Icon(Icons.pets_rounded, color: ClientPastelColors.mintDeep)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
