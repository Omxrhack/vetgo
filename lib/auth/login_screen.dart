import 'package:flutter/material.dart';

import '../core/auth/auth_storage.dart';
import '../core/network/auth_outcomes.dart' show LoginKind;
import '../core/network/vetgo_api_client.dart';

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
            _globalError = 'No se recibió un token. Intenta de nuevo o contacta soporte.';
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bienvenido de nuevo',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa con el correo con el que te registraste.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (_globalError != null) ...[
                      _InlineErrorCard(
                        message: _globalError!,
                        onDismiss: () => setState(() => _globalError = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _loading ? null : widget.onRegister,
                      child: const Text('¿No tienes cuenta? Crear cuenta'),
                    ),
                  ],
                ),
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

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
