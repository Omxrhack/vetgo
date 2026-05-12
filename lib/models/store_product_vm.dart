import 'package:intl/intl.dart';

final NumberFormat _storeMoney = NumberFormat.currency(
  locale: 'es_MX',
  symbol: r'$',
);

class StoreProductVm {
  const StoreProductVm({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    this.active = true,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final bool active;
  final String? imageUrl;

  String get priceLabel => _storeMoney.format(price);
  bool get inStock => stock > 0;

  factory StoreProductVm.fromApiJson(Map<String, dynamic> json) {
    final priceRaw = json['price'];
    final stockRaw = json['stock'];
    final image = json['image_url']?.toString().trim();
    return StoreProductVm(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Producto',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw?.toString() ?? '') ?? 0,
      stock: stockRaw is num
          ? stockRaw.toInt()
          : int.tryParse(stockRaw?.toString() ?? '') ?? 0,
      active: json['active'] != false,
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }
}

class StoreCartLine {
  const StoreCartLine({required this.product, required this.quantity});

  final StoreProductVm product;
  final int quantity;

  double get lineTotal => product.price * quantity;
  String get lineTotalLabel => _storeMoney.format(lineTotal);
}

String formatStoreMoney(num value) => _storeMoney.format(value);
