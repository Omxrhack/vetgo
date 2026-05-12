import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:vetgo/client/pet_form_screen.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';
import 'package:vetgo/widgets/client/pastel_status_chip.dart';
import 'package:vetgo/widgets/client/timeline_medical_tile.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Expediente medico digital de una mascota; el dueno puede cambiar la foto.
class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key, required this.pet, this.onChanged});

  final ClientPetVm pet;
  final Future<void> Function()? onChanged;

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  String? _photoUrlOverride;
  bool _uploadingPhoto = false;
  Map<String, dynamic>? _record;
  String? _recordError;

  @override
  void initState() {
    super.initState();
    _photoUrlOverride = widget.pet.photoUrl;
    _loadRecord();
  }

  String? get _photoDisplay =>
      (_photoUrlOverride != null && _photoUrlOverride!.isNotEmpty)
      ? _photoUrlOverride
      : widget.pet.photoUrl;

  Future<void> _pickAndUploadPetPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1536,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await x.readAsBytes();
      final name = x.name.trim().isNotEmpty ? x.name.trim() : 'pet.jpg';
      final (petRow, err) = await _api.uploadPetPhotoAsOwner(
        petId: widget.pet.id,
        bytes: bytes,
        filename: name,
      );
      if (!mounted) return;
      if (err != null) {
        VetgoNotice.show(context, message: err, isError: true);
        return;
      }
      final url = petRow?['photo_url']?.toString();
      if (url != null && url.isNotEmpty) {
        setState(() => _photoUrlOverride = url);
      }
      VetgoNotice.show(context, message: AppStrings.petPhotoActualizada);
      await widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _loadRecord() async {
    final (data, err) = await _api.getPetRecord(petId: widget.pet.id);
    if (!mounted) return;
    setState(() {
      _record = data;
      _recordError = err;
    });
  }

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => PetFormScreen(initialPet: widget.pet),
      ),
    );
    if (result == null || !mounted) return;
    await widget.onChanged?.call();
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop(true);
      return;
    }
    await _loadRecord();
  }

  List<Widget> _healthChips() {
    final vaccines = widget.pet.vaccinesUpToDate?.trim();
    final neutered = widget.pet.isNeutered;
    final notes = widget.pet.medicalNotes?.trim();
    return [
      PastelStatusChip(
        label: vaccines == null || vaccines.isEmpty
            ? 'Vacunas sin registrar'
            : 'Vacunas: $vaccines',
        icon: Icons.verified_rounded,
        backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.72),
        foregroundColor: ClientPastelColors.mintDeep,
      ),
      PastelStatusChip(
        label: neutered == null
            ? 'Esterilización sin dato'
            : (neutered ? 'Esterilizado' : 'No esterilizado'),
        icon: Icons.healing_rounded,
        backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.75),
        foregroundColor: ClientPastelColors.skyDeep,
      ),
      PastelStatusChip(
        label: notes == null || notes.isEmpty
            ? 'Sin alertas médicas'
            : 'Notas médicas',
        icon: notes == null || notes.isEmpty
            ? Icons.check_circle_outline_rounded
            : Icons.info_outline_rounded,
        backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.68),
      ),
    ];
  }

  List<Widget> _historyTiles() {
    final tiles = <Widget>[];
    final appointments = _record?['appointments'];
    final emergencies = _record?['emergencies'];
    final triage = _record?['triage_logs'];

    void addTile({
      required String title,
      required String subtitle,
      required String? rawDate,
      required Color color,
    }) {
      final dt = rawDate != null ? DateTime.tryParse(rawDate)?.toLocal() : null;
      tiles.add(
        TimelineMedicalTile(
          title: title,
          subtitle: subtitle,
          dateLabel: dt != null
              ? DateFormat('d MMM y', 'es').format(dt)
              : 'Sin fecha',
          dotColor: color,
          isLast: false,
        ),
      );
    }

    if (appointments is List) {
      for (final row in appointments.take(6)) {
        if (row is! Map) continue;
        addTile(
          title: 'Cita ${row['status'] ?? ''}'.trim(),
          subtitle: row['notes']?.toString().trim().isNotEmpty == true
              ? row['notes'].toString()
              : 'Visita veterinaria registrada.',
          rawDate: row['scheduled_at']?.toString(),
          color: ClientPastelColors.mintDeep,
        );
      }
    }
    if (emergencies is List) {
      for (final row in emergencies.take(3)) {
        if (row is! Map) continue;
        addTile(
          title: 'Emergencia ${row['status'] ?? ''}'.trim(),
          subtitle: row['symptoms']?.toString() ?? 'Emergencia registrada.',
          rawDate: row['created_at']?.toString(),
          color: ClientPastelColors.amberSoft.withValues(alpha: 0.95),
        );
      }
    }
    if (triage is List) {
      for (final row in triage.take(3)) {
        if (row is! Map) continue;
        addTile(
          title: 'Triage ${row['urgency_level'] ?? ''}'.trim(),
          subtitle:
              row['recommendation']?.toString() ??
              'Evaluación de síntomas registrada.',
          rawDate: row['created_at']?.toString(),
          color: ClientPastelColors.skyDeep,
        );
      }
    }

    if (tiles.isEmpty) {
      tiles.add(
        TimelineMedicalTile(
          title: 'Sin historial aún',
          subtitle:
              _recordError ??
              'Las citas, emergencias y triage aparecerán aquí.',
          dateLabel: 'Vetgo',
          dotColor: ClientPastelColors.skyDeep,
          isLast: true,
        ),
      );
    } else {
      final last = tiles.removeLast();
      if (last is TimelineMedicalTile) {
        tiles.add(
          TimelineMedicalTile(
            title: last.title,
            subtitle: last.subtitle,
            dateLabel: last.dateLabel,
            dotColor: last.dotColor,
            isLast: true,
          ),
        );
      } else {
        tiles.add(last);
      }
    }
    return tiles;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expediente'),
        actions: [
          IconButton(
            tooltip: 'Editar mascota',
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ClientSoftCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: AppStrings.petPhotoCambiarTooltip,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: _uploadingPhoto
                              ? null
                              : _pickAndUploadPetPhoto,
                          child: SizedBox(
                            width: 104,
                            height: 104,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: SizedBox(
                                    width: 104,
                                    height: 104,
                                    child:
                                        _photoDisplay != null &&
                                            _photoDisplay!.isNotEmpty
                                        ? Image.network(
                                            _photoDisplay!,
                                            fit: BoxFit.cover,
                                          )
                                        : ColoredBox(
                                            color: ClientPastelColors.skySoft
                                                .withValues(alpha: 0.75),
                                            child: Icon(
                                              Icons.pets_rounded,
                                              size: 48,
                                              color: ClientPastelColors.skyDeep
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                  ),
                                ),
                                if (_uploadingPhoto)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: ColoredBox(
                                      color: Colors.black.withValues(
                                        alpha: 0.42,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.pet.speciesLabel}${widget.pet.breedLabel.isNotEmpty ? ' · ${widget.pet.breedLabel}' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.monitor_weight_outlined,
                                size: 18,
                                color: muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.pet.weightLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.cake_outlined, size: 18, color: muted),
                              const SizedBox(width: 6),
                              Text(
                                widget.pet.ageLabel.isEmpty
                                    ? 'Edad ·'
                                    : widget.pet.ageLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.03, end: 0),
          const SizedBox(height: 22),
          Text(
            'Estado de salud',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [..._healthChips()]),
          const SizedBox(height: 28),
          Text(
            'Historial',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClientSoftCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Column(children: [..._historyTiles()]),
          ).animate().fadeIn(
            delay: 90.ms,
            duration: 380.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
