import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class LoveSoundManager {
  // Pool berukuran 12 menjamin tumpukan suara klik aman walau di-tap sangat cepat
  static const int _clickPoolSize = 12;
  static final List<AudioPlayer> _clickPool = [];
  static int _currentClickIndex = 0;

  // Jalur pipa terisolasi khusus agar milestone tidak mengganggu sfx tap
  static AudioPlayer? _successPlayer;
  static AudioPlayer? _milestonePlayer;

  static bool _isInitialized = false;

  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    stayAwake: true,
  ).build();

  /// Mengunci seluruh file audio ke dalam memori sejak awal (Warm-Up Total)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi Pool khusus untuk Klik Tombol (Pre-loaded)
      for (int i = 0; i < _clickPoolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setAudioContext(_audioContext);
        // Kunci file audio di memori native sekarang juga
        await player.setSource(AssetSource('audio/love-click.mp3'));
        _clickPool.add(player);
      }

      // 2. Inisialisasi Player khusus Success Alert Kelipatan 100
      _successPlayer = AudioPlayer();
      await _successPlayer!.setPlayerMode(PlayerMode.lowLatency);
      await _successPlayer!.setAudioContext(_audioContext);
      await _successPlayer!.setSource(AssetSource('audio/success-alert.mp3'));

      // 3. Inisialisasi Player khusus Angka Level Kelipatan 100
      _milestonePlayer = AudioPlayer();
      await _milestonePlayer!.setPlayerMode(PlayerMode.lowLatency);
      await _milestonePlayer!.setAudioContext(_audioContext);

      _isInitialized = true;
    } catch (e) {
      print("Error initializing LoveSoundManager: $e");
    }
  }

  /// Memutar suara klik secara instan tanpa delay dengan mekanisme Round-Robin
  static void playTapSound() {
    if (!_isInitialized || _clickPool.isEmpty) return;

    final player = _clickPool[_currentClickIndex];

    // Eksekusi instan: reset posisi ke paling awal lalu jalankan (overlapping diizinkan)
    unawaited(player.seek(Duration.zero).then((_) => player.resume()));

    // Geser giliran index ke player berikutnya
    _currentClickIndex = (_currentClickIndex + 1) % _clickPoolSize;
  }

  /// Memutar sound success-alert secara independen di jalurnya sendiri
  static void playSuccessAlert() {
    if (!_isInitialized || _successPlayer == null) return;
    unawaited(_successPlayer!.seek(Duration.zero).then((_) => _successPlayer!.resume()));
  }

  /// Memutar sound level kelipatan 100 secara independen tanpa memotong suara lain
  static void playMilestoneLevel(int level) {
    if (!_isInitialized || _milestonePlayer == null) return;

    unawaited(() async {
      try {
        await _milestonePlayer!.stop();
        await _milestonePlayer!.setSource(AssetSource('audio/$level.mp3'));
        await _milestonePlayer!.resume();
      } catch (_) {}
    }());
  }

  /// Bersihkan memori dari native player saat screen dihancurkan
  static Future<void> dispose() async {
    for (final player in _clickPool) {
      await player.dispose();
    }
    _clickPool.clear();
    await _successPlayer?.dispose();
    await _milestonePlayer?.dispose();
    _isInitialized = false;
  }
}