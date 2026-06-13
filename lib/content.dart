import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'audio_helper.dart';

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
    // Warm-up pool audio supaya tap pertama pun zero-latency
    MindLoveAudio.warmUp();
    _loadData();
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

  void _handleLoveClick() async {
    if (_clicks >= _maxClicks) return;

    setState(() {
      _clicks++;
    });

    // Simpan progres
    SharedPreferences prefs = await SharedPreferences.getInstance();
    unawaited(prefs.setInt('love_clicks', _clicks));

    // SFX tap — zero-latency dari pool
    unawaited(MindLoveAudio.playOneShot('audio/love-click.mp3', volume: 0.95));

    // Setiap kelipatan 100 → milestone sound + emoji burst
    if (_clicks % 100 == 0) {
      final int level = _clicks ~/ 100;
      if (level <= 15) {
        unawaited(MindLoveAudio.playOneShot('audio/$level.mp3', volume: 1.0));
      }
      _triggerParticleEffect();
    }
  }

  void _triggerParticleEffect() {
    // Spawn 20 emoji dari posisi tengah layar
    final List<_ParticleData> newParticles = List.generate(20, (_) {
      return _ParticleData(
        key: UniqueKey(),
        emoji: _emojis[_random.nextInt(_emojis.length)],
        // X spread ± 160px dari tengah
        offsetX: (_random.nextDouble() * 320) - 160,
        // Ketinggian terbang 250–450px
        flyHeight: 250 + _random.nextDouble() * 200,
        // Sedikit variasi durasi supaya tidak serentak persis
        durationMs: 1200 + _random.nextInt(600),
      );
    });

    setState(() {
      _particles.addAll(newParticles);
    });

    // Bersihkan partikel setelah animasi terpanjang selesai
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

  // ─── Warna hati berdasarkan progres ───────────────────────────────────────
  Color _getLoveColor() {
    final double p = _clicks / _maxClicks;
    if (p <= 0.25) {
      return Color.lerp(Colors.black, Colors.grey, p / 0.25)!;
    }
    if (p <= 0.50) {
      return Color.lerp(
        Colors.grey,
        MindLoveTheme.softPink,
        (p - 0.25) / 0.25,
      )!;
    }
    if (p <= 0.75) {
      return Color.lerp(
        MindLoveTheme.softPink,
        const Color(0xFF8B0000),
        (p - 0.50) / 0.25,
      )!;
    }
    return Color.lerp(
      const Color(0xFF8B0000),
      MindLoveTheme.loveRed,
      (p - 0.75) / 0.25,
    )!;
  }

  // Ukuran hati: 30 → 120 (diperkecil sedikit agar proporsional dalam orb baru)
  double _getLoveSize() => 30.0 + ((_clicks / _maxClicks) * 90.0);

  // ─── Avatar ──────────────────────────────────────────────────────────────
  Widget _buildAvatar(String path, String name, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // FIX: Perbesar avatar. Orb dikecilkan → avatar bisa lebih besar
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: MindLoveTheme.surfaceElevated.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: MindLoveTheme.softGlow,
            image: path.isNotEmpty
                ? DecorationImage(
                    image: FileImage(File(path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: path.isEmpty
              ? const Icon(Icons.person, color: Colors.white54, size: 46)
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: MindLoveTheme.mutedText,
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

  // ─── Love Orb (diperkecil: 180 → 140) ────────────────────────────────────
  Widget _buildLoveOrb() {
    final loveColor = _getLoveColor();
    // FIX: Perkecil orb dari 180 → 140 supaya avatar punya ruang lebih lega
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: 1.0 + ((_clicks / _maxClicks) * 0.06),
      child: Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: MindLoveTheme.romanticGlowGradient,
          boxShadow: [...MindLoveTheme.redGlow, ...MindLoveTheme.blueGlow],
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MindLoveTheme.deepMidnight.withValues(alpha: 0.74),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                Icons.favorite,
                color: loveColor,
                size: _getLoveSize(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Tombol Tap Love ──────────────────────────────────────────────────────
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
            gradient: MindLoveTheme.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: MindLoveTheme.redGlow,
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

  // ─── Progress Card (tanpa teks deskripsi) ─────────────────────────────────
  Widget _buildProgressCard() {
    final progress = _clicks / _maxClicks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MindLoveTheme.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: MindLoveTheme.softGlow,
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
                  color: MindLoveTheme.glowBlue,
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
                MindLoveTheme.loveRed,
              ),
            ),
          ),
          // FIX: Teks deskripsi dihapus
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
            // ── Glow blobs dekoratif ──────────────────────────────────────
            Positioned(
              left: -80,
              top: 24,
              child: _GlowBlob(
                color: MindLoveTheme.loveRed.withValues(alpha: 0.16),
                size: 180,
              ),
            ),
            Positioned(
              right: -70,
              bottom: 30,
              child: _GlowBlob(
                color: MindLoveTheme.neonBlue.withValues(alpha: 0.14),
                size: 170,
              ),
            ),

            // ── Konten utama ─────────────────────────────────────────────
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

                      // ── Row avatar + orb ─────────────────────────────
                      // Pakai IntrinsicHeight agar kolom avatar bisa
                      // stretch mengisi tinggi yang sama dengan orb,
                      // tanpa mengubah urutan/posisi elemen.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar kiri (partner) — flex:1 → ambil sisa ruang
                            Expanded(
                              child: Center(
                                child: _buildAvatar(
                                  _partnerImagePath,
                                  _partnerName,
                                  'Partner',
                                ),
                              ),
                            ),

                            // Orb tengah — lebar fixed, tidak ikut flex
                            _buildLoveOrb(),

                            // Avatar kanan (you) — flex:1 → ambil sisa ruang
                            Expanded(
                              child: Center(
                                child: _buildAvatar(
                                  _userImagePath,
                                  _userName,
                                  'You',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Stack: tombol + partikel emoji ───────────────
                      // Partikel di-render di dalam Stack lokal yang
                      // di-clip ke area layar; Center memastikan origin
                      // partikel tepat di tengah tombol.
                      SizedBox(
                        height: 60,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            _buildLoveButton(),
                            // Overlay partikel, muncul di atas tombol
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

// ============================================================
// DATA MODEL PARTIKEL
// ============================================================
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

// ============================================================
// WIDGET PARTIKEL EMOJI ANIMASI
// Muncul dari posisi tombol "Tap Love", terbang ke atas + fade
// ============================================================
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
        // Mulai fade di 40% perjalanan supaya terlihat lebih lama
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

// ============================================================
// DEKORASI GLOW BLOB
// ============================================================
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