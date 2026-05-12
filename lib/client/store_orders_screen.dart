import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_order_vm.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class StoreOrdersScreen extends StatefulWidget {
  const StoreOrdersScreen({super.key});

  @override
  State<StoreOrdersScreen> createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> {
  final _api = VetgoApiClient();
  List<StoreOrderVm> _orders = const <StoreOrderVm>[];
  bool _loading = true;
  String? _error;
  final Set<String> _cancelling = <String>{};

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
    final (data, err) = await _api.listMyStoreOrders();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
        _orders = const <StoreOrderVm>[];
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

  Future<void> _cancel(StoreOrderVm order) async {
    setState(() => _cancelling.add(order.id));
    final (_, err) = await _api.cancelStoreOrder(orderId: order.id);
    if (!mounted) return;
    setState(() => _cancelling.remove(order.id));
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: 'Pedido cancelado.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _orders.isEmpty
          ? const Center(child: Text('Todavía no tienes pedidos.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                  return ClientSoftCard(
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
                            Chip(
                              label: Text(order.statusLabel),
                              backgroundColor: scheme.primaryContainer
                                  .withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(created, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(order.fulfillmentLabel),
                        const SizedBox(height: 10),
                        for (final item in order.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity} x ${item.productName}',
                                  ),
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
                            if (order.canCancel)
                              TextButton(
                                onPressed: _cancelling.contains(order.id)
                                    ? null
                                    : () => _cancel(order),
                                child: Text(
                                  _cancelling.contains(order.id)
                                      ? 'Cancelando...'
                                      : 'Cancelar',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
