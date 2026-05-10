import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_styles.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_toolbar.dart';

/// Composer estilo Twitter/X: cerrar, «Publicar», avatar + Quill (negrita/listas) + envío en Markdown.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final QuillController _quillController;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _saving = false;
  String? _myAvatarUrl;

  static const int _maxChars = 2000;

  bool get _canPost {
    if (_saving) return false;
    final plain = _quillController.document.toPlainText();
    if (plain.trim().isEmpty) return false;
    if (plain.trim().characters.length > _maxChars) return false;
    return true;
  }

  int get _remaining {
    final len = _quillController.document.toPlainText().trim().characters.length;
    return _maxChars - len;
  }

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _quillController.addListener(() => setState(() {}));
    _loadAvatar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _loadAvatar() async {
    final s = await AuthStorage.loadSession();
    if (!mounted) return;
    setState(() => _myAvatarUrl = s?.profile?['avatar_url'] as String?);
  }

  @override
  void dispose() {
    _quillController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_canPost) return;
    final trimmedPlain = _quillController.document.toPlainText().trim();
    if (trimmedPlain.characters.length > _maxChars) return;

    final markdown =
        DeltaToMarkdown().convert(_quillController.document.toDelta()).trim();
    if (markdown.isEmpty) return;

    setState(() => _saving = true);
    final (data, err) = await VetgoApiClient().createPost(body: markdown);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null || data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Error al publicar')));
      return;
    }
    FeedEntryVm entry;
    try {
      entry = FeedEntryVm.fromJson(data);
    } catch (_) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = _remaining;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Cerrar',
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              child: FilledButton(
                onPressed: _canPost ? _publish : null,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  disabledBackgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                  disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Publicar',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: _myAvatarUrl != null && _myAvatarUrl!.isNotEmpty
                        ? NetworkImage(_myAvatarUrl!)
                        : null,
                    child: _myAvatarUrl == null || _myAvatarUrl!.isEmpty
                        ? Icon(Icons.person_rounded, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                      config: QuillEditorConfig(
                        expands: true,
                        padding: EdgeInsets.zero,
                        placeholder: 'Escribe tu publicación',
                        customStyles: vetgoSocialQuillStyles(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: vetgoSocialToolbarConfig(theme),
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remaining',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: remaining < 200
                      ? scheme.error
                      : scheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
