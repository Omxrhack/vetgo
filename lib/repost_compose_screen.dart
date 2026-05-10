import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:heroine/heroine.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_controller.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_styles.dart';
import 'package:vetgo/widgets/social/vetgo_social_heroine_motion.dart';
import 'package:vetgo/widgets/social/vetgo_social_quill_toolbar.dart';

/// Quote-repost estilo Twitter/X: comentario Quill arriba, tarjeta citada, «Republicar» en píldora.
class RepostComposeScreen extends StatefulWidget {
  const RepostComposeScreen({
    super.key,
    required this.original,
    this.heroineQuotedFlightTag,
  });

  final PostVm original;

  /// Par con el botón repost del feed / detalle (`SocialHeroineTags`).
  final String? heroineQuotedFlightTag;

  @override
  State<RepostComposeScreen> createState() => _RepostComposeScreenState();
}

class _RepostComposeScreenState extends State<RepostComposeScreen> {
  late final QuillController _quoteController;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _saving = false;
  String? _myAvatarUrl;

  static const Color _brandGreen = Color(0xFF1B8A4E);
  static const int _maxQuoteChars = 1000;

  int get _remaining {
    final len = _quoteController.document.toPlainText().trim().characters.length;
    return _maxQuoteChars - len;
  }

  @override
  void initState() {
    super.initState();
    _quoteController = vetgoSocialQuillController();
    _quoteController.addListener(() => setState(() {}));
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
    _quoteController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final plain = _quoteController.document.toPlainText().trim();
    if (plain.isNotEmpty && plain.characters.length > _maxQuoteChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El comentario supera el límite de caracteres')),
      );
      return;
    }

    setState(() => _saving = true);
    String? quoteBody;
    if (plain.isEmpty) {
      quoteBody = null;
    } else {
      final md =
          DeltaToMarkdown().convert(_quoteController.document.toDelta()).trim();
      quoteBody = md.isEmpty ? null : md;
    }

    final (data, err) = await VetgoApiClient().createRepost(
      widget.original.id,
      quoteBody: quoteBody,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null || data == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Error')));
      return;
    }
    FeedEntryVm entry;
    try {
      entry = FeedEntryVm.fromJson(data);
    } catch (_) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final o = widget.original;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Republicar',
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
            flex: 5,
            child: Column(
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
                            controller: _quoteController,
                            focusNode: _focusNode,
                            scrollController: _scrollController,
                            config: vetgoSocialQuillEditorConfig(
                              context,
                              placeholder: 'Añade un comentario (opcional)',
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
                        controller: _quoteController,
                        config: vetgoSocialToolbarConfig(theme),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$remaining',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: remaining < 100
                            ? scheme.error
                            : scheme.onSurface.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
              child: _QuotedPostCard(
                original: o,
                accent: _brandGreen,
                theme: theme,
                scheme: scheme,
                heroineQuotedFlightTag: widget.heroineQuotedFlightTag,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotedPostCard extends StatelessWidget {
  const _QuotedPostCard({
    required this.original,
    required this.accent,
    required this.theme,
    required this.scheme,
    this.heroineQuotedFlightTag,
  });

  final PostVm original;
  final Color accent;
  final ThemeData theme;
  final ColorScheme scheme;
  final String? heroineQuotedFlightTag;

  @override
  Widget build(BuildContext context) {
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: original.author.avatarUrl != null &&
                                    original.author.avatarUrl!.isNotEmpty
                                ? NetworkImage(original.author.avatarUrl!)
                                : null,
                            child: original.author.avatarUrl == null ||
                                    original.author.avatarUrl!.isEmpty
                                ? Icon(Icons.person_rounded, size: 12, color: scheme.primary)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              original.author.fullName,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: original.body,
                        shrinkWrap: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: scheme.onSurface.withValues(alpha: 0.92),
                          ),
                          blockSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final tag = heroineQuotedFlightTag;
    if (tag != null) {
      card = Heroine(
        tag: tag,
        motion: vetgoSocialHeroQuotedCardMotion,
        flightShuttleBuilder: vetgoSocialHeroFadeThrough(scheme),
        child: card,
      );
    }
    return card;
  }
}
