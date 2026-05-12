import 'package:flutter/material.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/store_product_vm.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class VetProductFormScreen extends StatefulWidget {
  const VetProductFormScreen({super.key, this.product});

  final StoreProductVm? product;

  @override
  State<VetProductFormScreen> createState() => _VetProductFormScreenState();
}

class _VetProductFormScreenState extends State<VetProductFormScreen> {
  final _api = VetgoApiClient();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _active = true;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _description.text = product.description;
      _category.text = product.category;
      _price.text = product.price.toStringAsFixed(2);
      _stock.text = product.stock.toString();
      _imageUrl.text = product.imageUrl ?? '';
      _active = product.active;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _category.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _payload() {
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    final stock = int.tryParse(_stock.text.trim());
    if (_name.text.trim().length < 2 ||
        _category.text.trim().length < 2 ||
        price == null ||
        price <= 0 ||
        stock == null ||
        stock < 0) {
      VetgoNotice.show(
        context,
        message: 'Completa nombre, categoría, precio y stock válidos.',
        isError: true,
      );
      return null;
    }

    return <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim(),
      'price': price,
      'stock': stock,
      'active': _active,
      if (_imageUrl.text.trim().isNotEmpty) 'image_url': _imageUrl.text.trim(),
    };
  }

  Future<void> _save() async {
    final body = _payload();
    if (body == null || _saving) return;
    setState(() => _saving = true);
    final (data, err) = _isEditing
        ? await _api.updateVetProduct(productId: widget.product!.id, body: body)
        : await _api.createVetProduct(body: body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    final product = data?['product'];
    VetgoNotice.show(
      context,
      message: _isEditing ? 'Producto actualizado.' : 'Producto creado.',
    );
    Navigator.of(context).pop(product is Map<String, dynamic> ? product : true);
  }

  Future<void> _delete() async {
    final product = widget.product;
    if (product == null || _saving) return;
    setState(() => _saving = true);
    final err = await _api.deleteVetProduct(productId: product.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: 'Producto desactivado.');
    Navigator.of(context).pop('deleted');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio MXN'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'URL de imagen (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: Text('Producto activo', style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
