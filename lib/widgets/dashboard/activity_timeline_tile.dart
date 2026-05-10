import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';

class ActivityTimelineTile extends StatelessWidget {
  const ActivityTimelineTile({
    super.key,
    required this.row,
    required this.isLast,
  });

  final Map<String, dynamic> row;
  final bool isLast;

  static Color dotColor(String? status, ColorScheme s) {
    switch (status) {
      case 'confirmed':
        return s.primary;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return s.error;
      case 'completed':
        return const Color(0xFF6B7280);
      default:
        return s.outlineVariant;
    }
  }

  static Color chipBg(String? status, ColorScheme s) {
    switch (status) {
      case 'confirmed':
        return s.primary.withValues(alpha: 0.12);
      case 'pending':
        return const Color(0xFFF59E0B).withValues(alpha: 0.12);
      case 'cancelled':
        return s.error.withValues(alpha: 0.12);
      case 'completed':
        return s.surfaceContainerHighest;
      default:
        return s.surfaceContainerHighest;
    }
  }

  static String chipLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmada';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      default:
        return status ?? 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final scheduledRaw = row['scheduled_at']?.toString();
    final dt = scheduledRaw != null ? DateTime.tryParse(scheduledRaw)?.toLocal() : null;
    final whenLabel = dt != null
        ? '${DateFormat('d MMM yyyy', 'es').format(dt)} · ${DateFormat.Hm('es').format(dt)}'
        : '—';

    final petMap = row['pet'] is Map<String, dynamic> ? row['pet'] as Map<String, dynamic> : {};
    final petName = petMap['name']?.toString().trim().isNotEmpty == true
        ? petMap['name']!.toString().trim()
        : AppStrings.vetMascota;

    final status = row['status']?.toString().trim();
    final dot = dotColor(status, scheme);
    final bg = chipBg(status, scheme);
    final label = chipLabel(status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          whenLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: dot,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
