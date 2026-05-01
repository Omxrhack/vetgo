import '../network/vetgo_api_client.dart';
import 'auth_session.dart';
import 'auth_storage.dart';

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

    if (session == null) {
      return SessionBootstrapResult.unauthenticated;
    }

    final hasRefresh = session.refreshToken != null && session.refreshToken!.isNotEmpty;
    final hasAccess = session.hasAccessToken;

    if (!hasAccess && !hasRefresh) {
      await AuthStorage.clear();
      return SessionBootstrapResult.unauthenticated;
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
      );
      await AuthStorage.saveSession(session!);
      return true;
    }

    if (!hasAccess || await AuthStorage.isAccessExpired()) {
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

    AuthSession? me = await api.fetchMe(accessToken: accessToken);
    if (me == null) {
      final refreshed = await doRefresh();
      if (refreshed) {
        session = await AuthStorage.loadSession();
        accessToken = session?.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          me = await api.fetchMe(accessToken: accessToken);
        }
      }
    }

    if (me?.user != null) {
      session = session!.merge(user: me!.user, profile: me.profile);
      await AuthStorage.saveSession(session!);
    } else {
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
