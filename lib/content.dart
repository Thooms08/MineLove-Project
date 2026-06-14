import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'love_sound_manager.dart'; // FIX: Menggunakan Sound Manager baru hasil kustomisasi khusus

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with TickerProviderStateMixin {
  String _partnerName = "";
  String _userName = "";
  String _partnerImagePath = "";
  String _userImagePath = "";

  int _clicks = 0;
  final int _maxClicks = 1500;
  bool _isPressed = false;

  // Partikel emoji — disimpan per-instance dengan key unik
  final List<_ParticleData> _particles = [];
  final List<String> _emojis = ['❤️', '💖', '🥰', '😍', '✨', '💕', '💘'];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // FIX: Menginisialisasi engine audio baru yang mengunci resource ke memori sejak awal
    LoveSoundManager.initialize();
    _loadData();
  }

  @override
  void dispose() {
    // FIX: Bersihkan seluruh pool audio agar tidak terjadi kebocoran memori (memory leak)
    LoveSoundManager.dispose();
    super.dispose();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _partnerName = prefs.getString('partner_name') ?? "Partner";
      _userName = prefs.getString('user_name') ?? "You";
      _partnerImagePath = prefs.getString('partner_image') ?? "";
      _userImagePath = prefs.getString('user_image') ?? "";
      _clicks = prefs.getInt('love_clicks') ?? 0;
    });
  }

  void _handleLoveClick() {
    if (_clicks >= _maxClicks) return;

    // ─────────────────────────────────────────────────────────────────
    // FIX: Jalankan sfx tap secara instan lewat sistem Round-Robin.
    // Tanpa antrean, tanpa await, suara langsung keluar di milidetik yang sama!
    // ─────────────────────────────────────────────────────────────────
    LoveSoundManager.playTapSound();

    final int newClicks = _clicks + 1;

    setState(() {
      _clicks = newClicks;
    });

    // Simpan progres ke local storage secara async background
    unawaited(_saveClicks(newClicks));

    // Setiap kelipatan 100 → Mainkan Milestone Level + Success Alert secara serentak
    if (newClicks % 100 == 0) {
      final int level = newClicks ~/ 100;
      
      // 1. Putar suara level (1.mp3, 2.mp3, dst) lewat player terisolasi khusus level
      if (level <= 15) {
        LoveSoundManager.playMilestoneLevel(level);
      }
      
      // 2. Putar suara success-alert.mp3 secara serentak lewat player terisolasi khusus alert
      LoveSoundManager.playSuccessAlert();
      
      // 3. Efek visual ledakan partikel
      _triggerParticleEffect();
    }
  }

  Future<void> _saveClicks(int clicks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('love_clicks', clicks);
  }

  void _triggerParticleEffect() {
    // Spawn 20 emoji dari posisi tengah layar
    final List<_ParticleData> newParticles = List.generate(20, (_) {
      return _ParticleData(
        key: UniqueKey(),
        emoji: _emojis[_random.nextInt(_emojis.length)],
        offsetX: (_random.nextDouble() * 320) - 160,
        flyHeight: 250 + _random.nextDouble() * 200,
        durationMs: 1200 + _random.nextInt(600),
      );
    });

    setState(() {
      _particles.addAll(newParticles);
    });

    // Bersihkan partikel setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _particles.removeWhere(
            (p) => newParticles.any((n) => n.key == p.key),
          );
        });
      }
    });
  }

  Color _getLoveColor() {
    final double p = _clicks / _maxClicks;
    if (p <= 0.25) {
      return Color.lerp(Colors.black, Colors.grey, p / 0.25)!;
    }
    if (p <= 0.50) {
      return Color.lerp(Colors.grey, MineLoveTheme.softPink, (p - 0.25) / 0.25)!;
    }
    if (p <= 0.75) {
      return Color.lerp(MineLoveTheme.softPink, const Color(0xFF8B0000), (p - 0.50) / 0.25)!;
    }
    return Color.lerp(const Color(0xFF8B0000), MineLoveTheme.loveRed, (p - 0.75) / 0.25)!;
  }

  double _getLoveSize(double orbSize) =>
      (orbSize * 0.21) + ((_clicks / _maxClicks) * (orbSize * 0.64));

  Widget _buildAvatar(String path, String name, String label, double avatarSize) {
    final double radius = avatarSize * 0.28;
    final double iconSize = avatarSize * 0.41;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: MineLoveTheme.surfaceElevated.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: MineLoveTheme.softGlow,
            image: path.isNotEmpty
                ? DecorationImage(
                    image: FileImage(File(path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: path.isEmpty
              ? Icon(Icons.person, color: Colors.white54, size: iconSize)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: MineLoveTheme.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLoveOrb(double orbSize) {
    final loveColor = _getLoveColor();
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: 1.0 + ((_clicks / _maxClicks) * 0.06),
      child: Container(
        width: orbSize,
        height: orbSize,
        padding: EdgeInsets.all(orbSize * 0.1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: MineLoveTheme.romanticGlowGradient,
          boxShadow: [...MineLoveTheme.redGlow, ...MineLoveTheme.blueGlow],
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MineLoveTheme.deepMidnight.withValues(alpha: 0.74),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                Icons.favorite,
                color: loveColor,
                size: _getLoveSize(orbSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoveButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleLoveClick();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isPressed ? 0.97 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: MineLoveTheme.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: MineLoveTheme.redGlow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Tap Love',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _clicks / _maxClicks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MineLoveTheme.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: MineLoveTheme.softGlow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Love Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$_clicks / $_maxClicks',
                style: const TextStyle(
                  color: MineLoveTheme.glowBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                MineLoveTheme.loveRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: -80,
              top: 24,
              child: _GlowBlob(
                color: MineLoveTheme.loveRed.withValues(alpha: 0.16),
                size: 180,
              ),
            ),
            Positioned(
              right: -70,
              bottom: 30,
              child: _GlowBlob(
                color: MineLoveTheme.neonBlue.withValues(alpha: 0.14),
                size: 170,
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Ukir setiap detak, dekap setiap rasa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, rowConstraints) {
                          final double maxW = rowConstraints.maxWidth;
                          final double orbSize = (maxW * 0.28).clamp(100.0, 140.0);
                          const double gap = 14.0;
                          final double remaining = maxW - orbSize - (gap * 2);
                          final double avatarSize = (remaining / 2).clamp(64.0, 110.0);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAvatar(_partnerImagePath, _partnerName, 'Partner', avatarSize),
                              const SizedBox(width: gap),
                              _buildLoveOrb(orbSize),
                              const SizedBox(width: gap),
                              _buildAvatar(_userImagePath, _userName, 'You', avatarSize),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 60,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            _buildLoveButton(),
                            ..._particles.map(
                              (p) => _EmojiParticle(
                                key: p.key,
                                emoji: p.emoji,
                                offsetX: p.offsetX,
                                flyHeight: p.flyHeight,
                                durationMs: p.durationMs,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildProgressCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParticleData {
  final Key key;
  final String emoji;
  final double offsetX;
  final double flyHeight;
  final int durationMs;

  const _ParticleData({
    required this.key,
    required this.emoji,
    required this.offsetX,
    required this.flyHeight,
    required this.durationMs,
  });
}

class _EmojiParticle extends StatefulWidget {
  final String emoji;
  final double offsetX;
  final double flyHeight;
  final int durationMs;

  const _EmojiParticle({
    super.key,
    required this.emoji,
    required this.offsetX,
    required this.flyHeight,
    required this.durationMs,
  });

  @override
  State<_EmojiParticle> createState() => _EmojiParticleState();
}

class _EmojiParticleState extends State<_EmojiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fly;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _fly = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(widget.offsetX, -_fly.value * widget.flyHeight),
          child: Opacity(
            opacity: _fade.value,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }
}

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