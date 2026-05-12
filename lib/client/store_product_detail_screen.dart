import 'package:flutter/material.dart';

import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class StoreProductDetailScreen extends StatefulWidget {
  const StoreProductDetailScreen({
    super.key,
    required this.product,
    required this.quantityInCart,
    required this.onAdd,
  });

  final StoreProductVm product;
  final int quantityInCart;
  final Future<void> Function(StoreProductVm product, int quantity) onAdd;

  @override
  State<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  int _quantity = 1;
  bool _busy = false;

  int get _remaining => widget.product.stock - widget.quantityInCart;

  void _setQuantity(int value) {
    final max = _remaining <= 0 ? 1 : _remaining;
    final next = value < 1 ? 1 : (value > max ? max : value);
    setState(() => _quantity = next);
  }

  Future<void> _add() async {
    if (_busy || _remaining <= 0) return;
    setState(() => _busy = true);
    await widget.onAdd(widget.product, _quantity);
    if (!mounted) return;
    setState(() => _busy = false);
    VetgoNotice.show(
      context,
      message: '${widget.product.name} agregado al carrito.',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: scheme.primaryContainer.withValues(alpha: 0.35),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 76,
                        color: scheme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          ClientSoftCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.priceLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    product.category.isEmpty ? 'Producto' : product.category,
                  ),
                  backgroundColor: scheme.primaryContainer.withValues(
                    alpha: 0.55,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.description.isEmpty
                      ? 'Producto disponible en tienda Vetgo.'
                      : product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  _remaining > 0
                      ? 'Disponibles: $_remaining'
                      : 'Sin stock disponible',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _remaining > 0
                        ? scheme.onSurfaceVariant
                        : scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _remaining <= 0
                          ? null
                          : () => _setQuantity(_quantity - 1),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Text(
                      '$_quantity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: _remaining <= 0 || _quantity >= _remaining
                          ? null
                          : () => _setQuantity(_quantity + 1),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy || _remaining <= 0 ? null : _add,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_shopping_cart_outlined),
                  label: Text(_busy ? 'Agregando...' : 'Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
