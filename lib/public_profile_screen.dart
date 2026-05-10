import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';

/// Pantalla de perfil público estilo profesional.
/// Reutilizable para vets, clientes, y el propio usuario (isOwnProfile = true).
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.profileId,
    this.isOwnProfile = false,
    this.onBookTap,
  });

  final String profileId;
  final bool isOwnProfile;
  final VoidCallback? onBookTap;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  final _api = VetgoApiClient();

  PublicProfileVm? _profile;
  List<PostVm> _posts = [];
  List<ReviewVm> _reviews = [];
  bool _loading = true;
  bool _followLoading = false;
  String? _error;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
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
            .map(PostVm.fromJson)
            .toList() ??
        [];
    setState(() => _posts = list);
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        // ── Banner SliverAppBar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 145,
          pinned: true,
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
            background: _BannerBackground(avatarUrl: p.avatarUrl),
          ),
        ),

        // ── Header content (card flota sobre el banner) ─────────────────
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + action button row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -44),
                      child: _ProfileAvatar(
                        avatarUrl: p.avatarUrl,
                        isVet: p.isVet,
                        scheme: scheme,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                  ],
                ),

                // Name + verification badge
                Transform.translate(
                  offset: const Offset(0, -32),
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

                      // Specialty chip
                      if (p.vet?.specialty != null) ...[
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
                      if (p.location != null && p.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 13,
                                color:
                                    scheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              p.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Follower counts — flat text style Threads
                      const SizedBox(height: 10),
                      _FollowCountRow(profile: p, theme: theme, scheme: scheme),
                    ],
                  ).animate().fadeIn(duration: 280.ms).slideY(
                      begin: 0.02,
                      end: 0,
                      duration: 280.ms,
                      curve: Curves.easeOutCubic),
                ),

                // Vet stats — big numbers
                if (p.isVet && p.vet != null) ...[
                  const SizedBox(height: 4),
                  _VetBigStatsRow(vet: p.vet!, theme: theme, scheme: scheme),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),

        // ── Pinned TabBar ────────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
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
              tabs: const [
                Tab(icon: Icon(Icons.article_outlined, size: 17), text: 'Feed'),
                Tab(
                    icon: Icon(Icons.photo_library_outlined, size: 17),
                    text: 'Fotos'),
                Tab(
                    icon: Icon(Icons.star_outline_rounded, size: 17),
                    text: 'Reseñas'),
                Tab(
                    icon: Icon(Icons.timeline_rounded, size: 17),
                    text: 'Actividad'),
              ],
            ),
            color: scheme.surfaceContainerLowest,
            borderColor: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(posts: _posts, theme: theme, scheme: scheme),
          _PhotosTab(posts: _posts, scheme: scheme),
          _ReviewsTab(
              reviews: _reviews,
              isVet: p.isVet,
              theme: theme,
              scheme: scheme),
          _ActivityTab(theme: theme, scheme: scheme),
        ],
      ),
    );
  }
}

// ─── Banner background ────────────────────────────────────────────────────────

class _BannerBackground extends StatelessWidget {
  const _BannerBackground({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient verde brand
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B8A4E), Color(0xFF0D5C34)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Patrón de patas con baja opacidad
        Opacity(
          opacity: 0.07,
          child: CustomPaint(
            painter: _PawPatternPainter(),
          ),
        ),
      ],
    );
  }
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
  });

  final String? avatarUrl;
  final bool isVet;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hasImg = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
        ),
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
  const _FeedTab(
      {required this.posts, required this.theme, required this.scheme});

  final List<PostVm> posts;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _EmptyState(
        icon: Icons.rss_feed_rounded,
        message: 'Aún sin publicaciones',
        scheme: scheme,
        theme: theme,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PostCard(post: posts[i], theme: theme, scheme: scheme)
          .animate()
          .fadeIn(duration: 260.ms, delay: (i * 40).ms)
          .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard(
      {required this.post, required this.theme, required this.scheme});

  final PostVm post;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('d MMM · HH:mm', 'es').format(post.createdAt);
    return ClientSoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                backgroundImage:
                    post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty
                        ? NetworkImage(post.author.avatarUrl!)
                        : null,
                child: post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 18, color: scheme.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author.fullName,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ImageGrid(urls: post.imageUrls),
          ],
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(urls.first,
            fit: BoxFit.cover, width: double.infinity, height: 200),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: urls
          .take(4)
          .map((url) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url, fit: BoxFit.cover),
              ))
          .toList(),
    );
  }
}

// ─── Photos tab ───────────────────────────────────────────────────────────────

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({required this.posts, required this.scheme});

  final List<PostVm> posts;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final images = posts.expand((p) => p.imageUrls).toList();
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

// ─── Activity tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.history_rounded,
      message: 'Actividad próximamente',
      scheme: scheme,
      theme: theme,
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
