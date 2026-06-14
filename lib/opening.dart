import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'main.dart'; // Buat arahin ke Home
import 'profile/main.dart'; // Buat arahin ke Setup Profile

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    // Animasi Floating 4 detik
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _checkProfileData();
  }

  void _checkProfileData() async {
    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasProfile = prefs.getBool('has_profile') ?? false;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(
            milliseconds: 1500,
          ), // Animasi Slow
          pageBuilder: (context, animation, secondaryAnimation) =>
              hasProfile ? const HomeScreen() : const ProfileSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineLoveTheme.deepMidnight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C1020), Color(0xFF090B14), Color(0xFF05070D)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -100,
              top: 120,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MineLoveTheme.loveRed.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -90,
              bottom: 90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MineLoveTheme.neonBlue.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: MineLoveTheme.surface.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: MineLoveTheme.redGlow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 122,
                            height: 122,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MineLoveTheme.primaryGradient,
                              boxShadow: MineLoveTheme.redGlow,
                            ),
                            child: Image.asset('assets/logo/logo.png'),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Mine Love',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Romantic futuristic love space',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MineLoveTheme.secondaryText,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
