import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Onboarding: gallery pick + [VetgoApiClient.uploadProfilePhoto].
class OnboardingProfilePhotoField extends StatefulWidget {
  const OnboardingProfilePhotoField({
    super.key,
    required this.imageUrl,
    required this.onUrlChanged,
    this.allowClear = false,
    this.busy = false,
  });

  final String? imageUrl;
  final ValueChanged<String?> onUrlChanged;
  final bool allowClear;
  final bool busy;

  @override
  State<OnboardingProfilePhotoField> createState() => _OnboardingProfilePhotoFieldState();
}

class _OnboardingProfilePhotoFieldState extends State<OnboardingProfilePhotoField> {
  final VetgoApiClient _api = VetgoApiClient();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (widget.busy || _uploading) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1536,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await x.readAsBytes();
      final name = x.name.trim().isNotEmpty ? x.name.trim() : 'profile.jpg';
      final (profile, err) = await _api.uploadProfilePhoto(bytes: bytes, filename: name);
      if (!mounted) return;
      if (err != null) {
        VetgoNotice.show(context, message: err, isError: true);
        return;
      }
      if (profile != null) {
        final session = await AuthStorage.loadSession();
        if (session != null) {
          await AuthStorage.saveSession(session.merge(profile: profile));
        }
        final snap = await AuthStorage.loadSession();
        final url = snap?.profile?['avatar_url']?.toString().trim();
        widget.onUrlChanged(url != null && url.isNotEmpty ? url : null);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _clear() {
    if (widget.busy || _uploading) return;
    widget.onUrlChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.58);
    final disabled = widget.busy || _uploading;
    final hasPhoto = widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;

    final radius = BorderRadius.circular(14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : _pickAndUpload,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: scheme.primary.withValues(alpha: 0.08),
                            backgroundImage: hasPhoto ? NetworkImage(widget.imageUrl!.trim()) : null,
                            child: !hasPhoto
                                ? Icon(Icons.add_photo_alternate_rounded, color: scheme.primary, size: 32)
                                : null,
                          ),
                          if (_uploading)
                            Positioned.fill(
                              child: ClipOval(
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.onboardingFotoPerfilTitulo,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.allowClear
                                ? AppStrings.onboardingFotoPerfilSubtituloOpcional
                                : AppStrings.onboardingFotoPerfilSubtitulo,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.allowClear && hasPhoto && !disabled) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _clear,
              child: Text(AppStrings.onboardingFotoPerfilQuitar),
            ),
          ),
        ],
      ],
    );
  }
}
