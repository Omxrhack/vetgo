import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../core/auth/auth_storage.dart';
import '../core/network/vetgo_api_client.dart';

/// Código de verificación (6–10 dígitos según backend). UI con 6 casillas (caso más habitual).
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onBack,
    this.hint,
  });

  final String email;
  final String? hint;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _api = VetgoApiClient();
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String token) async {
    if (token.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final outcome = await _api.verifyOtp(
      email: widget.email,
      token: token,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (outcome.ok && outcome.session != null) {
      final s = outcome.session!;
      if (s.hasAccessToken) {
        await AuthStorage.saveSession(s);
        if (!mounted) return;
        widget.onVerified();
        return;
      }
      setState(() {
        _error =
            'Cuenta verificada pero sin sesión automática. Inicia sesión con tu contraseña.';
      });
      return;
    }

    setState(() {
      _error = outcome.message ?? 'Código incorrecto.';
      _pinController.clear();
      _focusNode.requestFocus();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    final err = await _api.resendOtp(widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si hay cuota disponible, revisa tu correo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 46,
      height: 52,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(12),
        color: scheme.surface,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _loading ? null : widget.onBack,
        ),
        title: const Text('Verificar correo'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ingresa el código enviado a',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.email,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.hint != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Suele ser un código de 6 dígitos. Si el tuyo es más largo, '
                    'escríbelo en el teclado hasta completarlo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, color: scheme.error),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Pinput(
                    length: 6,
                    controller: _pinController,
                    focusNode: _focusNode,
                    autofocus: true,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        color: scheme.surfaceContainerHighest,
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyBorderWith(
                      border: Border.all(color: scheme.error),
                    ),
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    forceErrorState: _error != null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    keyboardType: TextInputType.number,
                    onCompleted: _loading ? null : _submit,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  TextButton(
                    onPressed: (_loading || _resending) ? null : _resend,
                    child: _resending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reenviar código'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : widget.onBack,
                    child: const Text('Volver al inicio de sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
