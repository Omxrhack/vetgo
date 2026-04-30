import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'onboarding_assets.dart';

class VetgoOnboardingPage extends StatelessWidget {
  const VetgoOnboardingPage({
    super.key,
    required this.onFinished,
    this.onSignIn,
  });

  /// Después de registrarse / omitir / completar el tour.
  final VoidCallback onFinished;

  /// Si lo defines, el enlace "Iniciar sesión" lo usa; si no, llama a [onFinished].
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pageDecoration = PageDecoration(
      imageFlex: 3,
      bodyFlex: 2,
      safeArea: 24,
      titlePadding: const EdgeInsets.only(bottom: 12),
      bodyPadding: const EdgeInsets.only(bottom: 8),
      contentMargin: const EdgeInsets.symmetric(horizontal: 24),
      imagePadding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      titleTextStyle: theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        height: 1.2,
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.72),
        height: 1.35,
      ),
      boxDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A2E22),
                  scheme.surface,
                ]
              : [
                  const Color(0xFFE8F5EC),
                  scheme.surface,
                ],
        ),
      ),
    );

    return IntroductionScreen(
      globalBackgroundColor: scheme.surface,
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 1,
      dotsFlex: 2,
      showDoneButton: false,
      onSkip: onFinished,
      skip: Text(
        'Omitir',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
      ),
      next: Icon(Icons.arrow_forward, color: scheme.primary),
      baseBtnStyle: TextButton.styleFrom(foregroundColor: scheme.primary),
      showBackButton: false,
      pages: [
        PageViewModel(
          title: 'Tu mascota, siempre acompañada',
          body:
              'Encuentra veterinarios, emergencias y seguimiento del cuidado en un solo lugar.',
          image: _OnboardingImage(assetPath: OnboardingAssets.page1),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'Cuidado que se adapta a ti',
          body:
              'Guarda historial, citas y recordatorios pensados para la salud de tu compañero.',
          image: _OnboardingImage(assetPath: OnboardingAssets.page2),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'Empieza en segundos',
          body:
              'Sin complicaciones: agenda, consulta y actúa cuando más importa.',
          image: _OnboardingImage(assetPath: OnboardingAssets.page3),
          decoration: pageDecoration,
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onFinished,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Crear cuenta gratis',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: '¿Ya tienes cuenta? ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => (onSignIn ?? onFinished)(),
                          child: Text(
                            'Iniciar sesión',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
      dotsDecorator: DotsDecorator(
        size: const Size(8, 8),
        activeSize: const Size(22, 8),
        activeColor: scheme.primary,
        color: scheme.onSurface.withValues(alpha: 0.28),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        spacing: const EdgeInsets.symmetric(horizontal: 4),
      ),
      controlsMargin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      controlsPadding: const EdgeInsets.symmetric(vertical: 8),
      curve: Curves.easeInOut,
    );
  }
}

class _OnboardingImage extends StatelessWidget {
  const _OnboardingImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.pets_rounded,
                  size: 96,
                  color: primary.withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
