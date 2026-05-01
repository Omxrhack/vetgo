import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/theme/vet_operator_colors.dart';
import 'package:vetgo/widgets/vet/vet_pastel_chip.dart';
import 'package:vetgo/widgets/vet/vet_section_title.dart';
import 'package:vetgo/widgets/vet/vet_soft_card.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Expediente rùpido antes de la visita a domicilio.
class VetPatientRecordScreen extends StatefulWidget {
  const VetPatientRecordScreen({
    super.key,
    required this.petId,
  });

  final String petId;

  @override
  State<VetPatientRecordScreen> createState() => _VetPatientRecordScreenState();
}

class _VetPatientRecordScreenState extends State<VetPatientRecordScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  Map<String, dynamic>? _payload;
  String? _error;
  bool _loading = true;
  bool _uploadingPhoto = false;

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
    final (data, err) = await _api.getVetPetSummary(petId: widget.petId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _payload = data;
      _error = err;
    });
  }

  String _ageLabel(Map<String, dynamic>? pet) {
    final raw = pet?['birth_date'];
    if (raw == null || raw is! String || raw.isEmpty) return 'Edad no registrada';
    final bd = DateTime.tryParse(raw);
    if (bd == null) return 'Edad no registrada';
    final now = DateTime.now();
    var years = now.year - bd.year;
    if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) years--;
    if (years < 1) {
      final months = (now.year - bd.year) * 12 + now.month - bd.month;
      return months <= 0 ? 'Cachorro / menor a 1 mes' : '$months mes(es)';
    }
    return '$years a\u00f1o(s)';
  }

  Future<void> _pickAndUploadPetPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1536, imageQuality: 88);
    if (x == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await x.readAsBytes();
      final name = x.name.trim().isNotEmpty ? x.name.trim() : 'pet.jpg';
      final (petRow, err) = await _api.uploadPetPhotoAsVet(
        petId: widget.petId,
        bytes: bytes,
        filename: name,
      );
      if (!mounted) return;
      if (err != null) {
        VetgoNotice.show(context, message: err, isError: true);
        return;
      }
      if (petRow != null && _payload != null) {
        final merged = Map<String, dynamic>.from(_payload!);
        final prevPet = merged['pet'] is Map<String, dynamic> ? Map<String, dynamic>.from(merged['pet'] as Map) : <String, dynamic>{};
        prevPet.addAll(petRow);
        merged['pet'] = prevPet;
        setState(() => _payload = merged);
      }
      VetgoNotice.show(context, message: AppStrings.petPhotoActualizada);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expediente del paciente'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _loading
            ? Center(
                key: const ValueKey<String>('load'),
                child: CircularProgressIndicator(color: scheme.primary),
              )
            : _error != null
                ? Center(
                    key: const ValueKey<String>('err'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
                      ),
                    ),
                  )
                : _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);
    final pet = _payload?['pet'] is Map<String, dynamic> ? _payload!['pet'] as Map<String, dynamic> : null;
    final owner = _payload?['owner'] is Map<String, dynamic> ? _payload!['owner'] as Map<String, dynamic> : null;
    final cd = _payload?['client_details'] is Map<String, dynamic>
        ? _payload!['client_details'] as Map<String, dynamic>
        : null;

    final name = pet?['name']?.toString() ?? 'Mascota';
    final species = pet?['species']?.toString().trim();
    final speciesLabel = (species == null || species.isEmpty) ? 'Sin especie' : species;
    final breed = pet?['breed']?.toString();
    final photo = pet?['photo_url']?.toString();
    final temperament = pet?['temperament']?.toString();
    final medical = pet?['medical_notes']?.toString();

    final ownerName = owner?['full_name']?.toString();

    final speciesBreed = breed != null && breed.isNotEmpty ? '$speciesLabel ? $breed' : speciesLabel;

    return ListView(
      key: const ValueKey<String>('ok'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        VetSoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: AppStrings.petPhotoCambiarTooltip,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploadingPhoto ? null : _pickAndUploadPetPhoto,
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: VetOperatorColors.mintSoft,
                            backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo == null || photo.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                  )
                                : null,
                          ),
                          if (_uploadingPhoto)
                            Positioned.fill(
                              child: ClipOval(
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
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
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      speciesBreed,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ageLabel(pet),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (ownerName != null && ownerName.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Tutor: $ownerName',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const VetSectionTitle(title: 'Alertas y temperamento'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            VetPastelChip(
              label: temperament != null && temperament.isNotEmpty ? temperament : 'Temperamento no indicado',
              backgroundColor: VetOperatorColors.amberSoft.withValues(alpha: 0.85),
              icon: Icons.pets_rounded,
            ),
            VetPastelChip(
              label: speciesLabel,
              backgroundColor: VetOperatorColors.lilacHint.withValues(alpha: 0.75),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const VetSectionTitle(title: 'Domicilio'),
        VetSoftCard(
          color: VetOperatorColors.peach.withValues(alpha: 0.35),
          child: Text(
            cd?['address_text']?.toString() ?? 'Sin direcciùn registrada',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        const VetSectionTitle(
          title: 'Notas mùdicas / alergias',
          subtitle: 'Revisa antes de tocar el timbre.',
        ),
        VetSoftCard(
          color: VetOperatorColors.mintSoft.withValues(alpha: 0.4),
          child: Text(
            medical != null && medical.isNotEmpty ? medical : 'Sin notas mùdicas registradas.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
