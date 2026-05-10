import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/dashboard/activity_timeline_tile.dart';

class VetProfileScreen extends StatelessWidget {
  const VetProfileScreen({
    super.key,
    required this.vet,
    required this.appointments,
    required this.onBookTap,
  });

  final Map<String, dynamic> vet;
  final List<Map<String, dynamic>> appointments;
  final VoidCallback onBookTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final name = vet['full_name']?.toString() ?? '';
    final avatarUrl = vet['avatar_url']?.toString();
    final specialty = vet['specialty']?.toString().isNotEmpty == true
        ? vet['specialty'].toString()
        : 'Medicina veterinaria general';
    final since = DateTime.tryParse(vet['relationship_since']?.toString() ?? '');
    final sinceLabel = since != null
        ? 'Cliente desde ${DateFormat('MMMM yyyy', 'es').format(since)}'
        : 'Tu veterinario de confianza';

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: scheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Veterinario',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero card
                ClientSoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Icon(Icons.person_rounded, size: 40, color: scheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_rounded, size: 11, color: scheme.primary),
                                  const SizedBox(width: 5),
                                  Text(
                                    sinceLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 16),

                // CTA
                FilledButton.icon(
                  onPressed: onBookTap,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: const Text('Agendar cita'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ).animate().fadeIn(duration: 280.ms, delay: 60.ms).slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 20),

                // Info card
                ClientSoftCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.medical_services_outlined, color: scheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Especialidad',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              specialty,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 280.ms, delay: 100.ms).slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                // Timeline
                Text(
                  'Tus citas con este veterinario',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ).animate().fadeIn(duration: 280.ms, delay: 130.ms),

                const SizedBox(height: 12),

                if (appointments.isEmpty)
                  ClientSoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            size: 36, color: scheme.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 10),
                        Text(
                          'Sin citas registradas aún',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 280.ms, delay: 160.ms)
                else
                  ClientSoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        for (int i = 0; i < appointments.length; i++)
                          ActivityTimelineTile(
                            row: appointments[i],
                            isLast: i == appointments.length - 1,
                          ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 280.ms, delay: 160.ms).slideY(begin: 0.03, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
