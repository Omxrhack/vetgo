import 'package:flutter/material.dart';

import 'package:vetgo/client_dashboard_screen.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/emergency_sos_screen.dart';
import 'package:vetgo/models/client_demo_data.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/store_screen.dart';
import 'package:vetgo/theme/client_pastel.dart';

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

  /// `auth.users.id` del dueùo (JWT); necesario para `GET /api/pets/:ownerId`.
  final String? ownerUserId;

  /// Tras subir foto de perfil (Storage) recarga sesiùn en [HomeScreen].
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
        _petsError = 'No se pudo obtener tu cuenta. Vuelve a iniciar sesiùn.';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            onOpenEmergency: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => EmergencySOSScreen(pets: _pets),
                ),
              );
            },
            onProfilePhotoUpdated: widget.onProfilePhotoUpdated,
          ),
          const StoreScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => EmergencySOSScreen(pets: _pets),
            ),
          );
        },
        backgroundColor: ClientPastelColors.coralSoft.withValues(alpha: 0.95),
        foregroundColor: scheme.error.withValues(alpha: 0.88),
        elevation: 4,
        child: const Icon(Icons.sos_rounded, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        height: 64,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Tienda',
          ),
        ],
      ),
    );
  }
}
