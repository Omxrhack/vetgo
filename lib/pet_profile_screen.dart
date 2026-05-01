import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

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
  const PetProfileScreen({super.key, required this.pet});

  final ClientPetVm pet;

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final VetgoApiClient _api = VetgoApiClient();
  String? _photoUrlOverride;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _photoUrlOverride = widget.pet.photoUrl;
  }

  String? get _photoDisplay =>
      (_photoUrlOverride != null && _photoUrlOverride!.isNotEmpty) ? _photoUrlOverride : widget.pet.photoUrl;

  Future<void> _pickAndUploadPetPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1536, imageQuality: 88);
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
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = ClientPastelColors.mutedOn(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Expediente'),
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
                      onTap: _uploadingPhoto ? null : _pickAndUploadPetPhoto,
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
                                child: _photoDisplay != null && _photoDisplay!.isNotEmpty
                                    ? Image.network(_photoDisplay!, fit: BoxFit.cover)
                                    : ColoredBox(
                                        color: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                                        child: Icon(Icons.pets_rounded, size: 48, color: ClientPastelColors.skyDeep.withValues(alpha: 0.55)),
                                      ),
                              ),
                            ),
                            if (_uploadingPhoto)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.42),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
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
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.pet.speciesLabel}${widget.pet.breedLabel.isNotEmpty ? ' · ${widget.pet.breedLabel}' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, size: 18, color: muted),
                          const SizedBox(width: 6),
                          Text(widget.pet.weightLabel, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 16),
                          Icon(Icons.cake_outlined, size: 18, color: muted),
                          const SizedBox(width: 6),
                          Text(
                            widget.pet.ageLabel.isEmpty ? 'Edad ·' : widget.pet.ageLabel,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOutCubic).slideY(begin: 0.03, end: 0),
          const SizedBox(height: 22),
          Text('Estado de salud', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PastelStatusChip(
                label: 'Vacunas al día',
                icon: Icons.verified_rounded,
                backgroundColor: ClientPastelColors.mintSoft.withValues(alpha: 0.72),
                foregroundColor: ClientPastelColors.mintDeep,
              ),
              PastelStatusChip(
                label: 'Desparasitación OK',
                icon: Icons.healing_rounded,
                backgroundColor: ClientPastelColors.skySoft.withValues(alpha: 0.75),
                foregroundColor: ClientPastelColors.skyDeep,
              ),
              PastelStatusChip(
                label: 'Control dental pendiente',
                icon: Icons.info_outline_rounded,
                backgroundColor: ClientPastelColors.amberSoft.withValues(alpha: 0.68),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Historial', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ClientSoftCard(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Column(
              children: [
                TimelineMedicalTile(
                  title: 'Consulta general',
                  subtitle: 'Chequeo anual, presión y escucha cardíaca normal.',
                  dateLabel: '12 marzo 2026',
                  dotColor: ClientPastelColors.mintDeep,
                  isLast: false,
                ),
                TimelineMedicalTile(
                  title: 'Vacuna polivalente',
                  subtitle: 'Refuerzo aplicado sin reacciones adversas.',
                  dateLabel: '02 febrero 2026',
                  dotColor: ClientPastelColors.skyDeep,
                  isLast: false,
                ),
                TimelineMedicalTile(
                  title: 'Desparasitación interna',
                  subtitle: 'Tableta oral; próxima dosis en 90 días.',
                  dateLabel: '18 enero 2026',
                  dotColor: ClientPastelColors.amberSoft.withValues(alpha: 0.95),
                  isLast: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 90.ms, duration: 380.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
