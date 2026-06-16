import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Navigasi ke halaman Edit Profile saat icon profile di navbar ditekan.
  void _openProfileEdit() {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
  }

  // Buka halaman donasi Saweria di browser eksternal
  Future<void> _openDonasi() async {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
    final Uri url = Uri.parse('https://saweria.co/minelove');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa membuka browser.'),
            backgroundColor: MineLoveTheme.surfaceElevated,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineLoveTheme.deepMidnight,
      // floatingActionButton DIHAPUS agar tidak menutupi konten utama
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
                  // ── Navbar (Hanya Logo, Teks, dan Profile) ──
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
                            padding: const EdgeInsets.all(6),
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

                          // ── Icon Profile di navbar ──
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

                  // ── Realtime Clock (Di luar / bawah Navbar) ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: MineLoveTheme.secondaryDark.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MineLoveTheme.neonBlue.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Text(
                        _getIndoDate(_currentTime),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MineLoveTheme.glowBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // ── Content ──
                  // Dibungkus dengan Expanded agar mengambil sisa ruang yang ada
                  // dan mengizinkan scroll secara internal tanpa mendesak area footer.
                  const Expanded(child: ContentScreen()),

                  // ── Tombol Donasi (Sebagai Footer Statis) ──
                  // Ditempatkan di luar Expanded sehingga posisinya selalu terpasang rapi
                  // di bagian bawah layar tanpa menutupi konten di dalam ContentScreen.
                 // ── Tombol Donasi (Sebagai Footer Statis) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Center(
                      child: GestureDetector(
                        onTap: _openDonasi,
                        child: Container(
                          height: 42, // <-- Diperkecil dari 50
                          padding: const EdgeInsets.symmetric(horizontal: 16), // <-- Diperkecil dari 24
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF4D6D), Color(0xFFFF7DAF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(21), // <-- Menyesuaikan setengah dari height (42/2) agar tetap bulat sempurna
                            boxShadow: [
                              BoxShadow(
                                color: MineLoveTheme.loveRed.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10, // <-- Blur sedikit dikurangi agar pas dengan ukuran kecil
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond_rounded,
                                color: Colors.white,
                                size: 12, // <-- Ikon diperkecil dari 18
                              ),
                              SizedBox(width: 4), // <-- Jarak antar ikon dan teks dikurangi dari 8
                              Text(
                                'Dukung Mine Love',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11, // <-- Font diperkecil dari 14
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}