import 'package:flutter/material.dart';

import 'package:vetgo/widgets/client/client_soft_card.dart';

/// Tarjeta de producto para la tienda.
class StoreProductCard extends StatefulWidget {
  const StoreProductCard({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.stock,
    required this.quantityInCart,
    this.imageUrl,
    this.onTap,
    required this.onAdd,
  });

  final String name;
  final String priceLabel;
  final int stock;
  final int quantityInCart;
  final String? imageUrl;
  final VoidCallback? onTap;
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

    return ClientSoftCard(
      padding: EdgeInsets.zero,
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(23),
              ),
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                    )
                  : ColoredBox(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.65,
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 44,
                        color: scheme.primary.withValues(alpha: 0.42),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.stock > 0 ? 'Stock: ${widget.stock}' : 'Sin stock',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.stock > 0
                        ? scheme.onSurfaceVariant
                        : scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.quantityInCart > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'En carrito: ${widget.quantityInCart}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: anim, child: child),
                        ),
                        child: _busy
                            ? Padding(
                                key: const ValueKey<String>('busy'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: scheme.primary,
                                  ),
                                ),
                              )
                            : _justAdded
                            ? DecoratedBox(
                                key: const ValueKey<String>('ok'),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer.withValues(
                                    alpha: 0.65,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 20,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              )
                            : FilledButton.tonal(
                                key: const ValueKey<String>('add'),
                                onPressed: widget.stock > 0 ? _tapAdd : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(40, 40),
                                  maximumSize: const Size(44, 44),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: scheme.primary,
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
