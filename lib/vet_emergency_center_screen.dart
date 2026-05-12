import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/vet_route_screen.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class VetEmergencyCenterScreen extends StatefulWidget {
  const VetEmergencyCenterScreen({
    super.key,
    required this.api,
    required this.resolveVetCoordinates,
    required this.refreshSignal,
  });

  final VetgoApiClient api;
  final (double lat, double lng) Function() resolveVetCoordinates;
  final int refreshSignal;

  @override
  State<VetEmergencyCenterScreen> createState() =>
      _VetEmergencyCenterScreenState();
}

class _VetEmergencyCenterScreenState extends State<VetEmergencyCenterScreen> {
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VetEmergencyCenterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final (data, err) = await widget.api.getVetEmergenciesActive();
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    final raw = data?['emergencies'];
    setState(() {
      _loading = false;
      _items = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const <Map<String, dynamic>>[];
    });
  }

  Future<void> _startRoute(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _busy.add(id));
    if (row['status'] == 'open') {
      final (_, err) = await widget.api.respondVetEmergency(
        emergencyId: id,
        accept: true,
      );
      if (!mounted) return;
      if (err != null) {
        setState(() => _busy.remove(id));
        VetgoNotice.show(context, message: err, isError: true);
        return;
      }
    }
    final coords = widget.resolveVetCoordinates();
    final (track, errTrack) = await widget.api.createTrackingSession(
      emergencyId: id,
      vetLat: coords.$1,
      vetLng: coords.$2,
    );
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (errTrack != null) {
      VetgoNotice.show(context, message: errTrack, isError: true);
      return;
    }
    final sessionId = track?['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      VetgoNotice.show(
        context,
        message: 'No se pudo iniciar la ruta.',
        isError: true,
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VetRouteScreen(
          trackingSessionId: sessionId,
          title: 'Ruta de emergencia',
        ),
      ),
    );
    await _load();
  }

  Future<void> _close(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _busy.add(id));
    final (_, err) = await widget.api.closeVetEmergency(emergencyId: id);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: 'Emergencia cerrada.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergencias')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [Text(_error!, textAlign: TextAlign.center)],
              )
            : _items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No tienes emergencias activas.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = _items[index];
                  final id = row['id']?.toString() ?? '';
                  final pet = row['pet'] is Map ? row['pet'] as Map : const {};
                  final created = DateTime.tryParse(
                    row['created_at']?.toString() ?? '',
                  );
                  final busy = _busy.contains(id);
                  return VetSoftCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pet['name']?.toString() ?? 'Paciente',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(row['status']?.toString() ?? 'open'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(row['symptoms']?.toString() ?? ''),
                        const SizedBox(height: 8),
                        if (created != null)
                          Text(
                            DateFormat(
                              'd MMM · HH:mm',
                              'es',
                            ).format(created.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (row['distance_km'] != null)
                          Text(
                            '${row['distance_km']} km aprox.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (busy)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
                              FilledButton.icon(
                                onPressed: () => _startRoute(row),
                                icon: const Icon(Icons.route_outlined),
                                label: const Text('Ruta'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _close(row),
                                child: const Text('Cerrar'),
                              ),
                            ],
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
