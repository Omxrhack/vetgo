import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import 'package:vetgo/client_dashboard_screen.dart';
import 'package:vetgo/core/network/vetgo_api_client.dart';
import 'package:vetgo/emergency_sos_screen.dart';
import 'package:vetgo/models/client_demo_data.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/profile_screen.dart';
import 'package:vetgo/social_screen.dart';
import 'package:vetgo/store_screen.dart';

/// Contenedor cliente: inicio + social + SOS + tienda + perfil.
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
  final String? ownerUserId;
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

  void _setTab(int index) {
    if (_tab != index) setState(() => _tab = index);
  }

  // bar positions: 0=Inicio, 1=Social, 2=SOS(no tab), 3=Tienda, 4=Perfil
  static const _barPosToTab = <int>[0, 1, -1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final screens = <Widget>[
      ClientDashboardScreen(
        userName: widget.userName,
        pets: _pets,
        petsLoading: _petsLoading,
        petsError: _petsError,
        onRefreshPets: _loadPets,
        onOpenEmergency: _openSos,
      ),
      const SocialScreen(),
      const StoreScreen(),
      ProfileScreen(
        userName: widget.userName,
        profilePhotoUrl: widget.profilePhotoUrl,
        onLogout: widget.onLogout,
        onProfilePhotoUpdated: widget.onProfilePhotoUpdated,
      ),
    ];

    Widget buildBarItem({
      required int barPos,
      required IconData iconOutlined,
      required IconData iconFilled,
      required String label,
    }) {
      final tabIdx = _barPosToTab[barPos];
      final selected = _tab == tabIdx;
      final color = selected ? scheme.primary : muted;

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _setTab(tabIdx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      selected ? iconFilled : iconOutlined,
                      size: 24,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                      letterSpacing: 0.1,
                    ),
                    child: Text(label),
                  ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: selected ? 14 : 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final barWidget = SizedBox(
      height: 68,
      child: Row(
        children: [
          buildBarItem(
            barPos: 0,
            iconOutlined: Icons.home_outlined,
            iconFilled: Icons.home_rounded,
            label: 'Inicio',
          ),
          buildBarItem(
            barPos: 1,
            iconOutlined: Icons.people_outline_rounded,
            iconFilled: Icons.people_rounded,
            label: 'Social',
          ),
          // SOS center button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: _openSos,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.error.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sos_rounded,
                  size: 26,
                  color: scheme.onErrorContainer,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1,
                    end: 1.05,
                    duration: 1800.ms,
                    curve: Curves.easeInOutSine,
                  ),
            ),
          ),
          buildBarItem(
            barPos: 3,
            iconOutlined: Icons.storefront_outlined,
            iconFilled: Icons.storefront_rounded,
            label: 'Tienda',
          ),
          buildBarItem(
            barPos: 4,
            iconOutlined: Icons.person_outline_rounded,
            iconFilled: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_tab),
        child: screens[_tab],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BottomBar(
        body: content,
        showIcon: false,
        layout: BottomBarLayout(
          width: screenWidth - 32,
          offset: 12,
          borderRadius: BorderRadius.circular(32),
          fit: StackFit.expand,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        child: barWidget,
      ),
    );
  }
}
