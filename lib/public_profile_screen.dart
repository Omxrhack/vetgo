import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroine/heroine.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:vetgo/core/navigation/social_heroine_tags.dart';
import 'package:vetgo/core/navigation/vetgo_social_heroine_route.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/repost_compose_screen.dart';
import 'package:vetgo/social_post_detail_screen.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/social/social_post_card.dart';
import 'package:vetgo/widgets/social/vetgo_social_heroine_motion.dart';

const Color _vetgoGreenProfile = Color(0xFF1B8A4E);

/// Pantalla de perfil público estilo profesional.
/// Reutilizable para vets, clientes, y el propio usuario (isOwnProfile = true).
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.profileId,
    this.isOwnProfile = false,
    this.onBookTap,
    this.heroineAvatarFlightTag,
  });

  final String profileId;
  final bool isOwnProfile;
  final VoidCallback? onBookTap;

  /// Coincide con el [Heroine] del avatar al abrir el perfil desde el feed Social.
  final String? heroineAvatarFlightTag;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  final _api = VetgoApiClient();

  PublicProfileVm? _profile;
  List<FeedEntryVm> _feedEntries = [];
  List<ReviewVm> _reviews = [];
  bool _loading = true;
  bool _followLoading = false;
  String? _error;

  final Set<String> _pendingLikePostIds = {};

  TabController? _tabController;

  void _syncTabsForRole(bool isVet) {
    final len = isVet ? 4 : 3;
    if (_tabController != null && _tabController!.length == len) return;
    _tabController?.dispose();
    _tabController = TabController(length: len, vsync: this);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _tabController?.dispose();
      _tabController = null;
      _load(resetLists: true);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load({bool resetLists = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (resetLists) {
        _feedEntries = [];
        _reviews = [];
      }
    });
    final (data, err) = await _api.getPublicProfile(widget.profileId);
    if (!mounted) return;
    if (err != null || data == null) {
      setState(() {
        _error = err ?? 'Error al cargar el perfil';
        _loading = false;
      });
      return;
    }
    final profile = PublicProfileVm.fromJson(data);
    _syncTabsForRole(profile.isVet);
    setState(() {
      _profile = profile;
      _loading = false;
    });
    _loadPosts();
    if (profile.isVet) _loadReviews();
  }

  Future<void> _loadPosts() async {
    final (data, _) = await _api.getUserPosts(widget.profileId);
    if (!mounted || data == null) return;
    final list = (data['posts'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(FeedEntryVm.fromJson)
            .toList() ??
        [];
    setState(() => _feedEntries = filterProfileFeedPosts(list));
  }

  Future<void> _loadReviews() async {
    final (data, _) = await _api.getProfileReviews(widget.profileId);
    if (!mounted || data == null) return;
    final list = (data['reviews'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ReviewVm.fromJson)
            .toList() ??
        [];
    setState(() => _reviews = list);
  }

  FeedEntryVm _entryWithUpdatedPost(FeedEntryVm e, PostVm p) {
    switch (e) {
      case FeedPostEntryVm(:final feedAt):
        return FeedPostEntryVm(feedAt: feedAt, post: p);
      case FeedRepostEntryVm(
          :final feedAt,
          :final repostId,
          :final quoteBody,
          :final reposter,
        ):
        return FeedRepostEntryVm(
          feedAt: feedAt,
          repostId: repostId,
          quoteBody: quoteBody,
          reposter: reposter,
          originalPost: p,
        );
    }
  }

  void _patchFeedPost(PostVm updated) {
    setState(() {
      _feedEntries = _feedEntries.map((e) {
        if (e.displayPost.id != updated.id) return e;
        return _entryWithUpdatedPost(e, updated);
      }).toList();
    });
  }

  Future<void> _handleFeedLike(PostVm post) async {
    if (_pendingLikePostIds.contains(post.id)) return;
    _pendingLikePostIds.add(post.id);

    final optimistic = post.copyWith(
      viewerHasLiked: !post.viewerHasLiked,
      likeCount: post.viewerHasLiked
          ? (post.likeCount - 1).clamp(0, 999999)
          : post.likeCount + 1,
    );
    _patchFeedPost(optimistic);

    final (data, err) = await _api.togglePostLike(post.id);
    if (!mounted) {
      _pendingLikePostIds.remove(post.id);
      return;
    }
    if (err != null || data == null) {
      _patchFeedPost(post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No se pudo actualizar')),
      );
      _pendingLikePostIds.remove(post.id);
      return;
    }
    _patchFeedPost(
      optimistic.copyWith(
        likeCount: (data['like_count'] as num?)?.toInt() ?? optimistic.likeCount,
        viewerHasLiked: data['viewer_has_liked'] as bool? ?? optimistic.viewerHasLiked,
      ),
    );
    _pendingLikePostIds.remove(post.id);
  }

  Future<void> _openFeedPostDetail(FeedEntryVm entry) async {
    final display = entry.displayPost;
    final timeLabel = DateFormat('d MMM · HH:mm', 'es').format(display.createdAt);
    final PostAuthorVm? reposter;
    final String? quoteBody;
    switch (entry) {
      case FeedRepostEntryVm r:
        reposter = r.reposter;
        quoteBody = r.quoteBody;
      case FeedPostEntryVm():
        reposter = null;
        quoteBody = null;
    }

    final updated = await Navigator.of(context).push<PostVm>(
      VetgoSocialHeroineRoute<PostVm>(
        builder: (ctx) => SocialPostDetailScreen(
          api: _api,
          initialPost: display,
          timeLabel: timeLabel,
          reposter: reposter,
          quoteBody: quoteBody,
          brandGreen: _vetgoGreenProfile,
          heroinePostFlightTag: vetgoSocialPostHeroTag(display.id),
          heroineAuthorFlightTag: vetgoSocialAuthorAvatarFlightTag(display.id),
          onAuthorTap: () {
            Navigator.of(ctx).push<void>(
              VetgoSocialHeroineRoute<void>(
                builder: (_) => PublicProfileScreen(
                  profileId: display.author.id,
                  heroineAvatarFlightTag:
                      vetgoSocialAuthorAvatarFlightTag(display.id),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (updated != null && mounted) _patchFeedPost(updated);
  }

  void _shareFeedPost(PostVm post) {
    Share.share(
      '${post.author.fullName}: ${post.body}',
      subject: 'Vetgo Social',
    );
  }

  Future<void> _toggleFollow() async {
    final p = _profile;
    if (p == null || _followLoading) return;
    setState(() => _followLoading = true);
    if (p.isFollowing) {
      await _api.unfollowUser(p.id);
      if (mounted) {
        setState(() {
          _profile = p.copyWith(
            isFollowing: false,
            followersCount: (p.followersCount - 1).clamp(0, 9999999),
          );
          _followLoading = false;
        });
      }
    } else {
      await _api.followUser(p.id);
      if (mounted) {
        setState(() {
          _profile = p.copyWith(
            isFollowing: true,
            followersCount: p.followersCount + 1,
          );
          _followLoading = false;
        });
      }
    }
  }

  void _openEditSheet() async {
    final refreshed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profileId: widget.profileId),
    );
    if (refreshed == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildProfile(context),
    );
  }

  Widget _buildProfile(BuildContext context) {
    final p = _profile!;
    final wantLen = p.isVet ? 4 : 3;
    // Tras hot reload el TabController puede quedar con otra longitud que las pestañas actuales.
    if (_tabController == null || _tabController!.length != wantLen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final prof = _profile;
        if (prof == null) return;
        _syncTabsForRole(prof.isVet);
        if (mounted) setState(() {});
      });
      return const Center(child: CircularProgressIndicator());
    }
    final tc = _tabController!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return NestedScrollView(
      // Permite que el avatar sobresalga del bloque blanco sin recorte respecto al banner.
      clipBehavior: Clip.none,
      headerSliverBuilder: (ctx, _) => [
        // ── Banner SliverAppBar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 145,
          // Sin pinned: el bloque verde no se queda encima del contenido al hacer scroll
          // y el avatar no queda “debajo” de la barra.
          pinned: false,
          floating: true,
          snap: true,
          clipBehavior: Clip.none,
          backgroundColor: scheme.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          // Back button with semi-transparent pill background
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
          actions: [
            if (widget.isOwnProfile)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _openEditSheet,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 17, color: Colors.white),
                  ),
                ),
              ),
          ],
          // Title only visible when collapsed
          title: _CollapsedTitle(fullName: p.fullName, theme: theme),
          flexibleSpace: FlexibleSpaceBar(
            background: _BannerBackground(isVet: p.isVet),
          ),
        ),

        // ── Header content (card + avatar en Stack para superponer sin recorte) ─
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            clipBehavior: Clip.none,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 102),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _ActionButton(
                                  profile: p,
                                  isOwnProfile: widget.isOwnProfile,
                                  followLoading: _followLoading,
                                  onFollow: _toggleFollow,
                                  onBook: widget.onBookTap,
                                  onEdit: _openEditSheet,
                                  theme: theme,
                                  scheme: scheme,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Transform.translate(
                        offset: const Offset(0, -26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    p.fullName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (p.isVet) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: scheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 11, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),

                            // Rol: perfil profesional vs comunidad
                            const SizedBox(height: 6),
                            _ProfileRoleHeader(
                                profile: p, scheme: scheme, theme: theme),

                            // Specialty chip (solo MVZ)
                            if (p.isVet && p.vet?.specialty != null) ...[
                              const SizedBox(height: 5),
                              _SpecialtyChip(
                                  specialty: p.vet!.specialty!,
                                  scheme: scheme,
                                  theme: theme),
                            ],

                            // Bio
                            if (p.bio != null && p.bio!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                p.bio!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.75),
                                  height: 1.45,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            // Location
                            if (p.location != null &&
                                p.location!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.place_outlined,
                                      size: 13,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.location!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Follower counts — flat text style Threads
                            const SizedBox(height: 10),
                            _FollowCountRow(
                                profile: p, theme: theme, scheme: scheme),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 280.ms)
                            .slideY(
                              begin: 0.02,
                              end: 0,
                              duration: 280.ms,
                              curve: Curves.easeOutCubic),
                      ),

                      // Vet stats — big numbers
                      if (p.isVet && p.vet != null) ...[
                        const SizedBox(height: 4),
                        _VetBigStatsRow(
                            vet: p.vet!, theme: theme, scheme: scheme),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  top: -48,
                  child: Material(
                    type: MaterialType.transparency,
                    elevation: 20,
                    shadowColor: Colors.black.withValues(alpha: 0.55),
                    surfaceTintColor: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.none,
                    child: _ProfileAvatar(
                      avatarUrl: p.avatarUrl,
                      isVet: p.isVet,
                      scheme: scheme,
                      heroineFlightTag: widget.heroineAvatarFlightTag,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Pinned TabBar ────────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              key: ValueKey<String>('profile_tabs_${p.id}_${p.isVet}'),
              controller: tc,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.4),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: scheme.primary.withValues(alpha: 0.10),
              ),
              dividerColor: Colors.transparent,
              labelStyle: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: theme.textTheme.labelSmall,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: p.isVet
                  ? const [
                      Tab(
                          icon: Icon(Icons.article_outlined, size: 17),
                          text: 'Feed'),
                      Tab(
                          icon: Icon(Icons.grid_view_rounded, size: 17),
                          text: 'Galería'),
                      Tab(
                          icon: Icon(Icons.star_outline_rounded, size: 17),
                          text: 'Reseñas'),
                      Tab(
                          icon: Icon(Icons.local_hospital_outlined, size: 17),
                          text: 'Consultorio'),
                    ]
                  : const [
                      Tab(
                          icon: Icon(Icons.article_outlined, size: 17),
                          text: 'Feed'),
                      Tab(
                          icon: Icon(Icons.photo_library_outlined, size: 17),
                          text: 'Fotos'),
                      Tab(
                          icon: Icon(Icons.auto_awesome_outlined, size: 17),
                          text: 'Momentos'),
                    ],
            ),
            color: scheme.surfaceContainerLowest,
            borderColor: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
      body: TabBarView(
        key: ValueKey<String>('profile_body_${p.id}_${p.isVet}'),
        controller: tc,
        clipBehavior: Clip.none,
        children: p.isVet
            ? [
                _buildFeedTab(theme, scheme),
                _PhotosTab(entries: _feedEntries, scheme: scheme),
                _ReviewsTab(
                  reviews: _reviews,
                  isVet: true,
                  theme: theme,
                  scheme: scheme,
                ),
                _ConsultorioTab(profile: p, theme: theme, scheme: scheme),
              ]
            : [
                _buildFeedTab(theme, scheme),
                _PhotosTab(entries: _feedEntries, scheme: scheme),
                _MomentosTab(
                  entries: _feedEntries,
                  theme: theme,
                  scheme: scheme,
                ),
              ],
      ),
    );
  }

  Widget _buildFeedTab(ThemeData theme, ColorScheme scheme) {
    return _FeedTab(
      entries: _feedEntries,
      theme: theme,
      scheme: scheme,
      brandGreen: _vetgoGreenProfile,
      onLikePost: _handleFeedLike,
      onOpenPostDetail: _openFeedPostDetail,
      onSharePost: _shareFeedPost,
      onRepostDone: (entry) {
        final u = entry.displayPost;
        setState(() {
          _feedEntries = filterProfileFeedPosts([
            entry,
            ..._feedEntries.map((e) {
              if (e.displayPost.id != u.id) return e;
              return _entryWithUpdatedPost(e, u);
            }),
          ]);
        });
      },
    );
  }
}

// ─── Banner background ────────────────────────────────────────────────────────

class _BannerBackground extends StatelessWidget {
  const _BannerBackground({required this.isVet});

  /// Veterinario: verde clínico + patas. Comunidad: tonos más cálidos + corazones.
  final bool isVet;

  @override
  Widget build(BuildContext context) {
    final gradient = isVet
        ? const LinearGradient(
            colors: [Color(0xFF1B8A4E), Color(0xFF0D5C34)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF2D9B62), Color(0xFF6BBF8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: BoxDecoration(gradient: gradient)),
        Opacity(
          opacity: isVet ? 0.07 : 0.09,
          child: CustomPaint(
            painter:
                isVet ? _PawPatternPainter() : _HeartPatternPainter(),
          ),
        ),
        if (isVet)
          Positioned(
            right: -20,
            top: 24,
            child: Icon(
              Icons.medical_services_outlined,
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        // Marca Vetgo en el banner (chip legible sobre el patrón).
        Positioned(
          right: 14,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Vetgo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.0,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Patrón suave de corazones para perfiles de comunidad (no clínico).
class _HeartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const step = 52.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        final ox = x + ((y / step).floor() % 2) * (step / 2);
        _drawTinyHeart(canvas, Offset(ox + step * 0.35, y + step * 0.4), 5.5, paint);
      }
    }
  }

  void _drawTinyHeart(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.35)
      ..cubicTo(c.dx - r, c.dy - r * 0.9, c.dx - r * 1.2, c.dy + r * 0.2, c.dx, c.dy + r * 1.1)
      ..cubicTo(c.dx + r * 1.2, c.dy + r * 0.2, c.dx + r, c.dy - r * 0.9, c.dx, c.dy + r * 0.35)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PawPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 60.0;
    const pawRadius = 7.0;
    const toeRadius = 4.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final cx = x + (y / spacing).floor() % 2 * (spacing / 2);
        // Main pad
        canvas.drawCircle(Offset(cx, y), pawRadius, paint);
        // 4 toes
        final toePositions = [
          Offset(cx - 10, y - 10),
          Offset(cx - 4, y - 13),
          Offset(cx + 4, y - 13),
          Offset(cx + 10, y - 10),
        ];
        for (final pos in toePositions) {
          canvas.drawCircle(pos, toeRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PawPatternPainter old) => false;
}

// ─── Collapsed title (visible only when AppBar is pinned/collapsed) ───────────

class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle({required this.fullName, required this.theme});

  final String fullName;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      fullName,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

// ─── Avatar with badge + white border ────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.isVet,
    required this.scheme,
    this.heroineFlightTag,
  });

  final String? avatarUrl;
  final bool isVet;
  final ColorScheme scheme;
  final String? heroineFlightTag;

  @override
  Widget build(BuildContext context) {
    final hasImg = avatarUrl != null && avatarUrl!.isNotEmpty;
    Widget avatarCore = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 44,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: hasImg ? NetworkImage(avatarUrl!) : null,
        child: !hasImg
            ? Icon(Icons.person_rounded, size: 44, color: scheme.primary)
            : null,
      ),
    );
    final tag = heroineFlightTag;
    if (tag != null) {
      avatarCore = Heroine(
        tag: tag,
        motion: vetgoSocialHeroAvatarMotion,
        flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
        continuouslyTrackTarget: true,
        child: avatarCore,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarCore,
        if (isVet)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.verified_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ─── Action button (Follow / Siguiendo / Editar perfil) ──────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.profile,
    required this.isOwnProfile,
    required this.followLoading,
    required this.onFollow,
    required this.onBook,
    required this.onEdit,
    required this.theme,
    required this.scheme,
  });

  final PublicProfileVm profile;
  final bool isOwnProfile;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback? onBook;
  final VoidCallback onEdit;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return OutlinedButton(
        onPressed: onEdit,
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        child: Text('Editar perfil',
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onBook != null) ...[
          OutlinedButton.icon(
            onPressed: onBook,
            icon: const Icon(Icons.calendar_today_rounded, size: 14),
            label: const Text('Agendar'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: scheme.primary),
              foregroundColor: scheme.primary,
              textStyle: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
        FilledButton(
          onPressed: followLoading ? null : onFollow,
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: profile.isFollowing
                ? scheme.surfaceContainerHigh
                : scheme.primary,
            foregroundColor:
                profile.isFollowing ? scheme.onSurface : scheme.onPrimary,
          ),
          child: followLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: profile.isFollowing
                          ? scheme.onSurface
                          : scheme.onPrimary),
                )
              : Text(
                  profile.isFollowing ? 'Siguiendo' : 'Seguir',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

// ─── Cabecera de rol (MVZ vs comunidad) ───────────────────────────────────────

class _ProfileRoleHeader extends StatelessWidget {
  const _ProfileRoleHeader({
    required this.profile,
    required this.scheme,
    required this.theme,
  });

  final PublicProfileVm profile;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (profile.isVet) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 15, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Médico veterinario verificado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final (String label, IconData icon) = switch (profile.role) {
      'owner' => ('Dueño de mascotas', Icons.pets_rounded),
      'client' => ('Familia Vetgo', Icons.family_restroom_rounded),
      'admin' => ('Equipo Vetgo', Icons.shield_outlined),
      _ => ('Comunidad Vetgo', Icons.waving_hand_rounded),
    };

    return Row(
      children: [
        Icon(icon,
            size: 16, color: scheme.onSurface.withValues(alpha: 0.42)),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.58),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Specialty chip ───────────────────────────────────────────────────────────

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip(
      {required this.specialty, required this.scheme, required this.theme});

  final String specialty;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services_outlined,
              size: 11, color: scheme.primary),
          const SizedBox(width: 5),
          Text(
            specialty,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Follow count row (flat text) ─────────────────────────────────────────────

class _FollowCountRow extends StatelessWidget {
  const _FollowCountRow(
      {required this.profile, required this.theme, required this.scheme});

  final PublicProfileVm profile;
  final ThemeData theme;
  final ColorScheme scheme;

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
            children: [
              TextSpan(
                text: _fmt(profile.followersCount),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.85)),
              ),
              const TextSpan(text: ' seguidores'),
              TextSpan(
                text: '  ·  ${_fmt(profile.followingCount)}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.85)),
              ),
              const TextSpan(text: ' siguiendo'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Vet stats big numbers ────────────────────────────────────────────────────

class _VetBigStatsRow extends StatelessWidget {
  const _VetBigStatsRow(
      {required this.vet, required this.theme, required this.scheme});

  final VetStatsVm vet;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final ratingStr =
        vet.avgRating != null ? vet.avgRating!.toStringAsFixed(1) : '—';
    final expStr =
        vet.yearsExperience != null ? '${vet.yearsExperience}' : '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
              width: 0.5),
          bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
              width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BigStat(
            value: vet.completedAppointments.toString(),
            label: 'Citas',
            theme: theme,
            scheme: scheme,
          ),
          _StatDivider(scheme: scheme),
          _BigStat(
            value: ratingStr,
            label: 'Rating',
            suffix: vet.avgRating != null ? '★' : null,
            suffixColor: const Color(0xFFF59E0B),
            theme: theme,
            scheme: scheme,
          ),
          _StatDivider(scheme: scheme),
          _BigStat(
            value: expStr,
            label: 'Años exp.',
            suffix: vet.yearsExperience != null ? 'a' : null,
            theme: theme,
            scheme: scheme,
          ),
          _StatDivider(scheme: scheme),
          _BigStat(
            value: vet.uniquePets.toString(),
            label: 'Mascotas',
            theme: theme,
            scheme: scheme,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: 80.ms)
        .slideY(begin: 0.02, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    this.suffix,
    this.suffixColor,
    required this.theme,
    required this.scheme,
  });

  final String value;
  final String label;
  final String? suffix;
  final Color? suffixColor;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                height: 1,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 1),
              Text(
                suffix!,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: suffixColor ?? scheme.primary,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: scheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

// ─── Tab bar delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar,
      {required this.color, required this.borderColor});

  final TabBar tabBar;
  final Color color;
  final Color borderColor;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: color,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, thickness: 1, color: borderColor),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.tabBar != tabBar || old.color != color;
}

// ─── Feed tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.entries,
    required this.theme,
    required this.scheme,
    required this.brandGreen,
    required this.onLikePost,
    required this.onOpenPostDetail,
    required this.onSharePost,
    required this.onRepostDone,
  });

  final List<FeedEntryVm> entries;
  final ThemeData theme;
  final ColorScheme scheme;
  final Color brandGreen;
  final Future<void> Function(PostVm post) onLikePost;
  final Future<void> Function(FeedEntryVm entry) onOpenPostDetail;
  final void Function(PostVm post) onSharePost;
  final void Function(FeedEntryVm entry) onRepostDone;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        icon: Icons.rss_feed_rounded,
        message: 'Aún sin publicaciones',
        scheme: scheme,
        theme: theme,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final entry = entries[i];
        final display = entry.displayPost;
        final (reposter, quoteBody) = switch (entry) {
          FeedRepostEntryVm r => (r.reposter, r.quoteBody),
          FeedPostEntryVm() => (null, null),
        };
        return SocialPostCard(
              displayPost: display,
              theme: theme,
              scheme: scheme,
              timeLabel: DateFormat('d MMM · HH:mm', 'es').format(display.createdAt),
              reposter: reposter,
              quoteBody: quoteBody,
              useElevatedChrome: true,
              brandGreen: brandGreen,
              heroinePostFlightTag: vetgoSocialPostHeroTag(display.id),
              heroineRepostFlightTag: vetgoSocialRepostHeroTag(display.id),
              onAuthorTap: null,
              onLikeTap: () => onLikePost(display),
              onCommentTap: () => onOpenPostDetail(entry),
              onOpenThread: () => onOpenPostDetail(entry),
              onShareTap: () => onSharePost(display),
              onRepost: () async {
                final res = await Navigator.of(context).push<FeedEntryVm>(
                  VetgoSocialHeroineRoute<FeedEntryVm>(
                    builder: (_) => RepostComposeScreen(
                      original: display,
                      heroineQuotedFlightTag:
                          vetgoSocialRepostHeroTag(display.id),
                    ),
                  ),
                );
                if (res != null && context.mounted) onRepostDone(res);
              },
            )
            .animate()
            .fadeIn(duration: 260.ms, delay: (i * 20).ms)
            .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.98, 0.98),
              end: const Offset(1, 1),
              duration: 260.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

