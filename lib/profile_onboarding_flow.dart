import 'package:flutter/material.dart';

import 'auth/widgets/auth_scenic_layer.dart';
import 'auth/widgets/auth_screen_shell.dart';
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
  String? _role;
  bool _loading = false;
  String? _error;

  Future<void> _submit(Map<String, dynamic> body) async {
    final token = await AuthStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Sesión no válida. Vuelve a iniciar sesión.');
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthPageShell(
      variant: AuthScenicVariant.register,
      topBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: _role == null
                  ? const SizedBox.shrink(key: ValueKey('no_back'))
                  : IconButton(
                      key: const ValueKey('back'),
                      tooltip: 'Cambiar rol',
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _role = null;
                                _error = null;
                              }),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: scheme.onSurface,
                      ),
                    ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'PASO FINAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
      child: Column(
        children: [
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
                    ?currentChild,
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
                  : KeyedSubtree(
                      key: ValueKey('role_$_role'),
                      child: _OnboardingFormPanel(
                        error: _error,
                        onDismissError: () => setState(() => _error = null),
                        form: _role == 'client'
                            ? ClientOnboardingForm(
                                loading: _loading,
                                onSubmit: _submit,
                              )
                            : VetOnboardingForm(
                                loading: _loading,
                                onSubmit: _submit,
                              ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFormPanel extends StatelessWidget {
  const _OnboardingFormPanel({
    required this.error,
    required this.onDismissError,
    required this.form,
  });

  final String? error;
  final VoidCallback onDismissError;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: error == null
                ? const SizedBox.shrink(key: ValueKey('no_error'))
                : Padding(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AuthErrorBanner(
                      message: error!,
                      onDismiss: onDismissError,
                    ),
                  ),
          ),
          Expanded(child: form),
        ],
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.onPick});

  final void Function(String role) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SingleChildScrollView(
        child: AuthStagger(
          delayStep: const Duration(milliseconds: 70),
          children: [
            const AuthBrandHeader(
              title: 'Completa tu perfil',
              subtitle: 'Cuéntanos cómo vas a usar Vetgo para personalizar tu experiencia.',
            ),
            const SizedBox(height: 28),
            _RoleCard(
              title: 'Soy dueño de mascota',
              subtitle: 'Busco veterinarios y servicios para mis mascotas.',
              icon: Icons.pets_rounded,
              onTap: () => onPick('client'),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              title: 'Soy veterinario',
              subtitle: 'Ofrezco consultas y servicios a domicilio o en línea.',
              icon: Icons.medical_services_outlined,
              onTap: () => onPick('vet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
