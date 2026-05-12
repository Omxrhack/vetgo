import 'package:vetgo/models/store_product_vm.dart';

class StoreOrderItemVm {
  const StoreOrderItemVm({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String id;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  String get lineTotalLabel => formatStoreMoney(lineTotal);

  factory StoreOrderItemVm.fromApiJson(Map<String, dynamic> json) {
    final quantityRaw = json['quantity'];
    final unitRaw = json['unit_price_mxn'];
    final lineRaw = json['line_total_mxn'];
    return StoreOrderItemVm(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? 'Producto',
      quantity: quantityRaw is num
          ? quantityRaw.toInt()
          : int.tryParse(quantityRaw?.toString() ?? '') ?? 0,
      unitPrice: unitRaw is num
          ? unitRaw.toDouble()
          : double.tryParse(unitRaw?.toString() ?? '') ?? 0,
      lineTotal: lineRaw is num
          ? lineRaw.toDouble()
          : double.tryParse(lineRaw?.toString() ?? '') ?? 0,
    );
  }
}

class StoreOrderVm {
  const StoreOrderVm({
    required this.id,
    required this.status,
    required this.fulfillmentMethod,
    required this.total,
    required this.createdAt,
    required this.items,
    this.ownerId,
    this.deliveryAddressText,
    this.contactName,
    this.contactPhone,
    this.notes,
    this.confirmedAt,
    this.fulfilledAt,
    this.cancelledAt,
  });

  final String id;
  final String? ownerId;
  final String status;
  final String fulfillmentMethod;
  final double total;
  final DateTime? createdAt;
  final List<StoreOrderItemVm> items;
  final String? deliveryAddressText;
  final String? contactName;
  final String? contactPhone;
  final String? notes;
  final DateTime? confirmedAt;
  final DateTime? fulfilledAt;
  final DateTime? cancelledAt;

  String get totalLabel => formatStoreMoney(total);
  bool get canCancel => status == 'pending_confirmation';

  String get statusLabel {
    switch (status) {
      case 'pending_confirmation':
        return 'Pendiente de confirmación';
      case 'confirmed':
        return 'Confirmado';
      case 'cancelled':
        return 'Cancelado';
      case 'fulfilled':
        return 'Entregado';
      default:
        return status;
    }
  }

  String get fulfillmentLabel {
    switch (fulfillmentMethod) {
      case 'delivery':
        return 'A domicilio';
      case 'pickup_contact':
        return 'Recoger/contacto';
      default:
        return fulfillmentMethod;
    }
  }

  factory StoreOrderVm.fromApiJson(Map<String, dynamic> json) {
    final totalRaw = json['total_mxn'];
    final rawItems = json['items'];
    return StoreOrderVm(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString(),
      status: json['status']?.toString() ?? '',
      fulfillmentMethod: json['fulfillment_method']?.toString() ?? '',
      total: totalRaw is num
          ? totalRaw.toDouble()
          : double.tryParse(totalRaw?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      confirmedAt: DateTime.tryParse(json['confirmed_at']?.toString() ?? ''),
      fulfilledAt: DateTime.tryParse(json['fulfilled_at']?.toString() ?? ''),
      cancelledAt: DateTime.tryParse(json['cancelled_at']?.toString() ?? ''),
      deliveryAddressText: json['delivery_address_text']?.toString(),
      contactName: json['contact_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      notes: json['notes']?.toString(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (e) => StoreOrderItemVm.fromApiJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : const <StoreOrderItemVm>[],
    );
  }
}
