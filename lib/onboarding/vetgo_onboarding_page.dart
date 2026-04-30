import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../theme/vetgo_typography.dart';
import 'onboarding_assets.dart';

class VetgoOnboardingPage extends StatelessWidget {
  const VetgoOnboardingPage({
    super.key,
    required this.onFinished,
    this.onSignIn,
  });

  final VoidCallback onFinished;
  final VoidCallback? onSignIn;

  static const Color _onImageText = Colors.white;
  static const Color _onImageSubtle = Color(0xF2FFFFFF);

  static final Curve _curve = Curves.easeOutCubic;

  /// Tipografía más grande y legible sobre la foto.
  static TextStyle _titleStyle() {
    return const TextStyle(
      fontFamily: VetgoTypography.family,
      fontSize: 31,
      fontWeight: FontWeight.w700,
      height: 1.12,
      letterSpacing: -0.6,
      color: _onImageText,
      shadows: [
        Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 3)),
      ],
    );
  }

  static TextStyle _bodyStyle() {
    return const TextStyle(
      fontFamily: VetgoTypography.family,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.48,
      letterSpacing: 0.15,
      color: _onImageSubtle,
      shadows: [
        Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = _titleStyle();
    final bodyStyle = _bodyStyle();

    final pageDecoration = PageDecoration(
      fullScreen: true,
      imageFlex: 5,
      bodyFlex: 5,
      footerFlex: 0,
      // Aire bajo el texto para que no quede pegado a Omitir / puntos / flecha.
      safeArea: 56,
      bodyAlignment: Alignment.bottomCenter,
      imageAlignment: Alignment.center,
      contentMargin: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      titlePadding: const EdgeInsets.only(bottom: 16),
      bodyPadding: const EdgeInsets.only(bottom: 24),
      titleTextStyle: titleStyle,
      bodyTextStyle: bodyStyle,
    );

    return IntroductionScreen(
      animationDuration: 480,
      globalBackgroundColor: Colors.black,
      showSkipButton: true,
      showNextButton: true,
      skipOrBackFlex: 1,
      nextFlex: 1,
      dotsFlex: 2,
      showDoneButton: false,
      onSkip: onFinished,
      overrideSkip: (context, onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: _OnboardingSkipButton(onPressed: onPressed),
      ),
      overrideNext: (context, onPressed) => Align(
        alignment: Alignment.centerRight,
        child: _OnboardingNextButton(onPressed: onPressed),
      ),
      showBackButton: false,
      pages: [
        PageViewModel(
          titleWidget: _OnboardingTitle(
            text: 'Tu mascota, siempre acompañada',
            style: titleStyle,
          ),
          bodyWidget: _OnboardingBody(
            text:
                'Encuentra veterinarios, emergencias y seguimiento del cuidado en un solo lugar.',
            style: bodyStyle,
          ),
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page1),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: _OnboardingTitle(
            text: 'Cuidado que se adapta a ti',
            style: titleStyle,
          ),
          bodyWidget: _OnboardingBody(
            text:
                'Guarda historial, citas y recordatorios pensados para la salud de tu compañero.',
            style: bodyStyle,
          ),
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page2),
          decoration: pageDecoration,
        ),
        PageViewModel(
          titleWidget: _OnboardingTitle(
            text: 'Empieza en segundos',
            style: titleStyle,
          ),
          bodyWidget: _OnboardingBody(
            text:
                'Sin complicaciones: agenda, consulta y actúa cuando más importa.',
            style: bodyStyle,
          ),
          image: _FullBleedOnboardingImage(assetPath: OnboardingAssets.page3),
          decoration: pageDecoration.copyWith(
            // Más zona superior → el copy queda más abajo; CTA sigue en ~30 %.
            imageFlex: 5,
            bodyFlex: 2,
            footerFlex: 3,
            safeArea: 25,
            // Título / cuerpo: separación media (no tan amplia como en 1–2).
            titlePadding: const EdgeInsets.only(bottom: 12),
            descriptionPadding: const EdgeInsets.only(bottom: 14),
          ),
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: _OnboardingCtaFooter(
              scheme: scheme,
              theme: theme,
              onFinished: onFinished,
              onSignIn: onSignIn,
            ),
          ),
        ),
      ],
      dotsDecorator: DotsDecorator(
        size: const Size(7, 7),
        activeSize: const Size(24, 8),
        activeColor: Colors.white,
        color: Colors.white.withValues(alpha: 0.4),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        spacing: const EdgeInsets.symmetric(horizontal: 5),
      ),
      dotsContainerDecorator: null,
      controlsMargin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      controlsPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      curve: Curves.easeInOutCubic,
    );
  }
}

/// "Omitir" sin caja: solo texto + feedback al tocar.
class _OnboardingSkipButton extends StatelessWidget {
  const _OnboardingSkipButton({required this.onPressed});

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Omitir',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Omitir',
              style: TextStyle(
                fontFamily: VetgoTypography.family,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.5),
                decorationThickness: 1.2,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: VetgoOnboardingPage._curve);
  }
}

/// Flecha en círculo solo con borde, sin relleno.
class _OnboardingNextButton extends StatelessWidget {
  const _OnboardingNextButton({required this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Siguiente',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: Colors.white30,
          highlightColor: Colors.white12,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: VetgoOnboardingPage._curve)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}

class _OnboardingTitle extends StatelessWidget {
  const _OnboardingTitle({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(duration: 480.ms, curve: VetgoOnboardingPage._curve)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 480.ms,
          curve: VetgoOnboardingPage._curve,
        );
  }
}

class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(
          duration: 520.ms,
          delay: 90.ms,
          curve: VetgoOnboardingPage._curve,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          duration: 520.ms,
          delay: 90.ms,
          curve: VetgoOnboardingPage._curve,
        );
  }
}

class _OnboardingCtaFooter extends StatelessWidget {
  const _OnboardingCtaFooter({
    required this.scheme,
    required this.theme,
    required this.onFinished,
    required this.onSignIn,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final VoidCallback onFinished;
  final VoidCallback? onSignIn;

  static const Color _onImageSubtle = Color(0xE6FFFFFF);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      'Crear cuenta gratis',
                      style: TextStyle(
                        fontFamily: VetgoTypography.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: '¿Ya tienes cuenta? ',
                    style: TextStyle(
                      fontFamily: VetgoTypography.family,
                      fontSize: 15,
                      height: 1.3,
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
                            style: TextStyle(
                              fontFamily: VetgoTypography.family,
                              fontSize: 15,
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
        );
      },
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 100.ms, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: 450.ms,
          delay: 100.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

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
          )
              .animate()
              .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(1.06, 1.06),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
                curve: Curves.easeOutCubic,
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
