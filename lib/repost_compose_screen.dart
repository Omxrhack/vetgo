import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/social_models.dart';

/// Pantalla para republicar con comentario opcional (quote).
class RepostComposeScreen extends StatefulWidget {
  const RepostComposeScreen({super.key, required this.original});

  final PostVm original;

  @override
  State<RepostComposeScreen> createState() => _RepostComposeScreenState();
}

class _RepostComposeScreenState extends State<RepostComposeScreen> {
  final _quote = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _quote.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final q = _quote.text.trim();
    final (data, err) = await VetgoApiClient().createRepost(
      widget.original.id,
      quoteBody: q.isEmpty ? null : q,
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

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Republicar',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Publicación original · ${o.author.fullName}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              o.body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Añade un comentario (opcional)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quote,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: '¿Qué opinas?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Republicar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
