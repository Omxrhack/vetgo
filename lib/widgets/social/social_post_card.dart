import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:heroine/heroine.dart';

import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/social/vetgo_social_heroine_motion.dart';

/// Avatar del autor (alineado con compositor / _ComposeBox).
const double _kAuthorAvatarRadius = 22;
const double _kGapAvatarToName = 12;

/// Radio del contenedor tipo tarjeta (misma pista que _ComposeBox).
const double _kCardRadius = 16;

/// Izquierda del texto del post alineada con el nombre: padding card + avatar + hueco.
double _bodyTextStartPadding(double horizontalPadding) =>
    horizontalPadding + _kAuthorAvatarRadius * 2 + _kGapAvatarToName;

/// Cuerpo del post envuelto en [Heroine]: con altura máxima finita (overlay) usa scroll;
/// [FittedBox] no garantiza evitar overflow del [Column] hijo en todos los layouts.
Widget _socialHeroPostTail(List<Widget> children) {
  final column = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight;
      final finiteW = maxW.isFinite && maxW < double.infinity;
      final finiteH = maxH.isFinite && maxH < double.infinity;

      if (!finiteW && !finiteH) {
        return column;
      }

      Widget inner = column;
      if (finiteW) {
        inner = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: inner,
        );
      }

      if (finiteH) {
        return SizedBox(
          height: maxH,
          width: finiteW ? maxW : double.infinity,
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: inner,
            ),
          ),
        );
      }

      return inner;
    },
  );
}

Widget _maybeHeroineRepostAction({
  required String? tag,
  required Widget child,
  required ColorScheme scheme,
}) {
  if (tag == null) return child;
  // [Heroine] no aporta Material; [InkWell] en el hijo lo requiere para el splash.
  return Heroine(
    tag: tag,
    motion: vetgoSocialHeroCompactMotion,
    flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
    child: Material(
      type: MaterialType.transparency,
      child: child,
    ),
  );
}

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
    this.useElevatedChrome = true,
    this.recommendedFollowed = false,
    this.recommendedFollowLoading = false,
    this.onRecommendedFollowTap,
    this.heroinePostFlightTag,
    this.heroineAuthorFlightTag,
    this.heroineRepostFlightTag,
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

  /// Superficie redondeada como la caja de composición; `false` en pantalla de detalle.
  final bool useElevatedChrome;

  /// Feed «Descubre»: ya sigues al autor (muestra palomita en el avatar).
  final bool recommendedFollowed;

  /// Cargando seguimiento desde el botón + del avatar.
  final bool recommendedFollowLoading;

  /// Tap en + para seguir; si es null y [recommendedFollowed], solo se muestra la palomita.
  final VoidCallback? onRecommendedFollowTap;

  /// Tags [Heroine] opcionales (transiciones con `VetgoSocialHeroineRoute`).
  final String? heroinePostFlightTag;
  final String? heroineAuthorFlightTag;
  final String? heroineRepostFlightTag;

  static const double _hPad = 16;

  bool get _showRecommendedFollowBadge =>
      recommended &&
          (recommendedFollowed ||
              recommendedFollowLoading ||
              onRecommendedFollowTap != null);

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

    final baseParagraph = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      fontWeight: FontWeight.w400,
    );
    final quoteParagraph =
        theme.textTheme.bodyMedium?.copyWith(height: 1.45, fontWeight: FontWeight.w400);

    final threadHeadChildren = <Widget>[
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
              p: quoteParagraph,
              strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
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
          showRecommendedFollowBadge: _showRecommendedFollowBadge,
          recommendedFollowed: recommendedFollowed,
          recommendedFollowLoading: recommendedFollowLoading,
          onRecommendedFollowTap: onRecommendedFollowTap,
          heroineAuthorFlightTag: heroineAuthorFlightTag,
        ),
      ),
    ];

    final threadTailChildren = <Widget>[
      if (displayPost.body.isNotEmpty)
        Padding(
          padding: EdgeInsets.fromLTRB(_bodyTextStartPadding(_hPad), 1, _hPad, 0),
          child: MarkdownBody(
            data: displayPost.body,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              blockSpacing: 6,
              h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              p: baseParagraph,
              strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      if (displayPost.imageUrls.isNotEmpty) ...[
        SizedBox(height: displayPost.body.isNotEmpty ? 14 : 10),
        SocialPostImageGrid(urls: displayPost.imageUrls),
      ],
    ];

    Widget tailSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: threadTailChildren,
    );
    final postTag = heroinePostFlightTag;
    if (postTag != null) {
      tailSection = Heroine(
        tag: postTag,
        motion: vetgoSocialHeroPostMotion,
        flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
        continuouslyTrackTarget: true,
        child: threadTailChildren.isEmpty
            ? const SizedBox.shrink()
            : _socialHeroPostTail(threadTailChildren),
      );
    }

    Widget threadSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [...threadHeadChildren, tailSection],
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
              _maybeHeroineRepostAction(
                scheme: scheme,
                tag: heroineRepostFlightTag,
                child: _SocialTrailingAction(
                  icon: Icons.repeat_rounded,
                  activeIcon: Icons.repeat_rounded,
                  theme: theme,
                  scheme: scheme,
                  count: displayPost.repostCount,
                  activeAsBrand: displayPost.viewerHasReposted,
                  brandGreen: brandGreen,
                  onPressed: onRepost ?? () {},
                ),
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

    if (useElevatedChrome) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
          child: inner,
        ),
      );
    }

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
    return 10;
  }
}

