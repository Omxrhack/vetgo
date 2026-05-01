import 'package:flutter/material.dart';

import 'package:vetgo/client_home_shell.dart';
import 'package:vetgo/core/auth/auth_session.dart';
import 'package:vetgo/core/auth/auth_storage.dart';
import 'package:vetgo/vet_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onLoggedOut});

  /// Tras cerrar sesión vuelve al flujo de login ([AuthFlow]).
  final VoidCallback? onLoggedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthSession? _session;
  bool _sessionReady = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final s = await AuthStorage.loadSession();
    if (!mounted) return;
    setState(() {
      _session = s;
      _sessionReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _session?.profile?['role']?.toString();
    if (role == 'vet') {
      final vetName = _session?.profile?['full_name']?.toString() ?? '';
      return VetShell(
        profileFirstName: vetName,
        onLoggedOut: () async {
          await AuthStorage.clear();
          widget.onLoggedOut?.call();
        },
      );
    }

    final clientName = _session?.profile?['full_name']?.toString() ?? '';
    final avatarUrl = _session?.profile?['avatar_url']?.toString();

    return ClientHomeShell(
      userName: clientName,
      profilePhotoUrl: avatarUrl != null && avatarUrl.isNotEmpty ? avatarUrl : null,
      onLogout: () async {
        await AuthStorage.clear();
        widget.onLoggedOut?.call();
      },
    );
  }
}