// ─── Photos tab ───────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({required this.entries, required this.scheme});

  final List<FeedEntryVm> entries;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final images = entries.expand((e) => e.displayPost.imageUrls).toList();
    if (images.isEmpty) {
      return _EmptyState(
        icon: Icons.camera_alt_outlined,
        message: 'Aún sin fotos',
        scheme: scheme,
        theme: Theme.of(context),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => Image.network(images[i], fit: BoxFit.cover)
          .animate()
          .fadeIn(duration: 200.ms, delay: (i * 20).ms),
    );
  }
}

// ─── Reviews tab ──────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab(
      {required this.reviews,
      required this.isVet,
      required this.theme,
      required this.scheme});

  final List<ReviewVm> reviews;
  final bool isVet;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!isVet) {
      return _EmptyState(
        icon: Icons.rate_review_outlined,
        message: 'Las reseñas son solo para veterinarios',
        scheme: scheme,
        theme: theme,
      );
    }
    if (reviews.isEmpty) {
      return _EmptyState(
        icon: Icons.rate_review_outlined,
        message: 'Aún sin reseñas',
        scheme: scheme,
        theme: theme,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _ReviewCard(review: reviews[i], theme: theme, scheme: scheme)
              .animate()
              .fadeIn(duration: 260.ms, delay: (i * 40).ms)
              .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard(
      {required this.review, required this.theme, required this.scheme});

  final ReviewVm review;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('d MMM yyyy', 'es').format(review.createdAt);
    return ClientSoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: review.reviewer.avatarUrl != null &&
                        review.reviewer.avatarUrl!.isNotEmpty
                    ? NetworkImage(review.reviewer.avatarUrl!)
                    : null,
                child: review.reviewer.avatarUrl == null ||
                        review.reviewer.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 16, color: scheme.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewer.fullName,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: i < review.rating
                        ? const Color(0xFFF59E0B)
                        : scheme.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// ─── Consultorio (solo MVZ): credibilidad clínica, sin duplicar el feed ───────

class _ConsultorioTab extends StatelessWidget {
  const _ConsultorioTab({
    required this.profile,
    required this.theme,
    required this.scheme,
  });

  final PublicProfileVm profile;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        ClientSoftCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_hospital_rounded,
                      color: scheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Consulta profesional',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Agenda citas y revisa disponibilidad desde el mapa de Vetgo. '
                'Este perfil muestra experiencia acumulada y opiniones de familias que ya fueron atendidas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClientSoftCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.map_outlined,
                  size: 20, color: scheme.primary.withValues(alpha: 0.85)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación del consultorio',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.location != null &&
                              profile.location!.trim().isNotEmpty
                          ? profile.location!.trim()
                          : 'El mapa muestra veterinarios cercanos; confirma horario al agendar.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Momentos: vista social para dueños / clientes (no clínica) ───────────────

class _MomentosTab extends StatelessWidget {
  const _MomentosTab({
    required this.entries,
    required this.theme,
    required this.scheme,
  });

  final List<FeedEntryVm> entries;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        icon: Icons.auto_awesome_outlined,
        message:
            'Cuando publiques en el feed, tus momentos aparecerán aquí en orden breve.',
        scheme: scheme,
        theme: theme,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final post = entries[i].displayPost;
        final preview = post.body.length > 120
            ? '${post.body.substring(0, 117)}…'
            : post.body;
        final when =
            DateFormat('d MMM yyyy', 'es').format(post.createdAt);
        final thumb = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
        return ClientSoftCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    thumb,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      color: scheme.primary.withValues(alpha: 0.45)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 240.ms, delay: (i * 28).ms)
            .slideY(begin: 0.02, end: 0, duration: 240.ms);
      },
    );
  }
}

// ─── Edit profile sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profileId});

  final String profileId;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _bio = TextEditingController();
  final _location = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final (_, err) = await VetgoApiClient().updateMyProfile(
      bio: _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
      location: _location.text.trim().isNotEmpty ? _location.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Editar perfil',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Biografía',
                hintText: 'Cuéntanos sobre ti...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Ciudad / ubicación',
                prefixIcon: const Icon(Icons.place_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.message,
      required this.scheme,
      required this.theme});

  final IconData icon;
  final String message;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 28, color: scheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
