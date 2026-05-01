import 'package:flutter/material.dart';

import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';

/// Tarjeta de producto con botón "+ Agregar" animado (simula endpoint).
class StoreProductCard extends StatefulWidget {
  const StoreProductCard({
    super.key,
    required this.name,
    required this.priceLabel,
    this.imageUrl,
    required this.onAdd,
  });

  final String name;
  final String priceLabel;
  final String? imageUrl;
  final Future<void> Function() onAdd;

  @override
  State<StoreProductCard> createState() => _StoreProductCardState();
}

class _StoreProductCardState extends State<StoreProductCard> {
  bool _busy = false;
  bool _justAdded = false;

  Future<void> _tapAdd() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _justAdded = false;
    });
    try {
      await widget.onAdd();
      if (mounted) setState(() => _justAdded = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _justAdded = false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = ClientPastelColors.mutedOn(context);

    return ClientSoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      alignment: Alignment.center,
                    )
                  : ColoredBox(
                      color: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                      child: Center(
                        child: Icon(Icons.pets_rounded, size: 42, color: scheme.primary.withValues(alpha: 0.45)),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.priceLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _busy
                  ? DecoratedBox(
                      key: const ValueKey<String>('busy'),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    )
                  : _justAdded
                      ? DecoratedBox(
                          key: const ValueKey<String>('ok'),
                          decoration: BoxDecoration(
                            color: ClientPastelColors.mintSoft.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ClientPastelColors.mintDeep.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, color: ClientPastelColors.mintDeep, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Añadido',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: ClientPastelColors.mintDeep,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton(
                          key: const ValueKey<String>('add'),
                          style: TextButton.styleFrom(
                            backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.55),
                            foregroundColor: muted,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _tapAdd,
                          child: const Text('+ Agregar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
