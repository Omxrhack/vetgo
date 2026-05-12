import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/vet/store/vet_product_form_screen.dart';
import 'package:vetgo/vet/store/vet_store_orders_screen.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';

class VetStoreAdminScreen extends StatefulWidget {
  const VetStoreAdminScreen({super.key});

  @override
  State<VetStoreAdminScreen> createState() => _VetStoreAdminScreenState();
}

class _VetStoreAdminScreenState extends State<VetStoreAdminScreen> {
  final _api = VetgoApiClient();
  List<StoreProductVm> _products = const <StoreProductVm>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await _api.listProducts(limit: 50);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    final raw = data?['data'];
    setState(() {
      _loading = false;
      _products = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      StoreProductVm.fromApiJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <StoreProductVm>[];
    });
  }

  Future<void> _openForm([StoreProductVm? product]) async {
    final changed = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => VetProductFormScreen(product: product),
      ),
    );
    if (changed != null) {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tienda veterinaria'),
          actions: [
            IconButton(
              tooltip: 'Nuevo producto',
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_business_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Productos'),
              Tab(text: 'Pedidos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadProducts,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [Text(_error!, textAlign: TextAlign.center)],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: _products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return VetSoftCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => _openForm(product),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 58,
                                  height: 58,
                                  child:
                                      product.imageUrl != null &&
                                          product.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : ColoredBox(
                                          color: scheme.primaryContainer
                                              .withValues(alpha: 0.35),
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
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${product.priceLabel} · Stock ${product.stock}',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const VetStoreOrdersScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
