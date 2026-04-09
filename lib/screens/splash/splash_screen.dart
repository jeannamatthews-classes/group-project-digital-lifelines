import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _orbitController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoGlow;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 0.52, curve: Curves.easeOutBack),
      ),
    );
    _logoGlow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.34, 0.8, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.28, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.58, 1, curve: Curves.easeOut),
      ),
    );

    _introController.forward();
    _goToHome();
  }

  Future<void> _goToHome() async {
    _navTimer = Timer(const Duration(milliseconds: 2900), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 520),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  Widget _floatingOrb({
    required double size,
    required Color color,
    required double angle,
    required double radius,
    required double opacity,
  }) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        final t = _orbitController.value * 2 * math.pi;
        final x = math.cos(t + angle) * radius;
        final y = math.sin(t + angle) * (radius * 0.45);
        return Transform.translate(
          offset: Offset(x, y),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAnimatedCore() {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _orbitController]),
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _floatingOrb(
                    size: 22,
                    color: AppColors.primary,
                    angle: 0,
                    radius: 66,
                    opacity: 0.18,
                  ),
                  _floatingOrb(
                    size: 14,
                    color: AppColors.accent,
                    angle: 1.8,
                    radius: 74,
                    opacity: 0.25,
                  ),
                  _floatingOrb(
                    size: 18,
                    color: AppColors.primaryDark,
                    angle: 3.2,
                    radius: 58,
                    opacity: 0.15,
                  ),
                  Container(
                    width: 118 + (8 * _logoGlow.value),
                    height: 118 + (8 * _logoGlow.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(
                            alpha: 0.20 * _logoGlow.value,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: const Text(
                  'Digital Lifelines',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.appBarText,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _subtitleFade,
              child: const Text(
                'Design your timelines. Save the moments.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _subtitleFade,
              child: Container(
                width: 108,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _introController.value.clamp(0.06, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAFF), Color(0xFFE9F0FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(child: _buildAnimatedCore()),
          ],
        ),
      ),
    );
  }
}
