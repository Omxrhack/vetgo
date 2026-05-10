import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/widgets/profile_photo_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.onLogout,
    this.onProfilePhotoUpdated,
  });

  final String userName;
  final String? profilePhotoUrl;
  final VoidCallback onLogout;
  final VoidCallback? onProfilePhotoUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final displayName = userName.trim().isEmpty ? 'Usuario' : userName.trim();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePhotoAvatar(
                heroTag: 'client_avatar_profile',
                imageUrl: profilePhotoUrl,
                placeholderBackground: scheme.primaryContainer,
                placeholderIconColor: scheme.primary,
                radius: 48,
                onUploaded: onProfilePhotoUpdated,
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .scaleXY(begin: 0.92, end: 1, duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 300.ms)
                  .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: scheme.error),
                title: Text(
                  'Cerrar sesión',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: onLogout,
              )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 300.ms)
                  .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}
