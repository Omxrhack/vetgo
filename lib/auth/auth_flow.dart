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

int _orderOf(_AuthView v) => switch (v) {
      _AuthView.login => 0,
      _AuthView.register => 1,
      _AuthView.otp => 2,
    };

class _AuthFlowState extends State<AuthFlow> {
  late _AuthView _view;
  String _otpEmail = '';
  String? _otpHint;
  bool _reverse = false;

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

  void _go(_AuthView next, {VoidCallback? mutate}) {
    setState(() {
      _reverse = _orderOf(next) < _orderOf(_view);
      _view = next;
      mutate?.call();
    });
  }

  void _goRegister() => _go(_AuthView.register);

  void _goLogin() => _go(_AuthView.login, mutate: () => _otpHint = null);

  void _goOtp(String email, {String? hint, bool alreadyUnverified = false}) {
    _go(
      _AuthView.otp,
      mutate: () {
        _otpEmail = email;
        _otpHint = alreadyUnverified
            ? 'Este correo ya estaba registrado sin verificar. Ingresa el código que recibiste o pide uno nuevo abajo.'
            : hint;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_view) {
      _AuthView.login => KeyedSubtree(
          key: const ValueKey('auth_login'),
          child: LoginScreen(
            onSuccess: widget.onAuthenticated,
            onRegister: _goRegister,
            onNeedOtp: (email) => _goOtp(
              email,
              hint:
                  'Tu correo aún no está verificado. Ingresa el código que te enviamos.',
            ),
          ),
        ),
      _AuthView.register => KeyedSubtree(
          key: const ValueKey('auth_register'),
          child: RegisterScreen(
            onGoToOtp: (email, {required bool alreadyUnverified}) =>
                _goOtp(email, alreadyUnverified: alreadyUnverified),
            onLogin: _goLogin,
          ),
        ),
      _AuthView.otp => KeyedSubtree(
          key: const ValueKey('auth_otp'),
          child: VerifyOtpScreen(
            email: _otpEmail,
            hint: _otpHint,
            onVerified: widget.onAuthenticated,
            onNavigateToLogin: _goLogin,
          ),
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (c, animation) {
        final beginX = (c.key == child.key)
            ? (_reverse ? -0.18 : 0.18)
            : (_reverse ? 0.18 : -0.18);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(beginX, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: c,
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
      child: child,
    );
  }
}
