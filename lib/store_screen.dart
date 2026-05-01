import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/store_category_pill.dart';
import 'package:vetgo/widgets/client/store_product_card.dart';

/// Tienda Vetgo: catùlogo demo con micro-animaciones en ù+ Agregarù.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _search = TextEditingController();
  int _categoryIndex = 0;

  static const _categories = ['Alimentos', 'Medicamentos', 'Juguetes', 'Higiene'];

  static const List<_ProductVm> _products = [
    _ProductVm('Croquetas premium', '\$489', null),
    _ProductVm('Snack dental', '\$129', null),
    _ProductVm('Antiparasitario', '\$215', null),
    _ProductVm('Pelota interactiva', '\$189', null),
    _ProductVm('Shampoo suave', '\$165', null),
    _ProductVm('Arenero biodegradable', '\$340', null),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
              decoration: InputDecoration(
                hintText: 'Buscar productosÖ',
                prefixIcon: Icon(Icons.search_rounded, color: ClientPastelColors.mutedOn(context)),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
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
                  onTap: () => setState(() => _categoryIndex = i),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
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
                  priceLabel: p.price,
                  imageUrl: p.imageUrl,
                  onAdd: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 700));
                  },
                )
                    .animate()
                    .fadeIn(delay: (40 * i).ms, duration: 280.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.04, end: 0, delay: (40 * i).ms, duration: 280.ms, curve: Curves.easeOutCubic);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductVm {
  const _ProductVm(this.name, this.price, this.imageUrl);
  final String name;
  final String price;
  final String? imageUrl;
}
