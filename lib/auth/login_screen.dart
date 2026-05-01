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
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );

    return AuthPageShell(
      variant: AuthScenicVariant.login,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: AuthStagger(
                children: [
                  const AuthBrandHeader(
                    title: 'Bienvenido de nuevo',
                    subtitle: 'Inicia sesion para seguir cuidando a tus mascotas.',
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _globalError == null
                        ? const SizedBox.shrink(key: ValueKey('no_error'))
                        : Padding(
                            key: const ValueKey('error'),
                            padding: const EdgeInsets.only(bottom: 18),
                            child: AuthErrorBanner(
                              message: _globalError!,
                              onDismiss: () =>
                                  setState(() => _globalError = null),
                            ),
                          ),
                  ),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      context,
                      label: 'Correo electronico',
                      hintText: 'nombre@ejemplo.com',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Ingresa tu correo.';
                      if (!_looksLikeEmail(s)) return 'Correo no valido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: authInputDecoration(
                      context,
                      label: 'Contrasena',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey(_obscure),
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa tu contrasena.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    style: primaryBtnStyle,
                    onPressed: _loading ? null : _submit,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _loading
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Iniciar sesion',
                              key: ValueKey('label'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : widget.onRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                          children: [
                            const TextSpan(text: 'Primera vez aqui? '),
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
                  ),
                ],
              ),
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
