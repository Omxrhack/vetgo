import 'package:flutter/material.dart';

import 'package:vetgo/client_dashboard_screen.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/emergency_sos_screen.dart';
import 'package:vetgo/models/client_demo_data.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/store_screen.dart';

/// Contenedor cliente: inicio + tienda + acceso SOS (alineado con VetgoTheme).
class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.onLogout,
    this.ownerUserId,
    this.onProfilePhotoUpdated,
  });

  final String userName;
  final String? profilePhotoUrl;
  final VoidCallback onLogout;

  /// `auth.users.id` del dueño (JWT); necesario para `GET /api/pets/:ownerId`.
  final String? ownerUserId;

  /// Tras subir foto de perfil (Storage) recarga sesión en [HomeScreen].
  final VoidCallback? onProfilePhotoUpdated;

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  final VetgoApiClient _api = VetgoApiClient();
  int _tab = 0;

  List<ClientPetVm> _pets = [];
  bool _petsLoading = true;
  String? _petsError;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final id = widget.ownerUserId?.trim();
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _petsLoading = false;
        _petsError = 'No se pudo obtener tu cuenta. Vuelve a iniciar sesión.';
        _pets = [];
      });
      return;
    }

    setState(() {
      _petsLoading = true;
      _petsError = null;
    });

    final (list, err) = await _api.listPetsByOwner(ownerId: id);
    if (!mounted) return;

    if (err != null) {
      setState(() {
        _petsLoading = false;
        _petsError = err;
        _pets = List<ClientPetVm>.from(ClientDemoData.pets);
      });
      return;
    }

    final mapped = list!.map(ClientPetVm.fromApiJson).toList();
    setState(() {
      _petsLoading = false;
      _petsError = null;
      _pets = mapped;
    });
  }

  void _openSos() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EmergencySOSScreen(pets: _pets),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;

    Widget tabEntry({
      required int index,
      required IconData iconOutlined,
      required IconData iconFilled,
      required String label,
    }) {
      final selected = _tab == index;
      final color = selected ? scheme.primary : muted;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _tab = index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? iconFilled : iconOutlined,
                  size: 26,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _tab,
        children: [
          ClientDashboardScreen(
            userName: widget.userName,
            profilePhotoUrl: widget.profilePhotoUrl,
            pets: _pets,
            petsLoading: _petsLoading,
            petsError: _petsError,
            onRefreshPets: _loadPets,
            onLogout: widget.onLogout,
            onOpenEmergency: _openSos,
            onProfilePhotoUpdated: widget.onProfilePhotoUpdated,
          ),
          const StoreScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openSos,
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        elevation: 6,
        highlightElevation: 10,
        child: const Icon(Icons.sos_rounded, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: 64,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 9,
        child: Row(
          children: [
            tabEntry(
              index: 0,
              iconOutlined: Icons.home_outlined,
              iconFilled: Icons.home_rounded,
              label: 'Inicio',
            ),
            const SizedBox(width: 104),
            tabEntry(
              index: 1,
              iconOutlined: Icons.storefront_outlined,
              iconFilled: Icons.storefront_rounded,
              label: 'Tienda',
            ),
          ],
        ),
      ),
    );
  }
}
