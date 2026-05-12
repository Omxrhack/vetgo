import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_order_vm.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class VetStoreOrdersScreen extends StatefulWidget {
  const VetStoreOrdersScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<VetStoreOrdersScreen> createState() => _VetStoreOrdersScreenState();
}

class _VetStoreOrdersScreenState extends State<VetStoreOrdersScreen> {
  final _api = VetgoApiClient();
  List<StoreOrderVm> _orders = const <StoreOrderVm>[];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await _api.listVetStoreOrders();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    final raw = data?['orders'];
    setState(() {
      _loading = false;
      _orders = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => StoreOrderVm.fromApiJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const <StoreOrderVm>[];
    });
  }

  Future<void> _setStatus(StoreOrderVm order, String status) async {
    setState(() => _busy.add(order.id));
    final (_, err) = await _api.updateVetStoreOrderStatus(
      orderId: order.id,
      status: status,
    );
    if (!mounted) return;
    setState(() => _busy.remove(order.id));
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: 'Pedido actualizado.');
    await _load();
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('No hay pedidos de tienda.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20, widget.embedded ? 8 : 12, 20, 32),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final created = order.createdAt == null
              ? 'Fecha pendiente'
              : DateFormat(
                  'd MMM y · HH:mm',
                  'es',
                ).format(order.createdAt!.toLocal());
          final busy = _busy.contains(order.id);
          return VetSoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pedido ${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Chip(label: Text(order.statusLabel)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(created, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(order.fulfillmentLabel),
                if (order.deliveryAddressText?.trim().isNotEmpty == true)
                  Text(
                    order.deliveryAddressText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (order.contactPhone?.trim().isNotEmpty == true)
                  Text(
                    'Tel. ${order.contactPhone}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 10),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.quantity} x ${item.productName}'),
                        ),
                        Text(item.lineTotalLabel),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    Text(
                      order.totalLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (busy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (order.status == 'pending_confirmation') ...[
                      TextButton(
                        onPressed: () => _setStatus(order, 'cancelled'),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _setStatus(order, 'confirmed'),
                        child: const Text('Confirmar'),
                      ),
                    ] else if (order.status == 'confirmed')
                      FilledButton.tonal(
                        onPressed: () => _setStatus(order, 'fulfilled'),
                        child: const Text('Entregar'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _content(context);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos de tienda')),
      body: _content(context),
    );
  }
}
