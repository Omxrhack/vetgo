import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:heroine/heroine.dart';
import 'package:markdown_quill/markdown_quill.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/navigation/social_heroine_tags.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_controller.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_styles.dart';
import 'package:vetgo/widgets/social/vetgo_social_heroine_motion.dart';
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
  bool _uploadingGallery = false;
  String? _myAvatarUrl;
  final List<String> _imageUrls = [];

  static const int _maxChars = 2000;
  static const int _maxImages = 4;

  static const double _mediaPreviewRadius = 12;

  bool get _canPost {
    if (_saving || _uploadingGallery) return false;
    final plain = _quillController.document.toPlainText();
    final textLen = plain.trim().characters.length;
    if (textLen > _maxChars) return false;
    if (textLen == 0 && _imageUrls.isEmpty) return false;
    return true;
  }

  int get _remaining {
    final len = _quillController.document.toPlainText().trim().characters.length;
    return _maxChars - len;
  }

  @override
  void initState() {
    super.initState();
    _quillController = vetgoSocialQuillController();
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

  Future<void> _pickAndUploadPhotos() async {
    final remaining = _maxImages - _imageUrls.length;
    if (remaining <= 0 || _uploadingGallery) return;

    final picker = ImagePicker();
    List<XFile> files = [];
    try {
      files = await picker.pickMultiImage(
        maxWidth: 2048,
        imageQuality: 85,
        limit: remaining,
      );
    } catch (_) {
      final one = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (one != null) files = [one];
    }

    if (files.isEmpty || !mounted) return;

    setState(() => _uploadingGallery = true);
    final api = VetgoApiClient();
    try {
      for (final x in files.take(remaining)) {
        final bytes = await x.readAsBytes();
        final name = x.name.trim().isNotEmpty ? x.name.trim() : 'photo.jpg';
        final (url, err) = await api.uploadPostImage(bytes: bytes, filename: name);
        if (!mounted) return;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          break;
        }
        if (url != null && url.isNotEmpty) {
          setState(() => _imageUrls.add(url));
        }
      }
    } finally {
      if (mounted) setState(() => _uploadingGallery = false);
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _imageUrls.length) return;
    setState(() => _imageUrls.removeAt(index));
  }

  Future<void> _publish() async {
    if (!_canPost) return;
    final trimmedPlain = _quillController.document.toPlainText().trim();
    if (trimmedPlain.characters.length > _maxChars) return;

    final markdown =
        DeltaToMarkdown().convert(_quillController.document.toDelta()).trim();
    if (markdown.isEmpty && _imageUrls.isEmpty) return;

    setState(() => _saving = true);
    final (data, err) = await VetgoApiClient().createPost(
      body: markdown,
      imageUrls: List<String>.from(_imageUrls),
    );
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
            color: scheme.outlineVariant.withValues(alpha: 0.11),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
                      backgroundImage: _myAvatarUrl != null && _myAvatarUrl!.isNotEmpty
                          ? NetworkImage(_myAvatarUrl!)
                          : null,
                      child: _myAvatarUrl == null || _myAvatarUrl!.isEmpty
                          ? Icon(Icons.person_rounded, color: scheme.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _focusNode,
                            scrollController: _scrollController,
                            config: vetgoSocialQuillEditorConfig(
                              context,
                              placeholder: 'Escribe tu publicación',
                            ),
                          ),
                        ),
                        if (_imageUrls.isNotEmpty || _uploadingGallery) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 88,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageUrls.length + (_uploadingGallery ? 1 : 0),
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                if (_uploadingGallery && i == _imageUrls.length) {
                                  return SizedBox(
                                    width: 88,
                                    height: 88,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(_mediaPreviewRadius),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final url = _imageUrls[i];
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(_mediaPreviewRadius),
                                      child: Image.network(
                                        url,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => ColoredBox(
                                          color: scheme.surfaceContainerHighest,
                                          child: Icon(Icons.broken_image_outlined, color: scheme.outline),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Material(
                                        color: scheme.surface,
                                        shape: const CircleBorder(),
                                        elevation: 1,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () => _removeImageAt(i),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.close_rounded, size: 18, color: scheme.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.11),
          ),
          Material(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Fotos (${_imageUrls.length}/$_maxImages)',
                    onPressed: _saving ||
                            _uploadingGallery ||
                            _imageUrls.length >= _maxImages
                        ? null
                        : _pickAndUploadPhotos,
                    iconSize: 22,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      Icons.image_outlined,
                      color: _imageUrls.length >= _maxImages
                          ? scheme.onSurface.withValues(alpha: 0.35)
                          : scheme.primary.withValues(alpha: 0.92),
                    ),
                  ),
                  Expanded(
                    child: QuillSimpleToolbar(
                      controller: _quillController,
                      config: vetgoSocialToolbarConfig(theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 8 + MediaQuery.paddingOf(context).bottom),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$remaining',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.05,
                  color: remaining < 200
                      ? scheme.error
                      : scheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
