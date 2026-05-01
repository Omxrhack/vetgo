import 'package:flutter/material.dart';

import 'client_dashboard_screen.dart';
import 'emergency_sos_screen.dart';
import 'models/client_demo_data.dart';
import 'store_screen.dart';
import 'theme/client_pastel.dart';

/// Contenedor cliente: inicio + tienda + acceso SOS (alineado con VetgoTheme).
class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({
    super.key,
    required this.userName,
    this.profilePhotoUrl,
    required this.onLogout,
  });

  final String userName;
  final String? profilePhotoUrl;
  final VoidCallback onLogout;

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _tab = 0;

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
            pets: ClientDemoData.pets,
            onLogout: widget.onLogout,
          ),
          const StoreScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const EmergencySOSScreen()),
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
