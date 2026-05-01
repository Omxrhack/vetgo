import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/widgets/vet/vet_async_toggle.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Programar una visita desde expediente (POST /api/vet/appointments).
class VetBookAppointmentScreen extends StatefulWidget {
  const VetBookAppointmentScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  final String petId;
  final String petName;

  @override
  State<VetBookAppointmentScreen> createState() => _VetBookAppointmentScreenState();
}

class _VetBookAppointmentScreenState extends State<VetBookAppointmentScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  final TextEditingController _notes = TextEditingController();

  DateTime? _visitDate;
  TimeOfDay? _visitTime;
  bool _submitBusy = false;

  void _ensureDefaults() {
    final base = DateTime.now().add(const Duration(days: 1));
    _visitDate ??= DateTime(base.year, base.month, base.day);
    _visitTime ??= const TimeOfDay(hour: 10, minute: 0);
  }

  DateTime _combinedLocal() {
    _ensureDefaults();
    final d = _visitDate!;
    final t = _visitTime!;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool _isFuture() => _combinedLocal().isAfter(DateTime.now());

  Future<void> _pickDate() async {
    _ensureDefaults();
    final now = DateTime.now();
    final last = now.add(const Duration(days: 365));
    final d = await showDatePicker(
      context: context,
      initialDate: _visitDate!,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: last,
    );
    if (d != null) setState(() => _visitDate = DateTime(d.year, d.month, d.day));
  }

  Future<void> _pickTime() async {
    _ensureDefaults();
    final t = await showTimePicker(
      context: context,
      initialTime: _visitTime!,
    );
    if (t != null) setState(() => _visitTime = t);
  }

  Future<void> _submit() async {
    _ensureDefaults();
    if (!_isFuture()) {
      VetgoNotice.show(context, message: AppStrings.scheduleFechaPasada, isError: true);
      return;
    }
    setState(() => _submitBusy = true);
    final at = _combinedLocal().toUtc();
    final notes = _notes.text.trim();
    final (_, err) = await _api.createVetAppointment(
      petId: widget.petId,
      scheduledAtIso: at.toIso8601String(),
      notes: notes.isEmpty ? null : notes,
    );
    if (!mounted) return;
    setState(() => _submitBusy = false);
    if (err != null) {
      VetgoNotice.show(context, message: err, isError: true);
      return;
    }
    VetgoNotice.show(context, message: AppStrings.vetBookAppointmentGuardada);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    _ensureDefaults();

    final timeDisplay = DateFormat.Hm('es').format(
      DateTime(1970, 1, 1, _visitTime!.hour, _visitTime!.minute),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.vetBookAppointmentTitulo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          VetSoftCard(
            padding: const EdgeInsets.all(18),
            color: VetOperatorColors.mintSoft.withValues(alpha: 0.42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.petName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.vetBookAppointmentCuandoTitulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.62),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(DateFormat.yMMMd('es').format(_visitDate!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(timeDisplay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _notes,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: AppStrings.scheduleNotasOpcional,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          VetAsyncPrimaryButton(
            label: AppStrings.vetBookAppointmentEnviar,
            busy: _submitBusy,
            onPressed: _submitBusy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
