import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/store_category_pill.dart';
import 'package:vetgo/widgets/client/store_product_card.dart';

/// Tienda Vetgo: catálogo desde `GET /api/products` con micro-animaciones.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _search = TextEditingController();
  final VetgoApiClient _api = VetgoApiClient();

  int _categoryIndex = 0;
  List<String> _categories = <String>['Todos'];

  List<_ProductRow> _products = <_ProductRow>[];
  bool _loading = true;
  String? _error;

  static final NumberFormat _money = NumberFormat.currency(locale: 'es_MX', symbol: r'$');

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
    final categoryParam = (cat != null && cat != 'Todos') ? cat : null;

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
    final catSet = <String>{'Todos'};

    if (raw is List<dynamic>) {
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final name = m['name']?.toString() ?? 'Producto';
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

    final sortedCats = catSet.where((c) => c != 'Todos').toList()..sort();
    final nextCategories = <String>['Todos', ...sortedCats];

    setState(() {
      _loading = false;
      _error = null;
      _products = rows;
      // Solo recalculamos pestañas cuando el listado es sin filtro de categoría (evita perder opciones al filtrar).
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tienda Vetgo'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Buscar productos…',
                prefixIcon: Icon(Icons.search_rounded, color: ClientPastelColors.mutedOn(context)),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _loadProducts,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                return StoreCategoryPill(
                  label: _categories[i],
                  selected: _categoryIndex == i,
                  selectedColor: ClientPastelColors.mintSoft.withValues(alpha: 0.85),
                  onTap: () {
                    setState(() => _categoryIndex = i);
                    _loadProducts();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Text(
                          _error != null
                              ? 'No se pudo cargar el catálogo.'
                              : 'No hay productos con estos filtros.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: ClientPastelColors.mutedOn(context)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, i) {
                            final p = _products[i];
                            return StoreProductCard(
                              name: p.name,
                              priceLabel: p.priceLabel,
                              imageUrl: p.imageUrl,
                              onAdd: () async {
                                await Future<void>.delayed(const Duration(milliseconds: 400));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${p.name} a�adido al carrito (demo).'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                );
                              },
                            )
                                .animate()
                                .fadeIn(delay: (40 * i).ms, duration: 280.ms, curve: Curves.easeOutCubic)
                                .slideY(begin: 0.04, end: 0, delay: (40 * i).ms, duration: 280.ms, curve: Curves.easeOutCubic);
                          },
                        ),
                      ),
          ),
        ],
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
