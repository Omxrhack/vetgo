import 'package:flutter/material.dart';
import 'package:vetgo/public_profile_screen.dart';

/// Wrapper que abre el perfil público de un veterinario.
/// Reutiliza PublicProfileScreen con el botón "Agendar cita".
class VetProfileScreen extends StatelessWidget {
  const VetProfileScreen({
    super.key,
    required this.vetId,
    this.onBookTap,
  });

  final String vetId;
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    return PublicProfileScreen(
      profileId: vetId,
      onBookTap: onBookTap,
    );
  }
}
