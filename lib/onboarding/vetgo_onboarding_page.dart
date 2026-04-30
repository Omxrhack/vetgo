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

  static const Color _onImageText = Colors.white;
  static const Color _onImageSubtle = Color(0xE6FFFFFF); // ~90% white

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final pageDecoration = PageDecoration(
      fullScreen: true,
      imageFlex: 6,
      bodyFlex: 4,
      footerFlex: 0,
      safeArea: 8,
      bodyAlignment: Alignment.bottomCenter,
      imageAlignment: Alignment.center,
      contentMargin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      titlePadding: const EdgeInsets.only(bottom: 12),
      bodyPadding: const EdgeInsets.only(bottom: 20),
      titleTextStyle: theme.textTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w700,
        color: _onImageText,
        height: 1.2,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      bodyTextStyle: theme.textTheme.bodyLarge!.copyWith(
        color: _onImageSubtle,
        height: 1.35,
        shadows: const [
          Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 1)),
        ],
      ),
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.black,
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 1,
      dotsFlex: 2,
      showDoneButton: false,
      onSkip: onFinished,
      skip: const Text(
        'Omitir',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _onImageText,
        ),
      ),
      next: const Icon(Icons.arrow_forward, color: _onImageText),
      baseBtnStyle: TextButton.styleFrom(foregroundColor: _onImageText),
      showBackButton: false,
      pages: [
        PageViewModel(
          title: 'Tu mascota, siempre acompañada',
          body:
              'Encuentra veterinarios, emergencias y seguimiento del cuidado en un solo lugar.',
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page1),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'Cuidado que se adapta a ti',
          body:
              'Guarda historial, citas y recordatorios pensados para la salud de tu compañero.',
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page2),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: 'Empieza en segundos',
          body:
              'Sin complicaciones: agenda, consulta y actúa cuando más importa.',
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page3),
          decoration: pageDecoration.copyWith(footerFlex: 1),
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
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
                      color: _onImageSubtle,
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
      dotsDecorator: const DotsDecorator(
        size: Size(8, 8),
        activeSize: Size(22, 8),
        activeColor: Colors.white,
        color: Color(0x66FFFFFF),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        spacing: EdgeInsets.symmetric(horizontal: 4),
      ),
      dotsContainerDecorator: const BoxDecoration(
        color: Color(0x33000000),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      controlsMargin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      controlsPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      curve: Curves.easeInOut,
    );
  }
}

/// Imagen a pantalla completa + degradado oscuro de abajo hacia arriba (para texto blanco abajo).
class _FullBleedOnboardingImage extends StatelessWidget {
  const _FullBleedOnboardingImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: primary.withValues(alpha: 0.25),
                child: Center(
                  child: Icon(
                    Icons.pets_rounded,
                    size: 96,
                    color: primary.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.52, 0.78],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
