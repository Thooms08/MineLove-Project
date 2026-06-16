import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'main.dart';
import 'profile/main.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  // ── Animasi floating logo (naik turun) ──────────────────────────────────
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  // ── Animasi loading bar (0 → 1.0 dalam 10 detik) ───────────────────────
  late AnimationController _loadCtrl;
  late Animation<double> _loadAnim;

  // ── Animasi shimmer pada bar (bergeser terus) ───────────────────────────
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // ── Animasi fade-in seluruh konten ─────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Teks persentase ────────────────────────────────────────────────────
  int _percent = 0;

  static const Duration _splashDuration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();

    // 1. Floating logo — bolak-balik naik turun selamanya
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // 2. Loading bar — maju dari 0 ke 1.0 selama 10 detik
    //    Kurva: easeInOut agar terasa natural, tidak terkesan linear mesin
    _loadCtrl = AnimationController(vsync: this, duration: _splashDuration);
    _loadAnim = CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut);

    // Update persen setiap frame agar angka terlihat bergerak
    _loadCtrl.addListener(() {
      final int newPct = (_loadAnim.value * 100).round();
      if (newPct != _percent && mounted) {
        setState(() => _percent = newPct);
      }
    });

    // 3. Shimmer — geser terus menerus di atas bar
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // 4. Fade-in halaman saat pertama muncul
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Mulai loading bar
    _loadCtrl.forward();

    // Navigasi setelah 10 detik
    _checkProfileData();
  }

  void _checkProfileData() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasProfile = prefs.getBool('has_profile') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1500),
        pageBuilder: (_, __, ___) =>
            hasProfile ? const HomeScreen() : const ProfileSetupScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _loadCtrl.dispose();
    _shimmerCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineLoveTheme.deepMidnight,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0C1020), Color(0xFF090B14), Color(0xFF05070D)],
            ),
          ),
          child: Stack(
            children: [
              // ── Glow blob kiri atas ────────────────────────────────────
              Positioned(
                left: -100,
                top: 120,
                child: _GlowBlob(
                  color: MineLoveTheme.loveRed.withValues(alpha: 0.18),
                  size: 240,
                ),
              ),
              // ── Glow blob kanan bawah ──────────────────────────────────
              Positioned(
                right: -90,
                bottom: 90,
                child: _GlowBlob(
                  color: MineLoveTheme.neonBlue.withValues(alpha: 0.16),
                  size: 220,
                ),
              ),

              // ── Konten utama ───────────────────────────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo card floating
                  Center(
                    child: AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
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
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Loading bar section ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        // Label + persentase
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Titik berkedip + teks Loading
                            Row(
                              children: [
                                _PulsingDot(),
                                const SizedBox(width: 8),
                                const Text(
                                  'Loading',
                                  style: TextStyle(
                                    color: MineLoveTheme.mutedText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            // Angka persen
                            Text(
                              '$_percent%',
                              style: const TextStyle(
                                color: MineLoveTheme.glowBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Bar container
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _loadAnim,
                            _shimmerAnim,
                          ]),
                          builder: (_, __) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                height: 5,
                                child: Stack(
                                  children: [
                                    // Track gelap
                                    Container(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    // Fill gradient merah-pink
                                    FractionallySizedBox(
                                      widthFactor: _loadAnim.value,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              MineLoveTheme.loveRed,
                                              MineLoveTheme.softPink,
                                              MineLoveTheme.glowBlue,
                                            ],
                                            stops: [0.0, 0.65, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Shimmer kilap bergeser di atas fill
                                    if (_loadAnim.value > 0.01)
                                      FractionallySizedBox(
                                        widthFactor: _loadAnim.value,
                                        child: LayoutBuilder(
                                          builder: (ctx, bc) {
                                            final double shimmerW =
                                                bc.maxWidth * 0.35;
                                            final double left =
                                                _shimmerAnim.value *
                                                    (bc.maxWidth + shimmerW) -
                                                shimmerW;
                                            return Stack(
                                              clipBehavior: Clip.hardEdge,
                                              children: [
                                                Positioned(
                                                  left: left,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: shimmerW,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.28,
                                                              ),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget titik berkedip di samping "Loading" ──────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MineLoveTheme.loveRed,
          boxShadow: [
            BoxShadow(
              color: MineLoveTheme.loveRed.withValues(alpha: 0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glow blob dekoratif di background ──────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
