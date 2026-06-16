import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'love_sound_manager.dart';
import 'tap_sound.dart'; // FIX: Mengimport file tap_sound baru
import 'success_sound.dart'; // FIX: Mengimport file success_sound baru

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

  // ── Animasi Progress Card ──────────────────────────────────────────────
  // _pulsCtrl : efek denyut (scale) saat naik milestone
  // _glowCtrl : animasi glow border berputar terus (looping)
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    LoveSoundManager.initialize();
    _loadData();

    // Pulse: denyut singkat saat milestone, scale 1.0 → 1.025 → 1.0
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulseAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.025), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.025, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Glow rotate: animasi shimmer border berputar terus menerus
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_glowCtrl);
  }

  @override
  void dispose() {
    LoveSoundManager.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
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
    // FIX: Menggunakan TapSound agar suara terpicu secara instan melalui pool
    // tanpa antrean dan mendukung overlapping (tumpukan suara realtime)
    // ─────────────────────────────────────────────────────────────────
    TapSound.play();

    final int newClicks = _clicks + 1;

    setState(() {
      _clicks = newClicks;
    });

    // Simpan progres ke local storage secara async background
    unawaited(_saveClicks(newClicks));

    // ─────────────────────────────────────────────────────────────────
    // FIX: Menggunakan SuccessSound untuk memproses milestone kelipatan 100
    // secara bersamaan/simultan tanpa memotong suara tap utama
    // ─────────────────────────────────────────────────────────────────
    SuccessSound.handleMilestone(newClicks);

    // Setiap kelipatan 100 → Efek visual ledakan partikel
    if (newClicks % 100 == 0) {
      _triggerParticleEffect();
      // Trigger denyut pada progress card
      _pulseCtrl.forward(from: 0.0);
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
      return Color.lerp(
        Colors.grey,
        MineLoveTheme.softPink,
        (p - 0.25) / 0.25,
      )!;
    }
    if (p <= 0.75) {
      return Color.lerp(
        MineLoveTheme.softPink,
        const Color(0xFF8B0000),
        (p - 0.50) / 0.25,
      )!;
    }
    return Color.lerp(
      const Color(0xFF8B0000),
      MineLoveTheme.loveRed,
      (p - 0.75) / 0.25,
    )!;
  }

  double _getLoveSize(double orbSize) =>
      (orbSize * 0.21) + ((_clicks / _maxClicks) * (orbSize * 0.64));

  // ── Warna milestone progress card (berubah tiap 100 tap) ──────────────
  // Level 0   (0–99)    : biru muda (starting)
  // Level 1   (100–199) : ungu lembut
  // Level 2   (200–299) : teal / cyan
  // Level 3   (300–399) : hijau zamrud
  // Level 4   (400–499) : kuning keemasan
  // Level 5   (500–599) : oranye
  // Level 6   (600–699) : merah muda terang
  // Level 7–9 (700–999) : merah cinta makin terang
  // Level 10+ (1000–)   : merah membara + efek paling intens
  static const List<List<Color>> _milestoneGradients = [
    [Color(0xFF4A90D9), Color(0xFF6EA8FF)], // 0   – ice blue
    [Color(0xFF9B59B6), Color(0xFFD89CFF)], // 100 – violet
    [Color(0xFF00BCD4), Color(0xFF80DEEA)], // 200 – cyan
    [Color(0xFF27AE60), Color(0xFF6FCF97)], // 300 – emerald
    [Color(0xFFF1C40F), Color(0xFFFFE082)], // 400 – gold
    [Color(0xFFE67E22), Color(0xFFFFAB76)], // 500 – amber
    [Color(0xFFE91E8C), Color(0xFFFF6EC7)], // 600 – hot pink
    [Color(0xFFFF2D55), Color(0xFFFF6B8A)], // 700 – love red
    [Color(0xFFFF1744), Color(0xFFFF616F)], // 800 – deep red
    [Color(0xFFD50000), Color(0xFFFF4D4D)], // 900 – crimson
    [Color(0xFFB71C1C), Color(0xFFFF6D00)], // 1000 – ember
    [Color(0xFFFF6D00), Color(0xFFFFAB00)], // 1100 – fire
    [Color(0xFFFFAB00), Color(0xFFFFD740)], // 1200 – gold fire
    [Color(0xFFFF4081), Color(0xFFFF80AB)], // 1300 – deep pink
    [Color(0xFFFF1744), Color(0xFFFF4D6D)], // 1400 – finale red
    [Color(0xFFFF4D6D), Color(0xFFFFAB91)], // 1500 – max love
  ];

  // Intensitas glow shadow makin besar seiring level
  List<BoxShadow> _getProgressCardGlow(int level, List<Color> grad) {
    final double intensity = 0.18 + (level / 15) * 0.55;
    final double spread = (level / 15) * 3.0;
    final double blur = 18 + (level / 15) * 26;
    return [
      BoxShadow(
        color: grad[0].withValues(alpha: intensity),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: grad[1].withValues(alpha: intensity * 0.6),
        blurRadius: blur * 1.4,
        spreadRadius: spread * 0.5,
      ),
    ];
  }

  // Ketebalan border makin tebal seiring level
  double _getProgressBorderWidth(int level) => 1.2 + (level / 15) * 1.6;

  // Label milestone yang muncul di header card
  String _getMilestoneLabel(int level) {
    const labels = [
      '',
      'First Love ❤️',
      'Growing 💕',
      'Blooming 🌸',
      'Sparkling ✨',
      'Burning 🔥',
      'Glowing 💫',
      'Passionate 💘',
      'Intense 💞',
      'Devoted 🥰',
      'Eternal 💖',
      'Blazing 🔥',
      'Golden 🌟',
      'Supreme 💎',
      'Ultimate 👑',
      'MAX LOVE ❤️‍🔥',
    ];
    if (level <= 0) return '';
    return level < labels.length ? labels[level] : labels.last;
  }

  Widget _buildAvatar(
    String path,
    String name,
    String label,
    double avatarSize,
  ) {
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
      // ─────────────────────────────────────────────────────────────────
      // FIX UTAMA: Pindahkan pemicu klik dari onTapUp ke onTapDown!
      // Pada clicker game berkecepatan tinggi, mendeteksi sentuhan awal (onTapDown)
      // menghilangkan delay fisik angkat jari, menghasilkan respon suara yang SUPER REALTIME.
      // ─────────────────────────────────────────────────────────────────
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _handleLoveClick();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
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
    final double progress = _clicks / _maxClicks;
    final int level = (_clicks ~/ 100).clamp(0, _milestoneGradients.length - 1);
    final List<Color> grad = _milestoneGradients[level];
    final List<BoxShadow> glow = _getProgressCardGlow(level, grad);
    final double borderWidth = _getProgressBorderWidth(level);
    final String milestoneLabel = _getMilestoneLabel(level);

    // Warna progress bar juga ikut gradient milestone
    final Color barColor = Color.lerp(grad[0], grad[1], 0.5)!;

    return ScaleTransition(
      scale: _pulseAnim,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          // Border gradient berputar — shimmer effect
          final double angle = _glowAnim.value * 2 * 3.14159;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // Outer glow shadow makin intens per level
              boxShadow: glow,
              // Gradient border tipis berputar sebagai shimmer
              gradient: LinearGradient(
                begin: Alignment(
                  -1.0 + 2.0 * (0.5 + 0.5 * _glowAnim.value),
                  -1.0 + 2.0 * (0.5 - 0.5 * _glowAnim.value),
                ),
                end: Alignment(
                  1.0 - 2.0 * (0.5 + 0.5 * _glowAnim.value) + 1,
                  1.0 + 2.0 * (0.5 - 0.5 * _glowAnim.value),
                ),
                colors: level == 0
                    ? [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.03),
                      ]
                    : [
                        grad[0].withValues(alpha: 0.7 + 0.3 * (level / 15)),
                        grad[1].withValues(alpha: 0.35),
                        grad[0].withValues(alpha: 0.5 + 0.3 * (level / 15)),
                      ],
                stops: level == 0 ? null : const [0.0, 0.5, 1.0],
                transform: GradientRotation(angle),
              ),
            ),
            padding: EdgeInsets.all(borderWidth),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: MineLoveTheme.surfaceElevated.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24 - 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Milestone label muncul mulai level 1
                  if (milestoneLabel.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        milestoneLabel,
                        key: ValueKey(level),
                        style: TextStyle(
                          color: grad[1],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Counter dengan warna sesuai level
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: level == 0 ? MineLoveTheme.glowBlue : grad[1],
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text('$_clicks / $_maxClicks'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar dengan warna dan animasi sesuai level
              Stack(
                children: [
                  // Track background
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Fill bar dengan gradient warna milestone
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: level == 0
                            ? [MineLoveTheme.loveRed, MineLoveTheme.softPink]
                            : [grad[0], grad[1]],
                      ),
                      boxShadow: level > 0
                          ? [
                              BoxShadow(
                                color: barColor.withValues(alpha: 0.55),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    // FractionallySizedBox tidak bisa langsung, pakai LayoutBuilder
                    child: LayoutBuilder(
                      builder: (ctx, bc) =>
                          SizedBox(width: bc.maxWidth * progress),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                          final double orbSize = (maxW * 0.28).clamp(
                            100.0,
                            140.0,
                          );
                          const double gap = 14.0;
                          final double remaining = maxW - orbSize - (gap * 2);
                          final double avatarSize = (remaining / 2).clamp(
                            64.0,
                            110.0,
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAvatar(
                                _partnerImagePath,
                                _partnerName,
                                'Partner',
                                avatarSize,
                              ),
                              const SizedBox(width: gap),
                              _buildLoveOrb(orbSize),
                              const SizedBox(width: gap),
                              _buildAvatar(
                                _userImagePath,
                                _userName,
                                'You',
                                avatarSize,
                              ),
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
    _fly = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
