import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomPaint(
          painter: BioPatternPainter(Colors.white),
          child: Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.85, end: 1.0).animate(fade),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 12))
                        ],
                      ),
                      child: const Icon(Icons.biotech_rounded,
                          size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('أكاديمية د. راشيا', 'Dr. Rashia Academy'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('علم الأحياء • الثانوية العامة',
                          'Biology • Egyptian Secondary School'),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                    const SizedBox(height: 36),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
