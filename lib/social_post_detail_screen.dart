import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/repost_compose_screen.dart';
import 'package:vetgo/widgets/social/social_post_card.dart';

/// Detalle de publicación: post arriba, comentarios debajo, compositor al pie (estilo Twitter).
class SocialPostDetailScreen extends StatefulWidget {
  const SocialPostDetailScreen({
    super.key,
    required this.api,
    required this.initialPost,
    required this.timeLabel,
    required this.onAuthorTap,
    this.reposter,
    this.quoteBody,
    this.recommended = false,
    this.brandGreen = const Color(0xFF1B8A4E),
  });

  final VetgoApiClient api;
  final PostVm initialPost;
  final String timeLabel;
  final VoidCallback onAuthorTap;
  final PostAuthorVm? reposter;
  final String? quoteBody;
  final bool recommended;
  final Color brandGreen;

  @override
  State<SocialPostDetailScreen> createState() => _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  late PostVm _post;
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();
  List<PostCommentVm> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
    _loadComments();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    final (data, err) = await widget.api.getPostComments(_post.id);
    if (!mounted) return;
    if (err != null || data == null) {
      setState(() {
        _loadingComments = false;
        _commentsError = err ?? 'No se pudieron cargar los comentarios';
      });
      return;
    }
    final list = (data['comments'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PostCommentVm.fromJson)
            .toList() ??
        [];
    setState(() {
      _comments = list;
      _loadingComments = false;
    });
  }

  Future<void> _sendComment() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final (data, err) = await widget.api.createPostComment(_post.id, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null || data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No se pudo publicar')),
      );
      return;
    }
    final commentMap = data['comment'] as Map<String, dynamic>?;
    if (commentMap != null) {
      setState(() {
        _comments = [..._comments, PostCommentVm.fromJson(commentMap)];
        _composerController.clear();
      });
    }
    final total = (data['comment_count'] as num?)?.toInt();
    if (total != null) {
      setState(() {
        _post = _post.copyWith(commentCount: total);
      });
    }
  }

  Future<void> _handleLike() async {
    final (data, err) = await widget.api.togglePostLike(_post.id);
    if (!mounted) return;
    if (err != null || data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No se pudo actualizar')),
      );
      return;
    }
    setState(() {
      _post = _post.copyWith(
        likeCount: (data['like_count'] as num?)?.toInt() ?? _post.likeCount,
        viewerHasLiked: data['viewer_has_liked'] as bool? ?? _post.viewerHasLiked,
      );
    });
  }

  void _share() {
    Share.share(
      '${_post.author.fullName}: ${_post.body}',
      subject: 'Vetgo Social',
    );
  }

  Future<void> _handleRepost() async {
    final res = await Navigator.of(context).push<FeedEntryVm>(
      MaterialPageRoute<FeedEntryVm>(
        builder: (_) => RepostComposeScreen(original: _post),
      ),
    );
    if (!mounted || res == null) return;
    setState(() {
      _post = res.displayPost;
    });
  }

  void _popWithResult() {
    Navigator.of(context).pop(_post);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: scheme.surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: scheme.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _popWithResult,
          ),
          title: Text(
            'Publicación',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: SocialPostCard(
                      displayPost: _post,
                      theme: theme,
                      scheme: scheme,
                      timeLabel: widget.timeLabel,
                      reposter: widget.reposter,
                      quoteBody: widget.quoteBody,
                      recommended: widget.recommended,
                      brandGreen: widget.brandGreen,
                      showBottomDivider: false,
                      onOpenThread: null,
                      onAuthorTap: widget.onAuthorTap,
                      onLikeTap: _handleLike,
                      onCommentTap: () => _composerFocus.requestFocus(),
                      onShareTap: _share,
                      onRepost: _handleRepost,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Respuestas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                  if (_loadingComments)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _CommentSkeletonTile(scheme: scheme),
                        childCount: 5,
                      ),
                    )
                  else if (_commentsError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _commentsError!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                        ),
                      ),
                    )
                  else if (_comments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                        child: Text(
                          'Aún no hay respuestas. Sé el primero en comentar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final c = _comments[i];
                          return _CommentListTile(comment: c, scheme: scheme, theme: theme);
                        },
                        childCount: _comments.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composerController,
                      focusNode: _composerFocus,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu respuesta…',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _sendComment,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: _sending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Icon(Icons.send_rounded, color: scheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentSkeletonTile extends StatelessWidget {
  const _CommentSkeletonTile({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final base = scheme.surfaceContainerHighest.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: base, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 140,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentListTile extends StatelessWidget {
  const _CommentListTile({
    required this.comment,
    required this.scheme,
    required this.theme,
  });

  final PostCommentVm comment;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: comment.author.avatarUrl != null &&
                    comment.author.avatarUrl!.isNotEmpty
                ? NetworkImage(comment.author.avatarUrl!)
                : null,
            child: comment.author.avatarUrl == null || comment.author.avatarUrl!.isEmpty
                ? Icon(Icons.person_rounded, size: 18, color: scheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author.fullName,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
