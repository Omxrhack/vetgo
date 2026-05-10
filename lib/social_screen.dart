import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/public_profile_screen.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/social/social_post_card.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _socialFeedRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('d MMM', 'es').format(dt);
}

// ─── Feed item sealed types ───────────────────────────────────────────────────

sealed class _FeedItem {}

final class _PostItem extends _FeedItem {
  _PostItem(this.post, {this.recommended = false});
  final PostVm post;
  final bool recommended;
}

final class _SuggestionCarouselItem extends _FeedItem {
  _SuggestionCarouselItem(this.profiles);
  final List<SuggestedProfileVm> profiles;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _api = VetgoApiClient();

  List<PostVm> _posts = [];
  List<PostVm> _explorePosts = [];
  List<SuggestedProfileVm> _suggestions = [];
  List<_FeedItem> _feedItems = [];

  String? _myAvatarUrl;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    // Start all requests in parallel with proper types
    final feedFuture      = _api.getSocialFeed(page: 1);
    final suggestFuture   = _api.getSuggestedProfiles(limit: 12);
    final exploreFuture   = _api.getExplorePosts(limit: 10);
    final sessionFuture   = AuthStorage.loadSession();

    final feedResult    = await feedFuture;
    final suggestResult = await suggestFuture;
    final exploreResult = await exploreFuture;
    final session       = await sessionFuture;

    if (!mounted) return;

    final (feedData, feedErr) = feedResult;
    final (suggestData, _)    = suggestResult;
    final (exploreData, _)    = exploreResult;

    if (feedErr != null || feedData == null) {
      setState(() {
        _error = feedErr ?? 'Error al cargar el feed';
        _loading = false;
      });
      return;
    }

    final posts       = _parsePosts(feedData);
    final suggestions = _parseSuggestions(suggestData);
    final explore     = _parsePosts(exploreData ?? <String, dynamic>{});

