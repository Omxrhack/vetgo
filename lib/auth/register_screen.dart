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
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Correo ya registrado'),
            content: Text(
              outcome.message ??
                  'Este correo ya esta verificado. Inicia sesion.',
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
                child: const Text('Ir a iniciar sesion'),
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
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );

    return AuthPageShell(
      variant: AuthScenicVariant.register,
      topBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Volver',
            onPressed: _loading ? null : widget.onLogin,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: AuthStagger(
                children: [
                  const AuthBrandHeader(
                    title: 'Crear cuenta',
                    subtitle:
                        'Te enviaremos un código de 6 dígitos por correo para activar tu cuenta.',
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
                      label: 'Correo electrónico',
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
                      if (!_looksLikeEmail(s)) return 'Correo no válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      context,
                      label: 'Contrasena',
                      hintText: 'Minimo 8 caracteres',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      suffixIcon: IconButton(
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
                      if (v == null || v.length < 8) {
                        return 'La contrasena debe tener al menos 8 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: authInputDecoration(
                      context,
                      label: 'Confirmar contrasena',
                      prefixIcon: Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            _obscure2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey(_obscure2),
                            size: 20,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return 'Las contrasenas no coinciden.';
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
                          : const Text('Continuar', key: ValueKey('label')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : widget.onLogin,
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
                            const TextSpan(text: 'Ya tienes cuenta? '),
                            TextSpan(
                              text: 'Iniciar sesion',
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
