import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/widgets/auth_scenic_layer.dart';
import '../auth/widgets/auth_screen_shell.dart';
import 'onboarding_assets.dart';

class VetgoOnboardingPage extends StatefulWidget {
  const VetgoOnboardingPage({
    super.key,
    required this.onFinished,
    this.onSignIn,
  });

  final VoidCallback onFinished;
  final VoidCallback? onSignIn;

  @override
  State<VetgoOnboardingPage> createState() => _VetgoOnboardingPageState();
}

class _VetgoOnboardingPageState extends State<VetgoOnboardingPage> {
  static const _pages = <_OnboardingSlide>[
    _OnboardingSlide(
      eyebrow: 'PASO 1 DE 3',
      title: 'Tu mascota, siempre acompañada',
      body:
          'Encuentra veterinarios, emergencias y seguimiento del cuidado en un solo lugar.',
      asset: OnboardingAssets.page1,
    ),
    _OnboardingSlide(
      eyebrow: 'PASO 2 DE 3',
      title: 'Cuidado que se adapta a ti',
      body:
          'Guarda historial, citas y recordatorios pensados para la salud de tu compañero.',
      asset: OnboardingAssets.page2,
    ),
    _OnboardingSlide(
      eyebrow: 'PASO 3 DE 3',
      title: 'Empieza en segundos',
      body:
          'Sin complicaciones: agenda, consulta y actúa cuando más importa.',
      asset: OnboardingAssets.page3,
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index >= _pages.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = _index == _pages.length - 1;

    return AuthPageShell(
      variant: AuthScenicVariant.login,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingSlideView(
                  key: ValueKey('slide_$i'),
                  slide: _pages[i],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                children: [
                  _DotsIndicator(
                    count: _pages.length,
                    index: _index,
                    activeColor: scheme.primary,
                    inactiveColor: scheme.outline.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isLast
                        ? _FinalCtaBlock(
                            key: const ValueKey('cta_final'),
                            onCreate: widget.onFinished,
                            onSignIn: widget.onSignIn ?? widget.onFinished,
                          )
                        : _PagerControls(
                            key: const ValueKey('cta_pager'),
                            onSkip: widget.onFinished,
                            onNext: _goNext,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String asset;
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({super.key, required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: AuthStagger(
          delayStep: const Duration(milliseconds: 70),
          children: [
            Text(
              slide.eyebrow,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            _SlideHero(asset: slide.asset),
            const SizedBox(height: 28),
            Text(
              slide.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              slide.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideHero extends StatelessWidget {
  const _SlideHero({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxWidth * 0.95;
        return Container(
          height: h.clamp(220.0, 360.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.pets_rounded,
                  size: 72,
                  color: scheme.primary.withValues(alpha: 0.55),
                ),
              );
            },
          ),
        )
            .animate()
            .fadeIn(duration: 380.ms, curve: Curves.easeOutCubic)
            .scale(
              begin: const Offset(0.98, 0.98),
              end: const Offset(1, 1),
              duration: 480.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.index,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 22 : 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _PagerControls extends StatelessWidget {
  const _PagerControls({
    super.key,
    required this.onSkip,
    required this.onNext,
  });

  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          child: const Text(
            'Omitir',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            minimumSize: const Size(140, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Siguiente'),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinalCtaBlock extends StatelessWidget {
  const _FinalCtaBlock({
    super.key,
    required this.onCreate,
    required this.onSignIn,
  });

  final VoidCallback onCreate;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          child: const Text('Crear cuenta gratis'),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
                children: [
                  const TextSpan(text: '¿Ya tienes cuenta? '),
                  TextSpan(
                    text: 'Iniciar sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