class _AuthorHeaderRow extends StatelessWidget {
  const _AuthorHeaderRow({
    required this.post,
    required this.theme,
    required this.scheme,
    required this.timeLabel,
    this.onAuthorTap,
    this.showRecommendedFollowBadge = false,
    this.recommendedFollowed = false,
    this.recommendedFollowLoading = false,
    this.onRecommendedFollowTap,
    this.heroineAuthorFlightTag,
  });

  final PostVm post;
  final ThemeData theme;
  final ColorScheme scheme;
  final String timeLabel;
  final VoidCallback? onAuthorTap;
  final bool showRecommendedFollowBadge;
  final bool recommendedFollowed;
  final bool recommendedFollowLoading;
  final VoidCallback? onRecommendedFollowTap;
  final String? heroineAuthorFlightTag;

  @override
  Widget build(BuildContext context) {
    final nameBlock = Text.rich(
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
    );

    Widget avatar = CircleAvatar(
      radius: _kAuthorAvatarRadius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage:
          post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty
              ? NetworkImage(post.author.avatarUrl!)
              : null,
      child: post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty
          ? Icon(Icons.person_rounded, size: 22, color: scheme.primary)
          : null,
    );
    final authorTag = heroineAuthorFlightTag;
    if (authorTag != null) {
      avatar = Heroine(
        tag: authorTag,
        motion: vetgoSocialHeroAvatarMotion,
        flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
        continuouslyTrackTarget: true,
        child: SizedBox(
          width: _kAuthorAvatarRadius * 2,
          height: _kAuthorAvatarRadius * 2,
          child: avatar,
        ),
      );
    }

    final avatarLayer = SizedBox(
      width: _kAuthorAvatarRadius * 2,
      height: _kAuthorAvatarRadius * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (onAuthorTap != null)
            GestureDetector(onTap: onAuthorTap, child: avatar)
          else
            avatar,
          if (showRecommendedFollowBadge)
            Positioned(
              right: -4,
              bottom: -4,
              child: _RecommendedFollowAvatarBadge(
                scheme: scheme,
                followed: recommendedFollowed,
                loading: recommendedFollowLoading,
                onTap: onRecommendedFollowTap,
              ),
            ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatarLayer,
        const SizedBox(width: _kGapAvatarToName),
        Expanded(
          child: onAuthorTap != null
              ? GestureDetector(
                  onTap: onAuthorTap,
                  behavior: HitTestBehavior.opaque,
                  child: nameBlock,
                )
              : nameBlock,
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
  }
}

/// Botón + / palomita superpuesto en la esquina del avatar (posts recomendados).
class _RecommendedFollowAvatarBadge extends StatelessWidget {
  const _RecommendedFollowAvatarBadge({
    required this.scheme,
    required this.followed,
    required this.loading,
    this.onTap,
  });

  final ColorScheme scheme;
  final bool followed;
  final bool loading;
  final VoidCallback? onTap;

  static const double _size = 26;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: followed ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.65),
      width: 1.2,
    );
    final bg = followed ? scheme.primary : scheme.surface;
    final fg = followed ? scheme.onPrimary : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : (followed ? null : onTap),
        customBorder: const CircleBorder(),
        child: Ink(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: loading
                  ? SizedBox(
                      key: const ValueKey<String>('loading'),
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      followed ? Icons.check_rounded : Icons.add_rounded,
                      key: ValueKey<bool>(followed),
                      size: 16,
                      color: fg,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialTrailingAction extends StatefulWidget {
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
  State<_SocialTrailingAction> createState() => _SocialTrailingActionState();
}

class _SocialTrailingActionState extends State<_SocialTrailingAction> {
  bool _pressed = false;

  static const Duration _switchDuration = Duration(milliseconds: 200);
  static const Duration _pressDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    final muted = widget.scheme.onSurface.withValues(alpha: 0.62);
    final active = widget.brandGreen ?? widget.scheme.primary;
    final iconColor = widget.activeAsBrand ? active : muted;
    final iconData = widget.activeAsBrand ? widget.activeIcon : widget.icon;

    return InkWell(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: _pressDuration,
          curve: Curves.easeOut,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              AnimatedSwitcher(
                duration: _switchDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Icon(
                  iconData,
                  key: ValueKey<String>('${iconData}_${widget.activeAsBrand}'),
                  size: 22,
                  color: iconColor,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 5),
                AnimatedSwitcher(
                  duration: _switchDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${widget.count}',
                    key: ValueKey<int>(widget.count),
                    style: widget.theme.textTheme.labelMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
            ),
          ),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            urls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            alignment: Alignment.center,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: GridView.count(
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
      ),
    );
  }
}
