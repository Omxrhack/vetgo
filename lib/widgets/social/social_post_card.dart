import 'package:flutter/material.dart';

import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';

/// Tarjeta de publicación estilo feed (cabecera, texto, medios a todo ancho, acciones).
class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.theme,
    required this.scheme,
    required this.timeLabel,
    this.recommended = false,
    this.onDismissRecommended,
    this.onAuthorTap,
  });

  final PostVm post;
  final ThemeData theme;
  final ColorScheme scheme;
  final String timeLabel;

  /// Muestra la franja «Descubre…» con botón cerrar.
  final bool recommended;
  final VoidCallback? onDismissRecommended;
  final VoidCallback? onAuthorTap;

  static const double _hPad = 14;

  @override
  Widget build(BuildContext context) {
    return ClientSoftCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: VetSoftCard.radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recommended)
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 13,
                      color: scheme.onSurface.withValues(alpha: 0.38),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Descubre nuevo contenido',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.38),
                      ),
                    ),
                    const Spacer(),
                    if (onDismissRecommended != null)
                      IconButton(
                        onPressed: onDismissRecommended,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: scheme.onSurface.withValues(alpha: 0.3),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(_hPad, recommended ? 6 : 14, _hPad, 0),
              child: _AuthorHeaderRow(
                post: post,
                theme: theme,
                scheme: scheme,
                timeLabel: timeLabel,
                onAuthorTap: onAuthorTap,
              ),
            ),
            if (post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
                child: Text(
                  post.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                  ),
                ),
              ),
            if (post.imageUrls.isNotEmpty) ...[
              SizedBox(height: post.body.isNotEmpty ? 14 : 10),
              SocialPostImageGrid(urls: post.imageUrls),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionIcon(
                    icon: Icons.chat_bubble_outline_rounded,
                    scheme: scheme,
                    onPressed: () {},
                  ),
                  _ActionIcon(
                    icon: Icons.repeat_rounded,
                    scheme: scheme,
                    onPressed: () {},
                  ),
                  _ActionIcon(
                    icon: Icons.favorite_border_rounded,
                    scheme: scheme,
                    onPressed: () {},
                  ),
                  _ActionIcon(
                    icon: Icons.send_outlined,
                    scheme: scheme,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorHeaderRow extends StatelessWidget {
  const _AuthorHeaderRow({
    required this.post,
    required this.theme,
    required this.scheme,
    required this.timeLabel,
    this.onAuthorTap,
  });

  final PostVm post;
  final ThemeData theme;
  final ColorScheme scheme;
  final String timeLabel;
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: post.author.avatarUrl != null &&
                  post.author.avatarUrl!.isNotEmpty
              ? NetworkImage(post.author.avatarUrl!)
              : null,
          child: post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty
              ? Icon(Icons.person_rounded, size: 20, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                children: [
                  TextSpan(text: post.author.fullName),
                  TextSpan(
                    text: ' · ',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  TextSpan(
                    text: timeLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_horiz_rounded,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    if (onAuthorTap == null) return row;
    return GestureDetector(
      onTap: onAuthorTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.scheme,
    required this.onPressed,
  });

  final IconData icon;
  final ColorScheme scheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = scheme.onSurface.withValues(alpha: 0.62);
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22, color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
    );
  }
}

/// Rejilla / imagen única a ancho completo del post (sin padding lateral).
class SocialPostImageGrid extends StatelessWidget {
  const SocialPostImageGrid({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          urls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      childAspectRatio: 1,
      children: urls
          .take(4)
          .map(
            (url) => Image.network(url, fit: BoxFit.cover),
          )
          .toList(),
    );
  }
}
