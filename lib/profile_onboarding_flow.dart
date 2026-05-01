import 'package:flutter/material.dart';

import 'client_onboarding_form.dart';
import 'core/auth/auth_storage.dart';
import 'core/network/vetgo_api_client.dart';
import 'vet_onboarding_form.dart';

/// Onboarding de perfil (cliente o veterinario) tras verificar correo.
class ProfileOnboardingFlow extends StatefulWidget {
  const ProfileOnboardingFlow({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<ProfileOnboardingFlow> createState() => _ProfileOnboardingFlowState();
}

class _ProfileOnboardingFlowState extends State<ProfileOnboardingFlow> {
  final _clientKey = GlobalKey<ClientOnboardingFormState>();
  final _vetKey = GlobalKey<VetOnboardingFormState>();

  String? _role;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final token = await AuthStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Sesion no valida. Vuelve a iniciar sesion.');
      return;
    }

    Map<String, dynamic>? body;
    if (_role == 'client') {
      body = _clientKey.currentState?.buildPayloadIfValid();
    } else if (_role == 'vet') {
      body = _vetKey.currentState?.buildPayloadIfValid();
    }

    if (body == null) {
      setState(() => _error = 'Revisa los campos marcados.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final api = VetgoApiClient();
    final res = await api.completeProfileOnboarding(
      accessToken: token,
      body: body,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res == null) {
      setState(() => _error = 'No se pudo guardar. Revisa la red o los datos.');
      return;
    }

    final prev = await AuthStorage.loadSession();
    if (prev != null) {
      await AuthStorage.saveSession(
        prev.merge(
          user: res.user ?? prev.user,
          profile: res.profile ?? prev.profile,
        ),
      );
    }

    if (!mounted) return;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) =>
                  SizeTransition(sizeFactor: a, child: FadeTransition(opacity: a, child: c)),
              child: _error == null
                  ? const SizedBox.shrink(key: ValueKey('err_none'))
                  : Material(
                      key: const ValueKey('err_msg'),
                      color: scheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final isPicker = child.key == const ValueKey('role_picker');
                  final beginX = isPicker ? -0.15 : 0.15;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(beginX, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: _role == null
                    ? KeyedSubtree(
                        key: const ValueKey('role_picker'),
                        child: _RolePicker(
                          onPick: (r) => setState(() {
                            _role = r;
                            _error = null;
                          }),
                        ),
                      )
                    : _role == 'client'
                        ? KeyedSubtree(
                            key: const ValueKey('role_client'),
                            child: ClientOnboardingForm(key: _clientKey),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('role_vet'),
                            child: VetOnboardingForm(key: _vetKey),
                          ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _role == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Cambiar rol',
                            onPressed: _loading
                                ? null
                                : () => setState(() => _role = null),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Guardar y continuar'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.onPick});

  final void Function(String role) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Como quieres usar Vetgo?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _RoleCard(
          title: 'Soy dueno de mascota',
          subtitle: 'Busco veterinarios y servicios para mis mascotas.',
          icon: Icons.pets,
          onTap: () => onPick('client'),
          scheme: scheme,
        ),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Soy veterinario',
          subtitle: 'Ofrezco consultas y servicios a domicilio o en linea.',
          icon: Icons.medical_services_outlined,
          onTap: () => onPick('vet'),
          scheme: scheme,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.scheme,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
