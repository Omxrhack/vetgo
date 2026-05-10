import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';

/// Hoja inferior: lista de comentarios + campo para publicar.
class PostCommentsSheet extends StatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.api,
    required this.postId,
    required this.onCommentCountChanged,
  });

  final VetgoApiClient api;
  final String postId;
  final void Function(int newTotal) onCommentCountChanged;

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final _controller = TextEditingController();
  List<PostCommentVm> _comments = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await widget.api.getPostComments(widget.postId);
    if (!mounted) return;
    if (err != null || data == null) {
      setState(() {
        _loading = false;
        _error = err ?? 'No se pudieron cargar los comentarios';
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
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final (data, err) = await widget.api.createPostComment(widget.postId, text);
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
        _controller.clear();
      });
    }
    final total = (data['comment_count'] as num?)?.toInt();
    if (total != null) widget.onCommentCountChanged(total);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comentarios',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.38,
              child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.error,
                              ),
                            ),
                          )
                        : _comments.isEmpty
                            ? Center(
                                child: Text(
                                  'Sé el primero en comentar.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _comments.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                                ),
                                itemBuilder: (ctx, i) {
                                  final c = _comments[i];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: scheme.primaryContainer,
                                          backgroundImage: c.author.avatarUrl != null &&
                                                  c.author.avatarUrl!.isNotEmpty
                                              ? NetworkImage(c.author.avatarUrl!)
                                              : null,
                                          child: c.author.avatarUrl == null ||
                                                  c.author.avatarUrl!.isEmpty
                                              ? Icon(Icons.person_rounded,
                                                  size: 18, color: scheme.primary)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c.author.fullName,
                                                style: theme.textTheme.labelLarge?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                c.body,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario…',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
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
          ],
        ),
      ),
    );
  }
}
