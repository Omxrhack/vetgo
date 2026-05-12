import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/live_tracking_screen.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _api = VetgoApiClient();
  late Map<String, dynamic> _appointment;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _appointment = Map<String, dynamic>.from(widget.appointment);
  }

  String get _id => _appointment['id']?.toString() ?? '';
  String get _status => _appointment['status']?.toString() ?? '';
  bool get _canCancel => _status == 'pending' || _status == 'confirmed';
  bool get _canReview => _status == 'completed' && _vetId != null;

  String? get _vetId {
    final vet = _appointment['vet'];
    if (vet is Map) return vet['id']?.toString();
    return null;
  }

  Future<void> _cancel() async {
    if (_id.isEmpty || _busy) return;
    setState(() => _busy = true);
    final (data, err) = await _api.cancelAppointment(appointmentId: _id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    final appt = data?['appointment'];
    if (appt is Map<String, dynamic>) {
      setState(() => _appointment = appt);
    }
    VetgoNotice.show(context, message: 'Cita cancelada.');
    Navigator.of(context).pop(true);
  }

  Future<void> _review() async {
    final vetId = _vetId;
    if (vetId == null || _id.isEmpty) return;
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reseñar atención'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = value),
                    icon: Icon(
                      value <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                  );
                }),
              ),
              TextField(
                controller: comment,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comentario opcional',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      comment.dispose();
      return;
    }
    final text = comment.text.trim();
    comment.dispose();

    final (_, err) = await _api.createReview(
      revieweeId: vetId,
      appointmentId: _id,
      rating: rating,
      comment: text.isEmpty ? null : text,
    );
    if (!mounted) return;
    VetgoNotice.show(
      context,
      message: err ?? 'Reseña enviada.',
      isError: err != null,
    );
  }

  Future<void> _track() async {
    final (data, err) = await _api.listActiveTrackingSessions();
    if (!mounted) return;
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    final sessions = data?['sessions'];
    Map<String, dynamic>? match;
    if (sessions is List) {
      for (final item in sessions.whereType<Map<String, dynamic>>()) {
        if (item['appointment_id']?.toString() == _id) {
          match = item;
          break;
        }
      }
    }
    final sessionId = match?['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      VetgoNotice.show(
        context,
        message: 'Aún no hay ruta activa para esta cita.',
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveTrackingScreen(
          trackingSessionId: sessionId,
          vetName: _vetName,
          etaLabel: _etaLabel(match),
          vetPhotoUrl: _vetAvatar,
        ),
      ),
    );
  }

  String _etaLabel(Map<String, dynamic>? session) {
    final raw = session?['eta_minutes'];
    final minutes = raw is num
        ? raw.round()
        : int.tryParse(raw?.toString() ?? '');
    return minutes == null ? 'ETA pendiente' : '$minutes min';
  }

  String get _petName {
    final pet = _appointment['pet'];
    if (pet is Map) return pet['name']?.toString() ?? 'Mascota';
    return 'Mascota';
  }

  String get _vetName {
    final vet = _appointment['vet'];
    if (vet is Map) {
      return vet['full_name']?.toString() ?? 'Veterinario pendiente';
    }
    return 'Veterinario pendiente';
  }

  String? get _vetAvatar {
    final vet = _appointment['vet'];
    if (vet is Map) return vet['avatar_url']?.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scheduled = DateTime.tryParse(
      _appointment['scheduled_at']?.toString() ?? '',
    )?.toLocal();
    final type = _appointment['appointment_type']?.toString().trim();
    final reason = _appointment['reason']?.toString().trim();
    final notes = _appointment['notes']?.toString().trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de cita')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _petName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.event_rounded,
                    text: scheduled == null
                        ? 'Fecha pendiente'
                        : DateFormat(
                            'EEEE d MMM y · HH:mm',
                            'es',
                          ).format(scheduled),
                  ),
                  _InfoLine(
                    icon: Icons.medical_services_outlined,
                    text: type?.isNotEmpty == true
                        ? type!
                        : 'Consulta programada',
                  ),
                  if (reason?.isNotEmpty == true)
                    _InfoLine(icon: Icons.notes_rounded, text: reason!),
                  _InfoLine(icon: Icons.person_rounded, text: _vetName),
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(_status.isEmpty ? 'pending' : _status),
                    backgroundColor: scheme.primaryContainer,
                  ),
                  if (notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Notas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _track,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Rastrear ruta'),
          ),
          const SizedBox(height: 10),
          if (_canCancel)
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(_busy ? 'Cancelando...' : 'Cancelar cita'),
            ),
          if (_canReview)
            OutlinedButton.icon(
              onPressed: _review,
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('Dejar reseña'),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: muted),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
