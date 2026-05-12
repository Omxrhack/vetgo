import 'package:flutter/material.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/location/onboarding_location_fill.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class StoreCheckoutScreen extends StatefulWidget {
  const StoreCheckoutScreen({super.key, required this.lines});

  final List<StoreCartLine> lines;

  @override
  State<StoreCheckoutScreen> createState() => _StoreCheckoutScreenState();
}

class _StoreCheckoutScreenState extends State<StoreCheckoutScreen> {
  final _api = VetgoApiClient();
  final _address = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _notes = TextEditingController();

  String _fulfillment = 'delivery';
  bool _busy = false;
  bool _locationBusy = false;

  double get _total =>
      widget.lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  @override
  void initState() {
    super.initState();
    _prefillFromOnboarding();
  }

  @override
  void dispose() {
    _address.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _prefillFromOnboarding() async {
    final session = await AuthStorage.loadSession();
    if (!mounted) return;
    final profile = session?.profile;
    final details = session?.details;
    final clientDetails = details?['client_details'];
    if (clientDetails is! Map) return;

    final address = clientDetails['address_text']?.toString().trim();
    final contactName = clientDetails['default_contact_name']
        ?.toString()
        .trim();
    final contactPhone = clientDetails['default_contact_phone']
        ?.toString()
        .trim();
    final preferred = clientDetails['preferred_fulfillment_method']
        ?.toString()
        .trim();
    final deliveryNotes = clientDetails['delivery_notes']?.toString().trim();

    setState(() {
      if (_address.text.trim().isEmpty &&
          address != null &&
          address.isNotEmpty) {
        _address.text = address;
      }
      if (_contactName.text.trim().isEmpty) {
        final fallback = contactName?.isNotEmpty == true
            ? contactName
            : profile?['full_name']?.toString().trim();
        if (fallback != null && fallback.isNotEmpty) {
          _contactName.text = fallback;
        }
      }
      if (_contactPhone.text.trim().isEmpty) {
        final fallback = contactPhone?.isNotEmpty == true
            ? contactPhone
            : profile?['phone']?.toString().trim();
        if (fallback != null && fallback.isNotEmpty) {
          _contactPhone.text = fallback;
        }
      }
      if (_notes.text.trim().isEmpty &&
          deliveryNotes != null &&
          deliveryNotes.isNotEmpty) {
        _notes.text = deliveryNotes;
      }
      if (preferred == 'delivery' || preferred == 'pickup_contact') {
        _fulfillment = preferred!;
      }
    });
  }

  Future<void> _fillAddress() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    final result = await loadAddressFromDeviceLocation();
    if (!mounted) return;
    setState(() => _locationBusy = false);
    if (!result.ok || result.addressText == null) {
      VetgoNotice.show(
        context,
        message: result.errorMessage ?? 'No se pudo obtener tu domicilio.',
        isError: true,
      );
      return;
    }
    _address.text = result.addressText!;
    VetgoNotice.show(context, message: 'Domicilio obtenido.');
  }

  Future<void> _submit() async {
    final address = _address.text.trim();
    final phone = _contactPhone.text.trim();
    if (_fulfillment == 'delivery' && address.isEmpty) {
      VetgoNotice.show(
        context,
        message: 'Agrega el domicilio de entrega.',
        isError: true,
      );
      return;
    }
    if (_fulfillment == 'pickup_contact' && phone.isEmpty) {
      VetgoNotice.show(
        context,
        message: 'Agrega un teléfono de contacto.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    final (data, err) = await _api.createStoreOrder(
      fulfillmentMethod: _fulfillment,
      items: widget.lines
          .map(
            (line) => <String, dynamic>{
              'product_id': line.product.id,
              'quantity': line.quantity,
            },
          )
          .toList(),
      deliveryAddressText: address.isEmpty ? null : address,
      contactName: _contactName.text.trim().isEmpty
          ? null
          : _contactName.text.trim(),
      contactPhone: phone.isEmpty ? null : phone,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    final orderId = data?['order'] is Map
        ? (data!['order'] as Map)['id']?.toString()
        : null;
    VetgoNotice.show(
      context,
      message: orderId == null || orderId.isEmpty
          ? 'Pedido registrado.'
          : 'Pedido registrado: ${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ClientSoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrega',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _fulfillment == 'delivery'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: scheme.primary,
                  ),
                  title: const Text('A domicilio'),
                  onTap: () => setState(() => _fulfillment = 'delivery'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _fulfillment == 'pickup_contact'
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: scheme.primary,
                  ),
                  title: const Text('Recoger/contacto'),
                  onTap: () => setState(() => _fulfillment = 'pickup_contact'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_fulfillment == 'delivery') ...[
            TextField(
              controller: _address,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Domicilio de entrega',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locationBusy ? null : _fillAddress,
              icon: _locationBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _locationBusy ? 'Obteniendo domicilio...' : 'Usar mi ubicación',
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _contactName,
            decoration: InputDecoration(
              labelText: 'Nombre de contacto (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contactPhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _fulfillment == 'pickup_contact'
                  ? 'Teléfono de contacto'
                  : 'Teléfono de contacto (opcional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ClientSoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                for (final line in widget.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${line.quantity} x ${line.product.name}',
                          ),
                        ),
                        Text(line.lineTotalLabel),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    const Text('Total'),
                    const Spacer(),
                    Text(
                      formatStoreMoney(_total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_busy ? 'Creando pedido...' : 'Confirmar pedido'),
          ),
        ),
      ),
    );
  }
}
