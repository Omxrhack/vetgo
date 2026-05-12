import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/client/store_cart_screen.dart';
import 'package:vetgo/client/store_checkout_screen.dart';
import 'package:vetgo/client/store_orders_screen.dart';
import 'package:vetgo/client/store_product_detail_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/vet/store/vet_store_admin_screen.dart';
import 'package:vetgo/widgets/client/store_category_pill.dart';
import 'package:vetgo/widgets/client/store_product_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Tienda Vetgo: catálogo desde `GET /api/products`.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, this.isVet = false});

  final bool isVet;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _search = TextEditingController();
  final VetgoApiClient _api = VetgoApiClient();

  int _categoryIndex = 0;
  List<String> _categories = <String>[AppStrings.storeCategoriaTodos];

  List<StoreProductVm> _products = <StoreProductVm>[];
  final Map<String, StoreProductVm> _productCache = <String, StoreProductVm>{};
  final Map<String, int> _cart = <String, int>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cat = (_categoryIndex > 0 && _categoryIndex < _categories.length)
        ? _categories[_categoryIndex]
        : null;
    final categoryParam = (cat != null && cat != AppStrings.storeCategoriaTodos)
        ? cat
        : null;

    final (data, err) = await _api.listProducts(
      page: 1,
      limit: 48,
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      category: categoryParam,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
        _products = [];
      });
      return;
    }

    final raw = data?['data'];
    final rows = <StoreProductVm>[];
    final catSet = <String>{AppStrings.storeCategoriaTodos};

    if (raw is List<dynamic>) {
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final product = StoreProductVm.fromApiJson(m);
        if (product.id.isEmpty) continue;
        final c = product.category.trim();
        if (c.isNotEmpty) {
          catSet.add(c);
        }
        rows.add(product);
        _productCache[product.id] = product;
      }
    }

    final sortedCats =
        catSet.where((c) => c != AppStrings.storeCategoriaTodos).toList()
          ..sort();
    final nextCategories = <String>[
      AppStrings.storeCategoriaTodos,
      ...sortedCats,
    ];

    setState(() {
      _loading = false;
      _error = null;
      _products = rows;
      if (categoryParam == null) {
        _categories = nextCategories;
        if (_categoryIndex >= _categories.length) {
          _categoryIndex = 0;
        }
      }
    });
  }

  int get _cartCount => _cart.values.fold<int>(0, (sum, qty) => sum + qty);

  List<StoreCartLine> get _cartLines {
    final lines = <StoreCartLine>[];
    for (final entry in _cart.entries) {
      final product = _productCache[entry.key];
      if (product == null || entry.value <= 0) continue;
      lines.add(StoreCartLine(product: product, quantity: entry.value));
    }
    return lines;
  }

  Future<void> _addToCart(StoreProductVm product, [int quantity = 1]) async {
    final current = _cart[product.id] ?? 0;
    final remaining = product.stock - current;
    if (remaining <= 0) {
      VetgoNotice.show(
        context,
        message: 'No hay más stock disponible.',
        isError: true,
      );
      return;
    }
    final addQty = quantity < 1
        ? 1
        : (quantity > remaining ? remaining : quantity);
    setState(() => _cart[product.id] = current + addQty);
  }

  Future<void> _openProduct(StoreProductVm product) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StoreProductDetailScreen(
          product: product,
          quantityInCart: _cart[product.id] ?? 0,
          onAdd: _addToCart,
        ),
      ),
    );
  }

  Future<bool> _openCheckout(List<StoreCartLine> lines) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StoreCheckoutScreen(lines: lines),
      ),
    );
    if (ok == true) {
      setState(() => _cart.clear());
      await _loadProducts();
      return true;
    }
    return false;
  }

  Future<void> _openCart() async {
    if (_cartLines.isEmpty) {
      VetgoNotice.show(context, message: 'Tu carrito está vacío.');
      return;
    }
    final result = await Navigator.of(context).push<StoreCartResult>(
      MaterialPageRoute<StoreCartResult>(
        builder: (_) =>
            StoreCartScreen(lines: _cartLines, onCheckout: _openCheckout),
      ),
    );
    if (!mounted || result == null || result.submitted) return;
    setState(() {
      _cart
        ..clear()
        ..addAll(result.quantities);
    });
  }

  Future<void> _openOrders() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StoreOrdersScreen()),
    );
    await _loadProducts();
  }

  Future<void> _openVetAdmin() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const VetStoreAdminScreen()),
    );
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint.withValues(alpha: 0.35),
        foregroundColor: scheme.onSurface,
        title: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.storeTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isVet)
            IconButton(
              tooltip: 'Gestionar tienda',
              onPressed: _openVetAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: 'Mis pedidos',
            onPressed: _openOrders,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Carrito',
              onPressed: _openCart,
              icon: Badge(
                isLabelVisible: _cartCount > 0,
                label: Text('$_cartCount'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              AppStrings.storeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Material(
              color: scheme.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: TextField(
                controller: _search,
                onSubmitted: (_) => _loadProducts(),
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: AppStrings.storeBuscarHint,
                  hintStyle: TextStyle(
                    color: ClientPastelColors.mutedOn(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: scheme.primary.withValues(alpha: 0.85),
                  ),
                  filled: true,
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    tooltip: AppStrings.storeBuscarTooltip,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.primary,
                    ),
                    onPressed: _loadProducts,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                return StoreCategoryPill(
                  label: _categories[i],
                  selected: _categoryIndex == i,
                  onTap: () {
                    setState(() => _categoryIndex = i);
                    _loadProducts();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: scheme.primary),
                  )
                : _products.isEmpty
                ? _StoreEmptyState(
                    message: _error ?? AppStrings.storeSinResultados,
                    showRetry: _error != null,
                    onRetry: _loadProducts,
                    isError: _error != null,
                  )
                : RefreshIndicator(
                    color: scheme.primary,
                    onRefresh: _loadProducts,
                    edgeOffset: 12,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        // Alto suficiente para pie (nombre + precio + CTA); la imagen usa Expanded en la tarjeta.
                        childAspectRatio: 0.58,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, i) {
                        final p = _products[i];
                        return StoreProductCard(
                              name: p.name,
                              priceLabel: p.priceLabel,
                              stock: p.stock,
                              quantityInCart: _cart[p.id] ?? 0,
                              imageUrl: p.imageUrl,
                              onTap: () => _openProduct(p),
                              onAdd: () async {
                                await _addToCart(p);
                                if (!context.mounted) {
                                  return;
                                }
                                VetgoNotice.show(
                                  context,
                                  message: '${p.name} agregado al carrito.',
                                );
                              },
                            )
                            .animate()
                            .fadeIn(
                              delay: (35 * i).ms,
                              duration: 280.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(
                              begin: 0.03,
                              end: 0,
                              delay: (35 * i).ms,
                              duration: 280.ms,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StoreEmptyState extends StatelessWidget {
  const _StoreEmptyState({
    required this.message,
    required this.showRetry,
    required this.onRetry,
    this.isError = false,
  });

  final String message;
  final bool showRetry;
  final VoidCallback onRetry;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconBg = isError
        ? scheme.errorContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final iconFg = isError
        ? scheme.error
        : scheme.onSurfaceVariant.withValues(alpha: 0.65);
    final iconData = isError
        ? Icons.cloud_off_outlined
        : Icons.inventory_2_outlined;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Icon(iconData, size: 48, color: iconFg),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isError
                    ? scheme.onSurface
                    : ClientPastelColors.mutedOn(context),
                height: 1.4,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(AppStrings.vetReintentar),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
