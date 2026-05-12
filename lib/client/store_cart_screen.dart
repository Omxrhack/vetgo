import 'package:flutter/material.dart';

import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';

class StoreCartResult {
  const StoreCartResult({required this.submitted, required this.quantities});

  final bool submitted;
  final Map<String, int> quantities;
}

class StoreCartScreen extends StatefulWidget {
  const StoreCartScreen({
    super.key,
    required this.lines,
    required this.onCheckout,
  });

  final List<StoreCartLine> lines;
  final Future<bool> Function(List<StoreCartLine> lines) onCheckout;

  @override
  State<StoreCartScreen> createState() => _StoreCartScreenState();
}

class _StoreCartScreenState extends State<StoreCartScreen> {
  late final Map<String, StoreProductVm> _products;
  late Map<String, int> _quantities;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _products = {
      for (final line in widget.lines) line.product.id: line.product,
    };
    _quantities = {
      for (final line in widget.lines) line.product.id: line.quantity,
    };
  }

  List<StoreCartLine> get _lines {
    final lines = <StoreCartLine>[];
    for (final entry in _quantities.entries) {
      final product = _products[entry.key];
      if (product == null || entry.value <= 0) continue;
      lines.add(StoreCartLine(product: product, quantity: entry.value));
    }
    return lines;
  }

  double get _total =>
      _lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  void _change(StoreProductVm product, int delta) {
    final current = _quantities[product.id] ?? 0;
    final rawNext = current + delta;
    final next = rawNext < 0
        ? 0
        : rawNext > product.stock
        ? product.stock
        : rawNext;
    setState(() {
      if (next <= 0) {
        _quantities.remove(product.id);
      } else {
        _quantities[product.id] = next;
      }
    });
  }

  Future<void> _checkout() async {
    if (_busy || _lines.isEmpty) return;
    setState(() => _busy = true);
    final ok = await widget.onCheckout(_lines);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop(
        StoreCartResult(submitted: true, quantities: const <String, int>{}),
      );
    }
  }

  void _close() {
    Navigator.of(context).pop(
      StoreCartResult(
        submitted: false,
        quantities: Map<String, int>.from(_quantities),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = _lines;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carrito'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _close,
          ),
        ),
        body: lines.isEmpty
            ? const Center(child: Text('Tu carrito está vacío.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                itemCount: lines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final line = lines[index];
                  final product = line.product;
                  return ClientSoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child:
                                product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? Image.network(
                                    product.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : ColoredBox(
                                    color: scheme.primaryContainer.withValues(
                                      alpha: 0.35,
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: scheme.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                line.lineTotalLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _change(product, -1),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              onPressed: line.quantity >= product.stock
                                  ? null
                                  : () => _change(product, 1),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatStoreMoney(_total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: lines.isEmpty || _busy ? null : _checkout,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _busy ? 'Confirmando...' : 'Continuar a checkout',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
