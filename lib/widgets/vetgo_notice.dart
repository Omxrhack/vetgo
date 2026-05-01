import 'dart:async';

import 'package:flutter/material.dart';

/// Temporary banner at the top of the screen (no [SnackBar]). Auto-dismiss after [duration].
abstract final class VetgoNotice {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = defaultDuration,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    final scheme = Theme.of(context).colorScheme;

    entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top + 12;
        return Positioned(
          left: 16,
          right: 16,
          top: top,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * -12),
                  child: child,
                ),
              );
            },
            child: Material(
              elevation: 8,
              shadowColor: scheme.shadow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              color: isError ? scheme.errorContainer : scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                      color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        entry.remove();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    unawaited(
      Future<void>.delayed(duration).then((_) {
        if (entry.mounted) {
          entry.remove();
        }
      }),
    );
  }
}
