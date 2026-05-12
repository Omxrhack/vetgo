import 'package:flutter/material.dart';

import 'auth/auth_flow.dart';
import 'core/auth/auth_session.dart';
import 'core/auth/auth_storage.dart';
import 'core/network/vetgo_api_client.dart';
import 'core/permissions/app_startup_permissions.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_prefs.dart';
import 'onboarding/vetgo_onboarding_page.dart';
import 'profile_onboarding_flow.dart';
import 'splash/splash_screen.dart';
import 'core/auth/silent_auth.dart';

/// Orquesta las etapas iniciales con transición animada entre pantallas.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

enum _AppStage { splash, onboarding, auth, profileOnboarding, home }

class _AppFlowState extends State<AppFlow> {
  static const Duration _minSplashTime = Duration(seconds: 3);
  static const Duration _extraSplashTime = Duration(seconds: 1);

  _AppStage _stage = _AppStage.splash;
  bool _authStartAtOtp = false;
  String? _authOtpEmail;

  @override
  void initState() {
    super.initState();
    VetgoApiClient.onForceLogout = _onLoggedOut;
    _bootstrap();
  }

  @override
  void dispose() {
    VetgoApiClient.onForceLogout = null;
    super.dispose();
  }

  Future<void> _prepareApp() async {
    final startedAt = DateTime.now();
    await AppStartupPermissions.requestAll();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minSplashTime) {
      await Future<void>.delayed(_minSplashTime - elapsed);
    }
    await Future<void>.delayed(_extraSplashTime);
  }

  Future<void> _bootstrap() async {
    await _prepareApp();
    if (!mounted) return;
    final introDone = await OnboardingPrefs.isComplete();
    if (!mounted) return;
    if (!introDone) {
      setState(() => _stage = _AppStage.onboarding);
      return;
    }
    await _applySessionBootstrap();
  }

  Future<void> _applySessionBootstrap() async {
    final dest = await SessionBootstrap.resolve();
    if (!mounted) return;

    String? otpEmail;
    if (dest == SessionBootstrapResult.needsOtp) {
      otpEmail =
          await AuthStorage.readPendingOtpEmail() ??
          await AuthStorage.readEmail();
      if (otpEmail == null || otpEmail.isEmpty) {
        if (!mounted) return;
        setState(() {
          _authStartAtOtp = false;
          _authOtpEmail = null;
          _stage = _AppStage.auth;
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      switch (dest) {
        case SessionBootstrapResult.unauthenticated:
          _authStartAtOtp = false;
          _authOtpEmail = null;
          _stage = _AppStage.auth;
        case SessionBootstrapResult.needsOtp:
          _authStartAtOtp = true;
          _authOtpEmail = otpEmail;
          _stage = _AppStage.auth;
        case SessionBootstrapResult.needsProfileOnboarding:
          _authStartAtOtp = false;
          _authOtpEmail = null;
          _stage = _AppStage.profileOnboarding;
        case SessionBootstrapResult.home:
          _authStartAtOtp = false;
          _authOtpEmail = null;
          _stage = _AppStage.home;
      }
    });
  }

  Future<void> _onSessionUpdated() async {
    await _applySessionBootstrap();
  }

  void _onLoggedOut() {
    setState(() {
      _authStartAtOtp = false;
      _authOtpEmail = null;
      _stage = _AppStage.auth;
    });
  }

  Future<void> _finishIntroOnboarding() async {
    await OnboardingPrefs.markComplete();
    if (!mounted) return;
    await _applySessionBootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
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
      child: _stageChild(),
    );
  }

  Widget _stageChild() {
    switch (_stage) {
      case _AppStage.splash:
        return const KeyedSubtree(
          key: ValueKey<String>('splash'),
          child: SplashScreen(),
        );
      case _AppStage.onboarding:
        return KeyedSubtree(
          key: const ValueKey<String>('onboarding'),
          child: VetgoOnboardingPage(onFinished: _finishIntroOnboarding),
        );
      case _AppStage.auth:
        return KeyedSubtree(
          key: ValueKey<String>(
            'auth_${_authStartAtOtp}_${_authOtpEmail ?? ''}',
          ),
          child: AuthFlow(
            onAuthenticated: _onSessionUpdated,
            startAtOtp: _authStartAtOtp,
            initialOtpEmail: _authOtpEmail,
          ),
        );
      case _AppStage.profileOnboarding:
        return KeyedSubtree(
          key: const ValueKey<String>('profileOnboarding'),
          child: ProfileOnboardingFlow(onFinished: _onSessionUpdated),
        );
      case _AppStage.home:
        return KeyedSubtree(
          key: const ValueKey<String>('home'),
          child: HomeScreen(onLoggedOut: _onLoggedOut),
        );
    }
  }
}

