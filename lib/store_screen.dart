import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/store_category_pill.dart';
import 'package:vetgo/widgets/client/store_product_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Tienda Vetgo: catálogo desde `GET /api/products`.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _search = TextEditingController();
  final VetgoApiClient _api = VetgoApiClient();

  int _categoryIndex = 0;
  List<String> _categories = <String>[AppStrings.storeCategoriaTodos];

  List<_ProductRow> _products = <_ProductRow>[];
  bool _loading = true;
  String? _error;

  static final NumberFormat _money =
      NumberFormat.currency(locale: 'es_MX', symbol: r'$');

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
    final categoryParam =
        (cat != null && cat != AppStrings.storeCategoriaTodos) ? cat : null;

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
    final rows = <_ProductRow>[];
    final catSet = <String>{AppStrings.storeCategoriaTodos};

    if (raw is List<dynamic>) {
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final name = m['name']?.toString() ?? AppStrings.storeProductoFallback;
        final price = m['price'];
        final c = m['category']?.toString().trim() ?? '';
        if (c.isNotEmpty) {
          catSet.add(c);
        }
        var priceLabel = r'$0';
        if (price is num) {
          priceLabel = _money.format(price.toDouble());
        }
        rows.add(
          _ProductRow(
            name: name,
            priceLabel: priceLabel,
            category: c,
            imageUrl: m['image_url']?.toString(),
          ),
        );
      }
    }

    final sortedCats =
        catSet.where((c) => c != AppStrings.storeCategoriaTodos).toList()
          ..sort();
    final nextCategories =
        <String>[AppStrings.storeCategoriaTodos, ...sortedCats];

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
                  hintStyle: TextStyle(color: ClientPastelColors.mutedOn(context)),
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
                    icon: Icon(Icons.arrow_forward_rounded, color: scheme.primary),
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
                    child: CircularProgressIndicator(
                      color: scheme.primary,
                    ),
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
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            // Alto suficiente para pie (nombre + precio + CTA); la imagen usa Expanded en la tarjeta.
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, i) {
                            final p = _products[i];
                            return StoreProductCard(
                              name: p.name,
                              priceLabel: p.priceLabel,
                              imageUrl: p.imageUrl,
                              onAdd: () async {
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 400),
                                );
                                if (!context.mounted) return;
                                VetgoNotice.show(
                                  context,
                                  message:
                                      AppStrings.storeCarritoDemo(p.name),
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
    final iconData =
        isError ? Icons.cloud_off_outlined : Icons.inventory_2_outlined;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
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

class _ProductRow {
  const _ProductRow({
    required this.name,
    required this.priceLabel,
    required this.category,
    this.imageUrl,
  });

  final String name;
  final String priceLabel;
  final String category;
  final String? imageUrl;
}
