import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:vetgo/models/social_models.dart';

/// Avatar del autor en cabecera (debe coincidir con el sangrado del cuerpo).
const double _kAuthorAvatarRadius = 20;
const double _kGapAvatarToName = 10;

/// Izquierda del texto del post alineada con el nombre: padding card + avatar + hueco.
double _bodyTextStartPadding(double horizontalPadding) =>
    horizontalPadding + _kAuthorAvatarRadius * 2 + _kGapAvatarToName;

/// Tarjeta de publicación estilo feed (cabecera, texto Markdown, medios, acciones).
class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.displayPost,
    required this.theme,
    required this.scheme,
    required this.timeLabel,
    this.reposter,
    this.quoteBody,
    this.recommended = false,
    this.onDismissRecommended,
    this.onAuthorTap,
    this.onRepost,
    this.onCommentTap,
    this.onLikeTap,
    this.onShareTap,
    this.onOpenThread,
    this.brandGreen = const Color(0xFF1B8A4E),
    this.showBottomDivider = true,
  });

  /// Contenido principal (post original; en repost es el citado).
  final PostVm displayPost;
  final ThemeData theme;
  final ColorScheme scheme;
  final String timeLabel;

  /// Si no es null, muestra la etiqueta «X reposteó» arriba.
  final PostAuthorVm? reposter;
  final String? quoteBody;

  /// Muestra la franja «Descubre…» con botón cerrar.
  final bool recommended;
  final VoidCallback? onDismissRecommended;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onRepost;
  final VoidCallback? onCommentTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onShareTap;
  /// Tap en el cuerpo del post (abrir hilo / detalle).
  final VoidCallback? onOpenThread;

  /// Verde marca (corazón relleno / repost propio).
  final Color brandGreen;

  final bool showBottomDivider;

  static const double _hPad = 16;

  @override
  Widget build(BuildContext context) {
    final Widget? discoverBanner = recommended
        ? Padding(
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
          )
        : null;

    final threadChildren = <Widget>[
      if (reposter != null)
        Padding(
          padding: EdgeInsets.fromLTRB(_hPad, recommended ? 6 : 12, _hPad, 0),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                    children: [
                      TextSpan(
                        text: reposter!.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' reposteó'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      if (quoteBody != null && quoteBody!.trim().isNotEmpty)
        Padding(
          padding: EdgeInsets.fromLTRB(
            _bodyTextStartPadding(_hPad),
            reposter != null ? 10 : (recommended ? 6 : 14),
            _hPad,
            0,
          ),
          child: MarkdownBody(
            data: quoteBody!,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          _hPad,
          _topPaddingForAuthor(recommended, reposter, quoteBody),
          _hPad,
          0,
        ),
        child: _AuthorHeaderRow(
          post: displayPost,
          theme: theme,
          scheme: scheme,
          timeLabel: timeLabel,
          onAuthorTap: onAuthorTap,
        ),
      ),
      if (displayPost.body.isNotEmpty)
        Padding(
          padding: EdgeInsets.fromLTRB(_bodyTextStartPadding(_hPad), 12, _hPad, 0),
          child: MarkdownBody(
            data: displayPost.body,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      if (displayPost.imageUrls.isNotEmpty) ...[
        SizedBox(height: displayPost.body.isNotEmpty ? 14 : 10),
        SocialPostImageGrid(urls: displayPost.imageUrls),
      ],
    ];

    Widget threadSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: threadChildren,
    );
    if (onOpenThread != null) {
      threadSection = GestureDetector(
        onTap: onOpenThread,
        behavior: HitTestBehavior.translucent,
        child: threadSection,
      );
    }

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?discoverBanner,
        threadSection,
        Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SocialTrailingAction(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_outline_rounded,
                theme: theme,
                scheme: scheme,
                count: displayPost.commentCount,
                onPressed: onCommentTap ?? () {},
              ),
              const SizedBox(width: 18),
              _SocialTrailingAction(
                icon: Icons.repeat_rounded,
                activeIcon: Icons.repeat_rounded,
                theme: theme,
                scheme: scheme,
                count: displayPost.repostCount,
                activeAsBrand: displayPost.viewerHasReposted,
                brandGreen: brandGreen,
                onPressed: onRepost ?? () {},
              ),
              const SizedBox(width: 18),
              _SocialTrailingAction(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                theme: theme,
                scheme: scheme,
                count: displayPost.likeCount,
                activeAsBrand: displayPost.viewerHasLiked,
                brandGreen: brandGreen,
                onPressed: onLikeTap ?? () {},
              ),
              const SizedBox(width: 18),
              _SocialTrailingAction(
                icon: Icons.share_outlined,
                activeIcon: Icons.share_outlined,
                theme: theme,
                scheme: scheme,
                onPressed: onShareTap ?? () {},
              ),
            ],
          ),
        ),
      ],
    );

    if (!showBottomDivider) return inner;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: inner,
    );
  }

  double _topPaddingForAuthor(bool rec, PostAuthorVm? rep, String? quote) {
    if (rep != null) return quote != null && quote.trim().isNotEmpty ? 12 : 10;
    if (rec) return 6;
    return 14;
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
          radius: _kAuthorAvatarRadius,
          backgroundColor: scheme.primaryContainer,
          backgroundImage:
              post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty
                  ? NetworkImage(post.author.avatarUrl!)
                  : null,
          child: post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty
              ? Icon(Icons.person_rounded, size: 20, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: _kGapAvatarToName),
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

class _SocialTrailingAction extends StatelessWidget {
  const _SocialTrailingAction({
    required this.icon,
    required this.activeIcon,
    required this.theme,
    required this.scheme,
    required this.onPressed,
    this.count = 0,
    this.activeAsBrand = false,
    this.brandGreen,
  });

  final IconData icon;
  final IconData activeIcon;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onPressed;
  final int count;
  final bool activeAsBrand;
  final Color? brandGreen;

  @override
  Widget build(BuildContext context) {
    final muted = scheme.onSurface.withValues(alpha: 0.62);
    final active = brandGreen ?? scheme.primary;
    final iconColor = activeAsBrand ? active : muted;
    final iconData = activeAsBrand ? activeIcon : icon;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 22, color: iconColor),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
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
