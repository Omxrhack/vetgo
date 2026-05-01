import 'package:flutter/material.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/core/storage/preferred_vet_prefs.dart';
import 'package:vetgo/models/vet_catalog_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Lista veterinarios ([GET /api/vets]) y guarda el elegido en preferencias locales.
class ChooseVetScreen extends StatefulWidget {
  const ChooseVetScreen({super.key});

  @override
  State<ChooseVetScreen> createState() => _ChooseVetScreenState();
}

class _ChooseVetScreenState extends State<ChooseVetScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  List<VetCatalogVm> _vets = [];
  bool _loading = true;
  String? _error;
  String? _selectedId;

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
    final cur = await PreferredVetPrefs.readId();
    final (list, err) = await _api.listVetsCatalog();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
        _selectedId = cur;
      });
      return;
    }
    final parsed = <VetCatalogVm>[];
    for (final m in list ?? const <Map<String, dynamic>>[]) {
      final v = VetCatalogVm.fromJson(m);
      if (v.id.isNotEmpty && v.fullName.isNotEmpty) {
        parsed.add(v);
      }
    }
    setState(() {
      _vets = parsed;
      _selectedId = cur;
      _loading = false;
    });
  }

  Future<void> _select(VetCatalogVm v) async {
    await PreferredVetPrefs.save(id: v.id, displayName: v.fullName);
    if (!mounted) return;
    setState(() => _selectedId = v.id);
    VetgoNotice.show(context, message: AppStrings.vetPreferidoGuardado(v.fullName));
    Navigator.of(context).pop<bool>(true);
  }

  Future<void> _clear() async {
    await PreferredVetPrefs.clear();
    if (!mounted) return;
    setState(() => _selectedId = null);
    VetgoNotice.show(context, message: AppStrings.vetPreferidoQuitarOk);
    Navigator.of(context).pop<bool>(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.vetElegirTitulo),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text(AppStrings.vetReintentar)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Text(
                        AppStrings.vetElegirSubtitulo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ClientPastelColors.mutedOn(context),
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedId != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: _clear,
                            icon: const Icon(Icons.person_off_outlined),
                            label: const Text(AppStrings.vetQuitarPreferido),
                          ),
                        ),
                      if (_vets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            AppStrings.vetListaVacia,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      else
                        ..._vets.map(
                          (VetCatalogVm v) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                                  backgroundImage:
                                      v.avatarUrl != null && v.avatarUrl!.isNotEmpty ? NetworkImage(v.avatarUrl!) : null,
                                  child: v.avatarUrl == null || v.avatarUrl!.isEmpty
                                      ? Text(
                                          v.fullName.isNotEmpty ? v.fullName[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  v.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  v.displaySubtitle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: ClientPastelColors.mutedOn(context),
                                      ),
                                ),
                                trailing: _selectedId == v.id
                                    ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                                    : Icon(Icons.chevron_right_rounded, color: scheme.outline),
                                onTap: () => _select(v),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
