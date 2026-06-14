import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_helper.dart';
import 'theme.dart';
import 'opening.dart';
import 'content.dart';
import 'profile/edit.dart';

void main() {
  runApp(const MineLoveApp());
}

class MineLoveApp extends StatelessWidget {
  const MineLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mine Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: MineLoveTheme.deepMidnight,
      ),
      home: OpeningScreen(),
    );
  }
}

// ==========================================
// HOME SCREEN (NAVBAR + REALTIME CLOCK)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  AudioPlayer? _bgmPlayer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Warm-up audio pool sedini mungkin supaya tap pertama langsung responsif
    MineLoveAudio.warmUp();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _startBackgroundMusic();
  }

  Future<void> _startBackgroundMusic() async {
    _bgmPlayer = await MineLoveAudio.playLooping(
      'audio/backsound.mp3',
      volume: 0.45,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _bgmPlayer?.dispose();
    MineLoveAudio.disposePool();
    super.dispose();
  }

  String _getIndoDate(DateTime time) {
    List<String> days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    String day = days[time.weekday - 1];
    String month = months[time.month - 1];

    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    String s = time.second.toString().padLeft(2, '0');

    return "$day, ${time.day} $month ${time.year} - $h:$m:$s";
  }

  // FIX: Navigasi ke halaman Edit Profile saat icon profile di navbar ditekan.
  // SFX click dimainkan agar konsisten dengan interaksi tombol lain di app.
  void _openProfileEdit() {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineLoveTheme.deepMidnight,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0E1A), Color(0xFF090B14), Color(0xFF05070D)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: MineLoveTheme.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: MineLoveTheme.blueGlow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: MineLoveTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: MineLoveTheme.redGlow,
                            ),
                            child: Image.asset('assets/logo/logo.png'),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mine Love',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: MineLoveTheme.secondaryDark.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: MineLoveTheme.neonBlue.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                _getIndoDate(_currentTime),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MineLoveTheme.glowBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // ── FIX: Icon profile di navbar ──────────────
                          // Tap untuk membuka halaman Edit Profile.
                          GestureDetector(
                            onTap: _openProfileEdit,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: MineLoveTheme.secondaryDark.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: MineLoveTheme.neonBlue.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: MineLoveTheme.glowBlue,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(child: ContentScreen()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}