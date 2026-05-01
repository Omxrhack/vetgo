import 'package:flutter/material.dart';

import '../core/auth/auth_storage.dart';
import '../core/network/auth_outcomes.dart' show LoginKind;
import '../core/network/vetgo_api_client.dart';
import 'widgets/auth_scenic_layer.dart';
import 'widgets/auth_screen_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSuccess,
    required this.onRegister,
    required this.onNeedOtp,
  });

  final VoidCallback onSuccess;
  final VoidCallback onRegister;
  final void Function(String email) onNeedOtp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _api = VetgoApiClient();
  bool _obscure = true;
  bool _loading = false;
  String? _globalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _globalError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final outcome = await _api.login(
      email: email,
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    switch (outcome.kind) {
      case LoginKind.success:
        if (outcome.session != null && outcome.session!.hasAccessToken) {
          await AuthStorage.saveSession(outcome.session!);
          if (!mounted) return;
          widget.onSuccess();
        } else {
          setState(() {
            _globalError =
                'No se recibió un token. Intenta de nuevo o contacta soporte.';
          });
        }
      case LoginKind.needsVerification:
        final e = outcome.emailForVerification ?? email;
        if (e.isEmpty) {
          setState(() {
            _globalError = outcome.message ?? 'Debes verificar tu correo.';
          });
        } else {
          widget.onNeedOtp(e);
        }
      case LoginKind.failure:
        setState(() {
          _globalError = outcome.message ?? 'No se pudo iniciar sesión.';
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
      variant: AuthScenicVariant.login,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const AuthHeroHeader(
                  title: 'Hola de nuevo',
                  subtitle:
                      'Inicia sesión para seguir cuidando a tus mascotas con Vetgo.',
                  icon: Icons.pets_rounded,
                ),
                const SizedBox(height: 28),
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
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: authInputDecoration(
                            context,
                            label: 'Contraseña',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: scheme.primary.withValues(alpha: 0.85),
                            ),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Mostrar' : 'Ocultar',
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
                            if (v == null || v.isEmpty)
                              return 'Ingresa tu contraseña.';
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
                                  'Iniciar sesión',
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
                const SizedBox(height: 22),
                TextButton(
                  onPressed: _loading ? null : widget.onRegister,
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
                        const TextSpan(text: '¿Primera vez aquí? '),
                        TextSpan(
                          text: 'Crear cuenta',
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
