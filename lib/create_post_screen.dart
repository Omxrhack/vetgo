import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';

/// Pantalla completa para crear publicación (Markdown: títulos, negritas).
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
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
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
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

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Nueva publicación',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _publish,
              child: Text(
                'Publicar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FmtChip(
                  label: 'Título',
                  onTap: () => _insert('# '),
                ),
                _FmtChip(
                  label: 'Subtítulo',
                  onTap: () => _insert('## '),
                ),
                _FmtChip(
                  label: 'Negrita',
                  onTap: () => _insert('**negrita**'),
                ),
                _FmtChip(
                  label: 'Cursiva',
                  onTap: () => _insert('_cursiva_'),
                ),
                _FmtChip(
                  label: 'Lista',
                  onTap: () => _insert('- '),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                maxLength: 2000,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                decoration: InputDecoration(
                  hintText: 'Escribe con Markdown.\n# Título\n## Subtítulo\n**negrita**',
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FmtChip extends StatelessWidget {
  const _FmtChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
