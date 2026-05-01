import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/core/l10n/app_strings.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/widgets/vetgo_notice.dart';

/// Avatar de perfil: al pulsar abre la galería, sube al bucket (`POST /api/auth/upload-photo`) y refresca la sesión local.
class ProfilePhotoAvatar extends StatefulWidget {
  const ProfilePhotoAvatar({
    super.key,
    required this.imageUrl,
    required this.placeholderBackground,
    required this.placeholderIconColor,
    this.radius = 28,
    this.heroTag,
    this.onUploaded,
    this.icon = Icons.person_rounded,
  });

  final String? imageUrl;
  final Color placeholderBackground;
  final Color placeholderIconColor;
  final double radius;
  final Object? heroTag;
  final VoidCallback? onUploaded;
  final IconData icon;

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  final VetgoApiClient _api = VetgoApiClient();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
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
        widget.onUploaded?.call();
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.radius > 24 ? 30.0 : 26.0;

    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.placeholderBackground,
      backgroundImage: widget.imageUrl != null && widget.imageUrl!.isNotEmpty ? NetworkImage(widget.imageUrl!) : null,
      child: widget.imageUrl == null || widget.imageUrl!.isEmpty
          ? Icon(widget.icon, color: widget.placeholderIconColor, size: iconSize)
          : null,
    );

    if (widget.heroTag != null) {
      avatar = Hero(tag: widget.heroTag!, child: avatar);
    }

    final size = widget.radius * 2;

    return Tooltip(
      message: AppStrings.profilePhotoCambiarTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _uploading ? null : _pickAndUpload,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                avatar,
                if (_uploading)
                  Positioned.fill(
                    child: ClipOval(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
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
    );
  }
}