    setState(() {
      _posts        = posts;
      _explorePosts = explore;
      _suggestions  = suggestions;
      _myAvatarUrl  = session?.profile?['avatar_url'] as String?;
      _hasMore      = feedData['has_more'] == true;
      _page         = 2;
      _loading      = false;
      _feedItems    = _buildFeedItems(posts, suggestions, explore);
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final (data, _) = await _api.getSocialFeed(page: _page);
    if (!mounted) return;
    if (data != null) {
      final more = _parsePosts(data);
      final allPosts = [..._posts, ...more];
      setState(() {
        _posts = allPosts;
        _hasMore = data['has_more'] == true;
        _page++;
        _feedItems = _buildFeedItems(allPosts, _suggestions, _explorePosts);
      });
    }
    setState(() => _loadingMore = false);
  }

  List<PostVm> _parsePosts(Map<String, dynamic> data) =>
      (data['posts'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(PostVm.fromJson)
          .toList() ??
      [];

  List<SuggestedProfileVm> _parseSuggestions(Map<String, dynamic>? data) =>
      (data?['suggestions'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(SuggestedProfileVm.fromJson)
          .toList() ??
      [];

  static List<_FeedItem> _buildFeedItems(
    List<PostVm> posts,
    List<SuggestedProfileVm> suggestions,
    List<PostVm> explore,
  ) {
    final items = <_FeedItem>[];
    int exploreIdx = 0;
    bool carouselInserted = false;

    for (int i = 0; i < posts.length; i++) {
      items.add(_PostItem(posts[i]));

      // Insert suggestion carousel after 3rd post (once)
      if (i == 2 && suggestions.isNotEmpty && !carouselInserted) {
        items.add(_SuggestionCarouselItem(suggestions));
        carouselInserted = true;
      }

      // Inject recommended post every 5 regular posts
      if ((i + 1) % 5 == 0 && exploreIdx < explore.length) {
        items.add(_PostItem(explore[exploreIdx++], recommended: true));
      }
    }

    // If no followed posts but there are explore posts, show them
    if (posts.isEmpty && explore.isNotEmpty) {
      for (final p in explore) {
        items.add(_PostItem(p, recommended: true));
      }
    }

    return items;
  }

  void _dismissRecommended(PostVm post) {
    setState(() {
      _feedItems = _feedItems
          .where((item) => !(item is _PostItem && item.recommended && item.post.id == post.id))
          .toList();
    });
  }

  void _openCreatePost() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        onCreated: (post) {
          setState(() {
            _posts = [post, ..._posts];
            _feedItems = [_PostItem(post), ..._feedItems];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _load,
        color: scheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: scheme.surfaceContainerLowest,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Social',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B8A4E),
                ),
              ),
              centerTitle: false,
            ),

            // ── Compose box — always visible ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _ComposeBox(
                  avatarUrl: _myAvatarUrl,
                  onTap: _openCreatePost,
                  theme: theme,
                  scheme: scheme,
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              )
            else if (_feedItems.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48, color: scheme.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(
                        'Sigue a alguien para ver su actividad aquí',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                sliver: SliverList.separated(
                  itemCount: _feedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = _feedItems[i];
                    return switch (item) {
                      _PostItem() => SocialPostCard(
                          post: item.post,
                          theme: theme,
                          scheme: scheme,
                          timeLabel: _socialFeedRelativeTime(item.post.createdAt),
                          recommended: item.recommended,
                          onDismissRecommended:
                              item.recommended ? () => _dismissRecommended(item.post) : null,
                          onAuthorTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => PublicProfileScreen(profileId: item.post.author.id),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 260.ms, delay: (i * 20).ms)
                            .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
                      _SuggestionCarouselItem() => _SuggestionCarousel(
                          profiles: item.profiles,
                          api: _api,
                          theme: theme,
                          scheme: scheme,
                        )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: (i * 20).ms),
                    };
                  },
                ),
              ),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Compose box ──────────────────────────────────────────────────────────────

class _ComposeBox extends StatelessWidget {
  const _ComposeBox({
    required this.avatarUrl,
    required this.onTap,
    required this.theme,
    required this.scheme,
  });

  final String? avatarUrl;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ClientSoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person_rounded, size: 18, color: scheme.primary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(24),
                  color: scheme.surfaceContainerLowest,
                ),
                child: Text(
                  '¿Qué está pasando?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.photo_camera_outlined, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestion carousel ──────────────────────────────────────────────────────

class _SuggestionCarousel extends StatefulWidget {
  const _SuggestionCarousel({
    required this.profiles,
    required this.api,
    required this.theme,
    required this.scheme,
  });

  final List<SuggestedProfileVm> profiles;
  final VetgoApiClient api;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  State<_SuggestionCarousel> createState() => _SuggestionCarouselState();
}

class _SuggestionCarouselState extends State<_SuggestionCarousel> {
  late final Set<String> _following = {};
  final Set<String> _loading = {};

  Future<void> _toggle(String id) async {
    if (_loading.contains(id)) return;
    setState(() => _loading.add(id));
    if (_following.contains(id)) {
      await widget.api.unfollowUser(id);
      if (mounted) setState(() { _following.remove(id); _loading.remove(id); });
    } else {
      await widget.api.followUser(id);
      if (mounted) setState(() { _following.add(id); _loading.remove(id); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Personas que quizás conozcas',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.profiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final p = widget.profiles[i];
              final isFollowing = _following.contains(p.id);
              final isLoading = _loading.contains(p.id);
              return _SuggestionCard(
                profile: p,
                isFollowing: isFollowing,
                isLoading: isLoading,
                theme: theme,
                scheme: scheme,
                onTap: () => Navigator.of(ctx).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => PublicProfileScreen(profileId: p.id),
                  ),
                ),
                onFollowTap: () => _toggle(p.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.profile,
    required this.isFollowing,
    required this.isLoading,
    required this.theme,
    required this.scheme,
    required this.onTap,
    required this.onFollowTap,
  });

  final SuggestedProfileVm profile;
  final bool isFollowing;
  final bool isLoading;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    return ClientSoftCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onTap,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 28, color: scheme.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onTap,
              child: Text(
                profile.fullName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.isVet ? 'Veterinario' : 'Cliente',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              width: double.infinity,
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                      ),
                    )
                  : isFollowing
                      ? OutlinedButton(
                          onPressed: onFollowTap,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            side: BorderSide(color: scheme.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Siguiendo'),
                        )
                      : FilledButton(
                          onPressed: onFollowTap,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Seguir'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Create post sheet ────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.onCreated});

  final void Function(PostVm post) onCreated;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _body = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _body.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final (data, err) = await VetgoApiClient().createPost(body: text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null || data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Error al publicar')));
      return;
    }
    widget.onCreated(PostVm.fromJson(data));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            Text('Nueva publicación',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              maxLines: 5,
              maxLength: 2000,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '¿Qué quieres compartir?',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _post,
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publicar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