/// Destino tras validar tokens en el arranque (`GET /auth/me` + refresh si hace falta).
enum SessionBootstrapResult {
  unauthenticated,
  needsOtp,
  needsProfileOnboarding,
  home,
}

/// Resuelve sesión persistida: renueva access si expiró, obtiene estado fresco del servidor.
abstract final class SessionBootstrap {
  static Future<SessionBootstrapResult> resolve() async {
    final api = VetgoApiClient();
    AuthSession? session = await AuthStorage.loadSession();
    var pendingOtpEmail = await AuthStorage.readPendingOtpEmail();

    bool hasRefresh(AuthSession? s) =>
        s?.refreshToken != null && s!.refreshToken!.isNotEmpty;
    bool hasAccess(AuthSession? s) => s?.hasAccessToken ?? false;

    Future<bool> trySilentRestore() async {
      final silent = await SilentAuth.attempt();
      switch (silent.kind) {
        case SilentAuthKind.success:
          session = await AuthStorage.loadSession();
          return session != null && hasAccess(session);
        case SilentAuthKind.needsOtp:
          final em = silent.otpEmail?.trim();
          if (em != null && em.isNotEmpty) {
            await AuthStorage.savePendingOtpEmail(em);
            pendingOtpEmail = em;
          }
          return false;
        case SilentAuthKind.noCredentials:
        case SilentAuthKind.failed:
          return false;
      }
    }

    if (!hasAccess(session) && !hasRefresh(session)) {
      if ((pendingOtpEmail ?? '').trim().isNotEmpty) {
        return SessionBootstrapResult.needsOtp;
      }
      await trySilentRestore();
      session = await AuthStorage.loadSession();
      pendingOtpEmail = await AuthStorage.readPendingOtpEmail();

      if (!hasAccess(session) && !hasRefresh(session)) {
        if ((pendingOtpEmail ?? '').trim().isNotEmpty) {
          return SessionBootstrapResult.needsOtp;
        }
        await AuthStorage.clear();
        return SessionBootstrapResult.unauthenticated;
      }
    }

    Future<bool> doRefresh() async {
      final rt = session?.refreshToken;
      if (rt == null || rt.isEmpty) return false;
      final fresh = await api.refreshSession(refreshToken: rt);
      if (fresh == null || !fresh.hasAccessToken) return false;
      session = session!.merge(
        accessToken: fresh.accessToken,
        refreshToken: fresh.refreshToken ?? session!.refreshToken,
        expiresIn: fresh.expiresIn,
        tokenType: fresh.tokenType,
        user: fresh.user ?? session!.user,
        profile: fresh.profile ?? session!.profile,
        details: fresh.details ?? session!.details,
      );
      await AuthStorage.saveSession(session!);
      return true;
    }

    if (!hasAccess(session) || await AuthStorage.isAccessExpired()) {
      final ok = await doRefresh();
      if (!ok) {
        await AuthStorage.clear();
        return SessionBootstrapResult.unauthenticated;
      }
    }

    var accessToken = session!.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      await AuthStorage.clear();
      return SessionBootstrapResult.unauthenticated;
    }

    AuthSession? me;
    var authRejected = false;

    Future<void> runFetch(String token) async {
      final pair = await api.fetchMeWithAuthHint(accessToken: token);
      me = pair.$1;
      authRejected = pair.$2;
    }

    await runFetch(accessToken);
    if (me == null) {
      final refreshed = await doRefresh();
      if (refreshed) {
        session = await AuthStorage.loadSession();
        accessToken = session?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          await runFetch(accessToken);
        }
      }
    }

    if (me != null && me!.user != null) {
      session = session!.merge(
        user: me!.user!,
        profile: me!.profile,
        details: me!.details,
      );
      await AuthStorage.saveSession(session!);
    } else {
      if (authRejected) {
        await AuthStorage.clear();
        return SessionBootstrapResult.unauthenticated;
      }
      return _fallbackFromCache();
    }

    if (!session!.isVerified) {
      return SessionBootstrapResult.needsOtp;
    }
    if (!session!.onboardingCompleted) {
      return SessionBootstrapResult.needsProfileOnboarding;
    }
    return SessionBootstrapResult.home;
  }

  static Future<SessionBootstrapResult> _fallbackFromCache() async {
    final cached = await AuthStorage.loadSession();
    if (cached == null) {
      await AuthStorage.clear();
      return SessionBootstrapResult.unauthenticated;
    }
    if (cached.isVerified && cached.onboardingCompleted) {
      return SessionBootstrapResult.home;
    }
    if (cached.isVerified && !cached.onboardingCompleted) {
      return SessionBootstrapResult.needsProfileOnboarding;
    }
    if (!cached.isVerified) {
      return SessionBootstrapResult.needsOtp;
    }
    await AuthStorage.clear();
    return SessionBootstrapResult.unauthenticated;
  }
}
