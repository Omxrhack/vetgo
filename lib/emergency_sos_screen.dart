import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vetgo/models/client_demo_data.dart';
import 'package:vetgo/models/client_pet_vm.dart';
import 'package:vetgo/theme/client_pastel.dart';
import 'package:vetgo/widgets/client/async_endpoint_button.dart';
import 'package:vetgo/widgets/client/client_soft_card.dart';

/// SOS Emergencia 24/7: acciÛn r·pida con gradiente suave.
class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  bool _searching = false;

  static const List<ClientPetVm> _pets = ClientDemoData.pets;

  ClientPetVm _selectedPet = ClientDemoData.pets.first;
  final TextEditingController _symptoms = TextEditingController();

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ClientPastelColors.skySoft.withValues(alpha: 0.55),
              ClientPastelColors.peachSoft.withValues(alpha: 0.85),
              ClientPastelColors.amberSoft.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Emergencia',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Respuesta prioritaria 24/7',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: ClientPastelColors.mutedOn(context)),
                ),
                const SizedBox(height: 36),
                Center(
                  child: AnimatedScale(
                    scale: _searching ? 0.94 : 1,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _searching ? null : _onSosPressed,
                        child: Ink(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                ClientPastelColors.coralSoft.withValues(alpha: 0.92),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.error.withValues(alpha: 0.22),
                                blurRadius: 28,
                                spreadRadius: 2,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _searching
                                ? Column(
                                    key: const ValueKey<String>('load'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: theme.colorScheme.error.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'Buscando veterinarios cercanosù',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey<String>('idle'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.sos_rounded, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.88)),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Solicitar ayuda\nurgente',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 40),
                Text(
                  'Detalle rùpido (opcional)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClientSoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<ClientPetVm>(
                        value: _selectedPet,
                        decoration: const InputDecoration(
                          labelText: 'Mascota',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
                        ),
                        items: _pets
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                            )
                            .toList(),
                        onChanged: _searching
                            ? null
                            : (v) {
                                if (v != null) setState(() => _selectedPet = v);
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _symptoms,
                        enabled: !_searching,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Sùntomas',
                          alignLabelWithHint: true,
                          hintText: 'Describe lo que observasù',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AsyncEndpointButton(
                        label: 'Enviar datos al equipo SOS',
                        icon: Icons.send_rounded,
                        loadingLabel: 'Enviandoù',
                        style: FilledButton.styleFrom(
                          backgroundColor: ClientPastelColors.mintDeep,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Future<void>.delayed(const Duration(milliseconds: 1200));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSosPressed() async {
    setState(() => _searching = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _searching = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud registrada para ${_selectedPet.name}. Te contactamos en segundos.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }
}
