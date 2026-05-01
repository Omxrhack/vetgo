import 'package:flutter/material.dart';

import '../core/network/auth_outcomes.dart' show RegisterKind;
import '../core/network/vetgo_api_client.dart';
import 'widgets/auth_scenic_layer.dart';
import 'widgets/auth_screen_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onGoToOtp,
    required this.onLogin,
  });

  final void Function(String email, {required bool alreadyUnverified})
  onGoToOtp;
  final VoidCallback onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _api = VetgoApiClient();
  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _globalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _globalError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final outcome = await _api.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    switch (outcome.kind) {
      case RegisterKind.goToOtp:
        widget.onGoToOtp(
          outcome.email,
          alreadyUnverified: outcome.alreadyUnverified,
        );
      case RegisterKind.emailAlreadyVerified:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Correo ya registrado'),
            content: Text(
              outcome.message ??
                  'Este correo ya está verificado. Inicia sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onLogin();
                },
                child: const Text('Ir a iniciar sesión'),
              ),
            ],
          ),
        );
      case RegisterKind.failure:
        setState(() {
          _globalError = outcome.message ?? 'No se pudo registrar.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final primaryBtnStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    );

    return AuthPageShell(
      variant: AuthScenicVariant.register,
      topBar: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
        child: Row(
          children: [
            Material(
              color: scheme.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: 'Volver',
                onPressed: _loading ? null : widget.onLogin,
                icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
              ),
            ),
            Expanded(
              child: Text(
                'Crear cuenta',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeroHeader(
                  title: 'Únete a Vetgo',
                  subtitle:
                      'Te enviaremos un código de 8 dígitos por correo para activar tu cuenta.',
                  icon: Icons.celebration_rounded,
                ),
                const SizedBox(height: 24),
                AuthFormCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_globalError != null) ...[
                          AuthErrorBanner(
                            message: _globalError!,
                            onDismiss: () =>
                                setState(() => _globalError = null),
                          ),
                          const SizedBox(height: 18),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: authInputDecoration(
                            context,
                            label: 'Correo electrónico',
                            hintText: 'nombre@ejemplo.com',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: scheme.primary.withValues(alpha: 0.85),
                            ),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.isEmpty) return 'Ingresa tu correo.';
                            if (!_looksLikeEmail(s)) return 'Correo no válido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          decoration: authInputDecoration(
                            context,
                            label: 'Contraseña',
                            hintText: 'Mínimo 8 caracteres',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: scheme.primary.withValues(alpha: 0.85),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) {
                              return 'La contraseña debe tener al menos 8 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure2,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: authInputDecoration(
                            context,
                            label: 'Confirmar contraseña',
                            prefixIcon: Icon(
                              Icons.verified_user_outlined,
                              color: scheme.primary.withValues(alpha: 0.85),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure2 = !_obscure2),
                              icon: Icon(
                                _obscure2
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: scheme.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),
                        FilledButton(
                          style: primaryBtnStyle,
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Continuar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _loading ? null : widget.onLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.78),
                      ),
                      children: [
                        const TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Iniciar sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _looksLikeEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }
}
