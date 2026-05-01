import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import 'verify_otp_screen.dart';

/// Orquesta login → registro → verificación OTP (mismo stack, sin `Navigator` anidado).
class AuthFlow extends StatefulWidget {
  const AuthFlow({
    super.key,
    required this.onAuthenticated,
    this.startAtOtp = false,
    this.initialOtpEmail,
  });

  final VoidCallback onAuthenticated;

  /// Si es true, abre directamente la pantalla OTP (p. ej. tras [SessionBootstrap]).
  final bool startAtOtp;

  /// Correo para OTP cuando [startAtOtp] es true.
  final String? initialOtpEmail;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

enum _AuthView { login, register, otp }

class _AuthFlowState extends State<AuthFlow> {
  late _AuthView _view;
  String _otpEmail = '';
  String? _otpHint;

  @override
  void initState() {
    super.initState();
    if (widget.startAtOtp &&
        widget.initialOtpEmail != null &&
        widget.initialOtpEmail!.trim().isNotEmpty) {
      _view = _AuthView.otp;
      _otpEmail = widget.initialOtpEmail!.trim();
      _otpHint = 'Verifica tu correo para continuar en Vetgo.';
    } else {
      _view = _AuthView.login;
    }
  }

  void _goRegister() => setState(() => _view = _AuthView.register);

  void _goLogin() => setState(() {
        _view = _AuthView.login;
        _otpHint = null;
      });

  void _goOtp(String email, {String? hint, bool alreadyUnverified = false}) {
    setState(() {
      _view = _AuthView.otp;
      _otpEmail = email;
      if (alreadyUnverified) {
        _otpHint =
            'Este correo ya estaba registrado sin verificar. Ingresa el código que recibiste o pide uno nuevo abajo.';
      } else {
        _otpHint = hint;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _AuthView.login => LoginScreen(
          onSuccess: widget.onAuthenticated,
          onRegister: _goRegister,
          onNeedOtp: (email) => _goOtp(
            email,
            hint:
                'Tu correo aún no está verificado. Ingresa el código que te enviamos.',
          ),
        ),
      _AuthView.register => RegisterScreen(
          onGoToOtp: (email, {required bool alreadyUnverified}) =>
              _goOtp(email, alreadyUnverified: alreadyUnverified),
          onLogin: _goLogin,
        ),
      _AuthView.otp => VerifyOtpScreen(
          email: _otpEmail,
          hint: _otpHint,
          onVerified: widget.onAuthenticated,
        ),
    };
  }
}
