import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroine/heroine.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/navigation/social_heroine_tags.dart';
import 'package:vetgo/core/navigation/vetgo_social_heroine_route.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/create_post_screen.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/public_profile_screen.dart';
import 'package:vetgo/repost_compose_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vetgo/social_post_detail_screen.dart';
import 'package:vetgo/widgets/social/social_post_card.dart';
import 'package:vetgo/widgets/social/vetgo_social_heroine_motion.dart';

// ─── Brand / helpers ──────────────────────────────────────────────────────────

const Color _vetgoGreen = Color(0xFF1B8A4E);

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
  _PostItem(this.entry, {this.recommended = false});
  final FeedEntryVm entry;
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

  List<FeedEntryVm> _feedEntries = [];
  List<FeedEntryVm> _exploreEntries = [];
  List<SuggestedProfileVm> _suggestions = [];
  List<_FeedItem> _feedItems = [];

  String? _myAvatarUrl;
  String? _myUserId;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  /// Evita envíos duplicados de like en el mismo post mientras la API responde.
  final Set<String> _pendingLikePostIds = {};
  /// Autores seguidos desde el botón + en posts «Descubre» (sesión).
  final Set<String> _recommendedFollowedIds = {};
  final Set<String> _recommendedFollowLoadingIds = {};
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

  Future<void> _followRecommendedAuthor(String authorId) async {
    if (_recommendedFollowLoadingIds.contains(authorId)) return;
    if (_recommendedFollowedIds.contains(authorId)) return;
    setState(() => _recommendedFollowLoadingIds.add(authorId));
    final (_, err) = await _api.followUser(authorId);
    if (!mounted) return;
    setState(() {
      _recommendedFollowLoadingIds.remove(authorId);
      if (err == null) {
        _recommendedFollowedIds.add(authorId);
      }
    });
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    final feedFuture = _api.getSocialFeed(page: 1);
    final suggestFuture = _api.getSuggestedProfiles(limit: 12);
    final exploreFuture = _api.getExplorePosts(limit: 10);
    final sessionFuture = AuthStorage.loadSession();

    // Feed + sesión en paralelo para filtrar reposts propios en la primera pintura.
    final feedResult = await feedFuture;
    final session = await sessionFuture;
    if (!mounted) return;

    final (feedData, feedErr) = feedResult;
    if (feedErr != null || feedData == null) {
      setState(() {
        _error = feedErr ?? 'Error al cargar el feed';
        _loading = false;
      });
      return;
    }

    final feedListRaw = await _decodeFeedEntries(feedData);
    final myId = session?.user?['id']?.toString();
    final feedList = filterHomeFeedForViewer(feedListRaw, myId);
    if (!mounted) return;

    setState(() {
      _feedEntries = feedList;
      _myUserId = myId;
      _myAvatarUrl = session?.profile?['avatar_url'] as String?;
      _suggestions = [];
      _exploreEntries = [];
      _hasMore = feedData['has_more'] == true;
      _page = 2;
      _loading = false;
      _feedItems = _buildFeedItems(feedList, const [], const []);
    });

    // Capa 2: sugerencias y explore
    final layer2 = await Future.wait<dynamic>([
      suggestFuture,
      exploreFuture,
    ]);
    if (!mounted) return;

    final suggestTuple = layer2[0] as (Map<String, dynamic>?, String?);
    final exploreTuple = layer2[1] as (Map<String, dynamic>?, String?);

    final suggestions = _parseSuggestions(suggestTuple.$1);
    final exploreRaw = _parseFeedEntries(exploreTuple.$1 ?? <String, dynamic>{});
    final explore = filterHomeFeedForViewer(exploreRaw, _myUserId);

    setState(() {
      _suggestions = suggestions;
      _exploreEntries = explore;
      _feedItems = _buildFeedItems(_feedEntries, suggestions, explore);
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final (data, _) = await _api.getSocialFeed(page: _page);
    if (!mounted) return;
    if (data != null) {
      final moreRaw = await _decodeFeedEntries(data);
      final more = filterHomeFeedForViewer(moreRaw, _myUserId);
      final merged = [..._feedEntries, ...more];
      setState(() {
        _feedEntries = merged;
        _hasMore = data['has_more'] == true;
        _page++;
        _feedItems = _buildFeedItems(merged, _suggestions, _exploreEntries);
      });
    }
    setState(() => _loadingMore = false);
  }

  List<FeedEntryVm> _parseFeedEntries(Map<String, dynamic> data) =>
      (data['posts'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(FeedEntryVm.fromJson)
          .toList() ??
      [];

  /// Parseo del JSON del feed; usa [compute] si hay muchas filas (menos trabajo en el isolate de UI).
  Future<List<FeedEntryVm>> _decodeFeedEntries(Map<String, dynamic> data) async {
    final raw = data['posts'] as List<dynamic>?;
    final n = raw?.length ?? 0;
    if (n < 20) {
      return _parseFeedEntries(data);
    }
    return compute(socialParseFeedEntriesIsolate, data);
  }

  List<SuggestedProfileVm> _parseSuggestions(Map<String, dynamic>? data) =>
      (data?['suggestions'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(SuggestedProfileVm.fromJson)
          .toList() ??
      [];

  static List<_FeedItem> _buildFeedItems(
    List<FeedEntryVm> entries,
    List<SuggestedProfileVm> suggestions,
    List<FeedEntryVm> explore,
  ) {
    final items = <_FeedItem>[];
    int exploreIdx = 0;
    bool carouselInserted = false;

    for (int i = 0; i < entries.length; i++) {
      items.add(_PostItem(entries[i]));

      if (i == 2 && suggestions.isNotEmpty && !carouselInserted) {
        items.add(_SuggestionCarouselItem(suggestions));
        carouselInserted = true;
      }

      if ((i + 1) % 5 == 0 && exploreIdx < explore.length) {
        items.add(_PostItem(explore[exploreIdx++], recommended: true));
      }
    }

    if (entries.isEmpty && explore.isNotEmpty) {
      for (final e in explore) {
        items.add(_PostItem(e, recommended: true));
      }
    }

    return items;
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

  void _patchDisplayPost(PostVm updated) {
    setState(() {
      _feedEntries = _feedEntries.map((e) {
        if (e.displayPost.id != updated.id) return e;
        return _entryWithUpdatedPost(e, updated);
      }).toList();
      _exploreEntries = _exploreEntries.map((e) {
        if (e.displayPost.id != updated.id) return e;
        return _entryWithUpdatedPost(e, updated);
      }).toList();
      _feedItems = _buildFeedItems(_feedEntries, _suggestions, _exploreEntries);
    });
  }

  Future<void> _handleLike(PostVm post) async {
    if (_pendingLikePostIds.contains(post.id)) return;
    _pendingLikePostIds.add(post.id);

    final optimistic = post.copyWith(
      viewerHasLiked: !post.viewerHasLiked,
      likeCount: post.viewerHasLiked
          ? (post.likeCount - 1).clamp(0, 999999)
          : post.likeCount + 1,
    );
    _patchDisplayPost(optimistic);

    final (data, err) = await _api.togglePostLike(post.id);
    if (!mounted) {
      _pendingLikePostIds.remove(post.id);
      return;
    }
    if (err != null || data == null) {
      _patchDisplayPost(post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No se pudo actualizar el me gusta')),
      );
      _pendingLikePostIds.remove(post.id);
      return;
    }
    _patchDisplayPost(
      optimistic.copyWith(
        likeCount: (data['like_count'] as num?)?.toInt() ?? optimistic.likeCount,
        viewerHasLiked: data['viewer_has_liked'] as bool? ?? optimistic.viewerHasLiked,
      ),
    );
    _pendingLikePostIds.remove(post.id);
  }

  Future<void> _openPostDetail(FeedEntryVm entry, {required bool recommended}) async {
    final display = entry.displayPost;
    final timeLabel = _socialFeedRelativeTime(display.createdAt);
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
          recommended: recommended,
          brandGreen: _vetgoGreen,
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
    if (updated != null && mounted) _patchDisplayPost(updated);
  }

  void _sharePost(PostVm post) {
    Share.share(
      '${post.author.fullName}: ${post.body}',
      subject: 'Vetgo Social',
    );
  }

  void _dismissRecommended(FeedEntryVm entry) {
    final id = entry.displayPost.id;
    setState(() {
      _feedItems = _feedItems
          .where((item) =>
              !(item is _PostItem && item.recommended && item.entry.displayPost.id == id))
          .toList();
    });
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.of(context).push<FeedEntryVm>(
      VetgoSocialHeroineRoute<FeedEntryVm>(
        builder: (_) => const CreatePostScreen(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _feedEntries = [result, ..._feedEntries];
        _feedItems = _buildFeedItems(_feedEntries, _suggestions, _exploreEntries);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: scheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Social',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: _vetgoGreen,
                ),
              ),
              centerTitle: false,
            ),

            // ── Compose strip (bloque redondeado; sin doble divisor duro) ──
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _ComposeBox(
                      avatarUrl: _myAvatarUrl,
                      onTap: _openCreatePost,
                      theme: theme,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.14),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando…',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: scheme.onSurface.withValues(alpha: 0.28),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pudimos cargar el feed',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _load,
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_feedItems.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 48,
                          color: scheme.onSurface.withValues(alpha: 0.22),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu línea de tiempo está lista',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sigue a alguien para ver su actividad aquí.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                sliver: SliverList.separated(
                  itemCount: _feedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final item = _feedItems[i];
                    return switch (item) {
                      _PostItem() => _SocialFeedPostTile(
                          entry: item.entry,
                          recommended: item.recommended,
                          theme: theme,
                          scheme: scheme,
                          myUserId: _myUserId,
                          recommendedFollowedIds: _recommendedFollowedIds,
                          recommendedFollowLoadingIds: _recommendedFollowLoadingIds,
                          onRecommendedFollow: _followRecommendedAuthor,
                          onDismissRecommended:
                              item.recommended ? () => _dismissRecommended(item.entry) : null,
                          onFeedUpdated: (entry) {
                            final u = entry.displayPost;
                            setState(() {
                              _feedEntries = filterHomeFeedForViewer([
                                entry,
                                ..._feedEntries.map((e) {
                                  if (e.displayPost.id != u.id) return e;
                                  return _entryWithUpdatedPost(e, u);
                                }),
                              ], _myUserId);
                              _exploreEntries = _exploreEntries.map((e) {
                                if (e.displayPost.id != u.id) return e;
                                return _entryWithUpdatedPost(e, u);
                              }).toList();
                              _feedItems =
                                  _buildFeedItems(_feedEntries, _suggestions, _exploreEntries);
                            });
                          },
                          onLikePost: _handleLike,
                          onOpenPostDetail: () =>
                              _openPostDetail(item.entry, recommended: item.recommended),
                          onSharePost: _sharePost,
                        )
                            .animate()
                            .fadeIn(duration: 260.ms, delay: (i * 20).ms)
                            .slideY(begin: 0.03, end: 0, duration: 260.ms, curve: Curves.easeOutCubic)
                            .scale(
                              begin: const Offset(0.98, 0.98),
                              end: const Offset(1, 1),
                              duration: 260.ms,
                              curve: Curves.easeOutCubic,
                            ),
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

// ─── Feed post tile (navegación repost) ───────────────────────────────────────

class _SocialFeedPostTile extends StatelessWidget {
  const _SocialFeedPostTile({
    required this.entry,
    required this.recommended,
    required this.theme,
    required this.scheme,
    this.myUserId,
    this.recommendedFollowedIds,
    this.recommendedFollowLoadingIds,
    this.onRecommendedFollow,
    this.onDismissRecommended,
    required this.onFeedUpdated,
    required this.onLikePost,
    required this.onOpenPostDetail,
    required this.onSharePost,
  });

  final FeedEntryVm entry;
  final bool recommended;
  final ThemeData theme;
  final ColorScheme scheme;
  final String? myUserId;
  final Set<String>? recommendedFollowedIds;
  final Set<String>? recommendedFollowLoadingIds;
  final void Function(String authorId)? onRecommendedFollow;
  final VoidCallback? onDismissRecommended;
  final void Function(FeedEntryVm entry) onFeedUpdated;
  final Future<void> Function(PostVm post) onLikePost;
  final VoidCallback onOpenPostDetail;
  final void Function(PostVm post) onSharePost;

  @override
  Widget build(BuildContext context) {
    final display = entry.displayPost;
    final timeLabel = _socialFeedRelativeTime(display.createdAt);

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

    final authorId = display.author.id;
    final followed = recommendedFollowedIds?.contains(authorId) ?? false;
    final loading = recommendedFollowLoadingIds?.contains(authorId) ?? false;
    final showRecommendedFollow =
        recommended && myUserId != null && authorId != myUserId;

    return SocialPostCard(
      displayPost: display,
      theme: theme,
      scheme: scheme,
      timeLabel: timeLabel,
      reposter: reposter,
      quoteBody: quoteBody,
      recommended: recommended,
      onDismissRecommended: onDismissRecommended,
      recommendedFollowed: showRecommendedFollow && followed,
      recommendedFollowLoading: showRecommendedFollow && loading,
      onRecommendedFollowTap: showRecommendedFollow &&
              !followed &&
              !loading &&
              onRecommendedFollow != null
          ? () => onRecommendedFollow!(authorId)
          : null,
      useElevatedChrome: true,
      brandGreen: _vetgoGreen,
      heroinePostFlightTag: vetgoSocialPostHeroTag(display.id),
      heroineAuthorFlightTag: vetgoSocialAuthorAvatarFlightTag(display.id),
      heroineRepostFlightTag: vetgoSocialRepostHeroTag(display.id),
      onAuthorTap: () => Navigator.of(context).push<void>(
        VetgoSocialHeroineRoute<void>(
          builder: (_) => PublicProfileScreen(
            profileId: display.author.id,
            heroineAvatarFlightTag:
                vetgoSocialAuthorAvatarFlightTag(display.id),
          ),
        ),
      ),
      onRepost: () async {
        final res = await Navigator.of(context).push<FeedEntryVm>(
          VetgoSocialHeroineRoute<FeedEntryVm>(
            builder: (_) => RepostComposeScreen(
              original: display,
              heroineQuotedFlightTag: vetgoSocialRepostHeroTag(display.id),
            ),
          ),
        );
        if (res != null && context.mounted) onFeedUpdated(res);
      },
      onLikeTap: () => onLikePost(display),
      onCommentTap: onOpenPostDetail,
      onOpenThread: onOpenPostDetail,
      onShareTap: () => onSharePost(display),
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
    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: scheme.primary.withValues(alpha: 0.06),
        highlightColor: scheme.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Heroine(
                tag: vetgoSocialComposeHeroTag,
                motion: vetgoSocialHeroAvatarMotion,
                flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Icon(Icons.person_rounded, size: 22, color: scheme.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '¿Qué está pasando?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.42),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.15,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 24,
                  color: scheme.primary.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personas que quizás conozcas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.profiles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                        VetgoSocialHeroineRoute<void>(
                          builder: (_) => PublicProfileScreen(
                            profileId: p.id,
                            heroineAvatarFlightTag:
                                vetgoSocialProfileHeroTag(p.id),
                          ),
                        ),
                      ),
                      onFollowTap: () => _toggle(p.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
    return SizedBox(
      width: 104,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Heroine(
              tag: vetgoSocialProfileHeroTag(profile.id),
              motion: vetgoSocialHeroAvatarMotion,
              flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? Icon(Icons.person_rounded, size: 24, color: scheme.primary)
                    : null,
              ),
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
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                          side: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Siguiendo'),
                      )
                    : FilledButton(
                        onPressed: onFollowTap,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Seguir'),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Top-level para [compute]: parseo de feed fuera del isolate de UI (listas largas).
List<FeedEntryVm> socialParseFeedEntriesIsolate(Map<String, dynamic> data) {
  return (data['posts'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(FeedEntryVm.fromJson)
          .toList() ??
      [];
}
