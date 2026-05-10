import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';

/// Pantalla de perfil público estilo Threads.
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
    // Load posts and reviews in parallel
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildProfile(theme, scheme),
    );
  }

  Widget _buildProfile(ThemeData theme, ColorScheme scheme) {
    final p = _profile!;
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          pinned: true,
          backgroundColor: scheme.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            p.fullName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (widget.isOwnProfile)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _ProfileHeader(profile: p, theme: theme, scheme: scheme),
                const SizedBox(height: 12),
                _FollowRow(
                  profile: p,
                  isOwnProfile: widget.isOwnProfile,
                  followLoading: _followLoading,
                  onFollow: _toggleFollow,
                  onBook: widget.onBookTap,
                  theme: theme,
                  scheme: scheme,
                ),
                if (p.isVet && p.vet != null) ...[
                  const SizedBox(height: 12),
                  _VetStatsRow(vet: p.vet!, theme: theme, scheme: scheme),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
              indicatorColor: scheme.primary,
              indicatorWeight: 2.5,
              labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: 'Fotos'),
                Tab(text: 'Reseñas'),
                Tab(text: 'Actividad'),
              ],
            ),
            color: scheme.surfaceContainerLowest,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(posts: _posts, theme: theme, scheme: scheme),
          _PhotosTab(posts: _posts, scheme: scheme),
          _ReviewsTab(reviews: _reviews, isVet: p.isVet, theme: theme, scheme: scheme),
          _ActivityTab(theme: theme, scheme: scheme),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.theme,
    required this.scheme,
  });

  final PublicProfileVm profile;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          backgroundImage:
              avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person_rounded, size: 36, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
              if (profile.vet?.specialty != null) ...[
                const SizedBox(height: 3),
                _SpecialtyChip(specialty: profile.vet!.specialty!, scheme: scheme, theme: theme),
              ],
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  profile.bio!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (profile.location != null && profile.location!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 14, color: scheme.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Text(
                      profile.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.02, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.specialty, required this.scheme, required this.theme});

  final String specialty;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        specialty,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Follow row ───────────────────────────────────────────────────────────────

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.profile,
    required this.isOwnProfile,
    required this.followLoading,
    required this.onFollow,
    required this.onBook,
    required this.theme,
    required this.scheme,
  });

  final PublicProfileVm profile;
  final bool isOwnProfile;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback? onBook;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CountChip(
          label: 'Seguidores',
          count: profile.followersCount,
          theme: theme,
          scheme: scheme,
        ),
        Container(width: 1, height: 28, color: scheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 14)),
        _CountChip(
          label: 'Siguiendo',
          count: profile.followingCount,
          theme: theme,
          scheme: scheme,
        ),
        const Spacer(),
        if (isOwnProfile) ...[
          OutlinedButton(
            onPressed: () => _openEditSheet(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: scheme.outline),
            ),
            child: Text('Editar perfil', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ] else ...[
          if (onBook != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.calendar_today_rounded, size: 15),
                label: const Text('Agendar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: scheme.primary),
                  foregroundColor: scheme.primary,
                ),
              ),
            ),
          FilledButton(
            onPressed: followLoading ? null : onFollow,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: profile.isFollowing ? scheme.surfaceContainerHigh : scheme.primary,
              foregroundColor: profile.isFollowing ? scheme.onSurface : scheme.onPrimary,
            ),
            child: followLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  )
                : Text(
                    profile.isFollowing ? 'Siguiendo' : 'Seguir',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 280.ms, delay: 60.ms);
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final refreshed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profileId: context.findAncestorStateOfType<_PublicProfileScreenState>()!.widget.profileId),
    );
    if (refreshed == true && context.mounted) {
      context.findAncestorStateOfType<_PublicProfileScreenState>()!._load();
    }
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count, required this.theme, required this.scheme});

  final String label;
  final int count;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final formatted = count >= 1000
        ? '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}K'
        : count.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatted, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}

// ─── Vet stats ─────────────────────────────────────────────────────────────────

class _VetStatsRow extends StatelessWidget {
  const _VetStatsRow({required this.vet, required this.theme, required this.scheme});

  final VetStatsVm vet;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStatCard(
          value: vet.completedAppointments.toString(),
          label: 'Citas',
          icon: Icons.calendar_today_rounded,
          theme: theme,
          scheme: scheme,
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          value: vet.avgRating != null ? '${vet.avgRating}★' : '—',
          label: 'Rating',
          icon: Icons.star_rounded,
          theme: theme,
          scheme: scheme,
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          value: vet.yearsExperience != null ? '${vet.yearsExperience}a' : '—',
          label: 'Exp.',
          icon: Icons.workspace_premium_outlined,
          theme: theme,
          scheme: scheme,
        ),
        const SizedBox(width: 8),
        _MiniStatCard(
          value: vet.uniquePets.toString(),
          label: 'Mascotas',
          icon: Icons.pets_rounded,
          theme: theme,
          scheme: scheme,
        ),
      ],
    ).animate().fadeIn(duration: 280.ms, delay: 80.ms);
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.theme,
    required this.scheme,
  });

  final String value;
  final String label;
  final IconData icon;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClientSoftCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab bar delegate ─────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, {required this.color});

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: color,
      child: Column(
        children: [tabBar, Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4))],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar || old.color != color;
}

// ─── Feed tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.posts, required this.theme, required this.scheme});

  final List<PostVm> posts;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _EmptyState(icon: Icons.article_outlined, message: 'Sin publicaciones aún', scheme: scheme, theme: theme);
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
  const _PostCard({required this.post, required this.theme, required this.scheme});

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
                backgroundImage: post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty
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
                    Text(post.author.fullName, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(timeLabel, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
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
        child: Image.network(urls.first, fit: BoxFit.cover, width: double.infinity, height: 200),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1,
      children: urls.take(4).map((url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(url, fit: BoxFit.cover),
      )).toList(),
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
        icon: Icons.photo_library_outlined,
        message: 'Sin fotos aún',
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
  const _ReviewsTab({required this.reviews, required this.isVet, required this.theme, required this.scheme});

  final List<ReviewVm> reviews;
  final bool isVet;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!isVet) {
      return _EmptyState(icon: Icons.star_outline_rounded, message: 'Las reseñas son solo para veterinarios', scheme: scheme, theme: theme);
    }
    if (reviews.isEmpty) {
      return _EmptyState(icon: Icons.star_outline_rounded, message: 'Sin reseñas aún', scheme: scheme, theme: theme);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: reviews.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ReviewCard(review: reviews[i], theme: theme, scheme: scheme)
          .animate()
          .fadeIn(duration: 260.ms, delay: (i * 40).ms)
          .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.theme, required this.scheme});

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
                backgroundImage: review.reviewer.avatarUrl != null && review.reviewer.avatarUrl!.isNotEmpty
                    ? NetworkImage(review.reviewer.avatarUrl!)
                    : null,
                child: review.reviewer.avatarUrl == null || review.reviewer.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 16, color: scheme.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewer.fullName, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text(timeLabel, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14,
                  color: i < review.rating ? const Color(0xFFF59E0B) : scheme.outlineVariant,
                )),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
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
    return _EmptyState(icon: Icons.timeline_rounded, message: 'Actividad próximamente', scheme: scheme, theme: theme);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Editar perfil', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _bio,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Biografía',
                hintText: 'Cuéntanos sobre ti...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Ciudad / ubicación',
                prefixIcon: const Icon(Icons.place_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared empty state ───────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, required this.scheme, required this.theme});

  final IconData icon;
  final String message;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

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
