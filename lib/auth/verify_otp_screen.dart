import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../core/auth/auth_storage.dart';
import '../core/network/vetgo_api_client.dart';
import 'widgets/auth_scenic_layer.dart';
import 'widgets/auth_screen_shell.dart';
import '../widgets/vetgo_notice.dart';

/// Pantalla de código tras registro o login sin verificar.
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.onVerified,
    this.onNavigateToLogin,
    this.hint,
  });

  final String email;
  final String? hint;
  final VoidCallback onVerified;

  /// Si la cuenta queda verificada pero sin tokens (p. ej. sin contraseña en OTP), volver a login.
  final VoidCallback? onNavigateToLogin;

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
  String? _resendInfo;

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
      _resendInfo = null;
    });
    final outcome = await _api.verifyOtp(email: widget.email, token: token);
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
      if (!mounted) return;
      VetgoNotice.show(
        context,
        message:
            'Correo verificado. Entra con tu contraseña para continuar.',
      );
      widget.onNavigateToLogin?.call();
      setState(() {
        _pinController.clear();
        _focusNode.requestFocus();
      });
      return;
    }

    setState(() {
      _error = outcome.message ?? 'Código incorrecto.';
      _resendInfo = null;
      _pinController.clear();
      _focusNode.requestFocus();
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _resendInfo = null;
    });
    final result = await _api.resendOtp(widget.email);
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (result.alreadyVerified) {
        _error = null;
        _resendInfo = null;
      } else if (result.error != null) {
        _error = result.error;
      } else {
        _resendInfo = 'Si hay cuota disponible, revisa tu correo.';
      }
    });
    if (!mounted) return;
    if (result.alreadyVerified) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Correo ya verificado'),
          content: const Text(
            'Este correo ya está confirmado. Inicia sesión con tu contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Seguir aquí'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onNavigateToLogin?.call();
              },
              child: const Text('Ir a iniciar sesión'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final defaultPinTheme = PinTheme(
      width: 38,
      height: 48,
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
        color: scheme.surface,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: scheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: scheme.primary.withValues(alpha: 0.06),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: scheme.error, width: 2),
      ),
    );

    return PopScope(
      canPop: false,
      child: AuthPageShell(
        variant: AuthScenicVariant.otp,
        topBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Text(
            'PASO 2 DE 2',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuthStagger(
                children: [
                  AuthBrandHeader(
                    title: 'Verifica tu correo',
                    subtitle: widget.hint ??
                        'Ingresa el código de 6 dígitos que enviamos a tu correo.',
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    widget.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _error == null
                        ? const SizedBox.shrink(key: ValueKey('no_error'))
                        : Padding(
                            key: const ValueKey('error'),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AuthErrorBanner(
                              message: _error!,
                              onDismiss: () => setState(() => _error = null),
                            ),
                          ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: (_error != null || _resendInfo == null)
                        ? const SizedBox.shrink(key: ValueKey('no_resend_info'))
                        : Padding(
                            key: const ValueKey('resend_info'),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ResendInfoBanner(
                              message: _resendInfo!,
                              onDismiss: () =>
                                  setState(() => _resendInfo = null),
                            ),
                          ),
                  ),
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _pinController,
                      focusNode: _focusNode,
                      autofocus: true,
                      separatorBuilder: (_) => const SizedBox(width: 6),
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorPinTheme,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      forceErrorState: _error != null,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      onCompleted: (pin) {
                        if (!_loading) _submit(pin);
                      },
                      onChanged: (_) {
                        if (_error != null || _resendInfo != null) {
                          setState(() {
                            _error = null;
                            _resendInfo = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _loading
                        ? Padding(
                            key: const ValueKey('loading'),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('idle')),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: (_loading || _resending) ? null : _resend,
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _resending
                            ? SizedBox(
                                key: const ValueKey('resending'),
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : const Text(
                                'Reenviar código',
                                key: ValueKey('resend'),
                                style: TextStyle(fontWeight: FontWeight.w600),
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
}

class _ResendInfoBanner extends StatelessWidget {
  const _ResendInfoBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: scheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: scheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
