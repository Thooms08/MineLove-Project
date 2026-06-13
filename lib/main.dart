import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_helper.dart';
import 'theme.dart';
import 'opening.dart';
import 'content.dart';

void main() {
  runApp(const MindLoveApp());
}

class MindLoveApp extends StatelessWidget {
  const MindLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Love',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: MindLoveTheme.deepMidnight,
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
    MindLoveAudio.warmUp();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _startBackgroundMusic();
  }

  Future<void> _startBackgroundMusic() async {
    _bgmPlayer = await MindLoveAudio.playLooping(
      'audio/backsound.mp3',
      volume: 0.45,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _bgmPlayer?.dispose();
    MindLoveAudio.disposePool();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindLoveTheme.deepMidnight,
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
                        color: MindLoveTheme.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: MindLoveTheme.blueGlow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: MindLoveTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: MindLoveTheme.redGlow,
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
                                  'Mind Love',
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
                                color: MindLoveTheme.secondaryDark.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: MindLoveTheme.neonBlue.withValues(
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
                                  color: MindLoveTheme.glowBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
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