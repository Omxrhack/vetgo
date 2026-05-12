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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = _session;
    final uid = session?.user?['id']?.toString();
    final roleRaw = session?.profile?['role'];
    final role = roleRaw?.toString().trim();

    if (session == null ||
        !session.hasAccessToken ||
        uid == null ||
        uid.isEmpty ||
        role == null ||
        role.isEmpty ||
        (role != 'vet' && role != 'client')) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AuthStorage.clear();
        if (context.mounted) widget.onLoggedOut?.call();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (role == 'vet') {
      final vetName = session.profile?['full_name']?.toString() ?? '';
      final vetAvatar = session.profile?['avatar_url']?.toString();
      return VetShell(
        profileFirstName: vetName,
        ownerUserId: uid,
        profilePhotoUrl: vetAvatar != null && vetAvatar.isNotEmpty
            ? vetAvatar
            : null,
        onProfilePhotoUpdated: () {
          _loadSession();
        },
        onLoggedOut: () async {
          await AuthStorage.clear();
          widget.onLoggedOut?.call();
        },
      );
    }

    final clientName = session.profile?['full_name']?.toString() ?? '';
    final avatarUrl = session.profile?['avatar_url']?.toString();

    return ClientHomeShell(
      userName: clientName,
      profilePhotoUrl: avatarUrl != null && avatarUrl.isNotEmpty
          ? avatarUrl
          : null,
      ownerUserId: uid,
      onProfilePhotoUpdated: () {
        _loadSession();
      },
      onLogout: () async {
        await AuthStorage.clear();
        widget.onLoggedOut?.call();
      },
    );
  }
}
