import 'package:flutter/material.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';

/// Composer estilo Twitter/X: cerrar, «Publicar» en píldora, avatar + campo, barra de formato inferior.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;
  String? _myAvatarUrl;

  static const int _maxChars = 2000;

  bool get _canPost =>
      !_saving &&
      _controller.text.trim().isNotEmpty &&
      _controller.text.trim().characters.length <= _maxChars;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insert(String snippet) {
    final c = _controller;
    final t = c.text;
    final start = c.selection.start >= 0 ? c.selection.start : t.length;
    final end = c.selection.end >= 0 ? c.selection.end : t.length;
    final newText = t.replaceRange(start, end, snippet);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _publish() async {
    if (!_canPost) return;
    final text = _controller.text.trim();
    setState(() => _saving = true);
    final (data, err) = await VetgoApiClient().createPost(body: text);
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
    final len = _controller.text.characters.length;
    final remaining = _maxChars - len;

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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      maxLength: _maxChars,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: '¿Qué está pasando?',
                        hintStyle: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
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
                  color: remaining < 200
                      ? scheme.error
                      : scheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          Material(
            color: scheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolbarIcon(
                      icon: Icons.title_rounded,
                      tooltip: 'Título',
                      onTap: () => _insert('# '),
                      scheme: scheme,
                    ),
                    _ToolbarIcon(
                      icon: Icons.horizontal_rule_rounded,
                      tooltip: 'Subtítulo',
                      onTap: () => _insert('## '),
                      scheme: scheme,
                    ),
                    _ToolbarIcon(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Negrita',
                      onTap: () => _insert('**negrita**'),
                      scheme: scheme,
                    ),
                    _ToolbarIcon(
                      icon: Icons.format_italic_rounded,
                      tooltip: 'Cursiva',
                      onTap: () => _insert('_cursiva_'),
                      scheme: scheme,
                    ),
                    _ToolbarIcon(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Lista',
                      onTap: () => _insert('- '),
                      scheme: scheme,
                    ),
                  ],
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

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: scheme.primary,
      ),
    );
  }
}
