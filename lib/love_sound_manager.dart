import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// ================================================================
/// ANALISIS FINAL — MENGAPA lowLatency TIDAK BISA DIANDALKAN DI SINI
/// ================================================================
///
/// SoundPoolPlayer.start() (lowLatency) punya dua path:
///   if (streamId != null) → soundPool.resume(streamId)   // replay
///   else if (soundId != null) → soundPool.play(soundId)  // first play
///
/// Masalahnya: setelah seek(0), streamId di-set null.
/// resume() kemudian memanggil start() → streamId null → butuh soundId.
/// soundId hanya ada setelah async onLoadComplete callback dari SoundPool.
/// Jika timing tidak tepat (player belum "prepared"), suara tidak bunyi.
///
/// SOLUSI FINAL: Semua player tap + success pakai mediaPlayer mode.
/// play(AssetSource) di mediaPlayer mode = atomic, reliable, tidak ada
/// race condition async load. Overhead sedikit lebih tinggi tapi
/// dengan pool 8 player, tiap player punya cukup "recovery time"
/// antara tap sehingga tidak ada overload.
///
/// Milestone tetap mediaPlayer + play(AssetSource) karena ganti file.
/// ================================================================

class LoveSoundManager {
  // Pool 8 player — cukup untuk tap cepat sekalipun, tiap player
  // punya jeda natural antar gilirannya (round-robin setiap 8 tap)
  static const int _clickPoolSize = 8;
  static final List<AudioPlayer> _clickPool = [];
  static int _clickIndex = 0;

  static AudioPlayer? _successPlayer;
  static AudioPlayer? _milestonePlayer;

  static bool _isInitialized = false;

  // mixWithOthers: tidak mematikan BGM, tidak rebut audio focus
  static final AudioContext _audioCtx = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    stayAwake: true,
  ).build();

  /// Inisialisasi semua player. Dipanggil SEKALI di initState().
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // ── Pool Tap Sound ─────────────────────────────────────────────
      // mediaPlayer mode: play() atomic dan reliable di semua kondisi
      for (int i = 0; i < _clickPoolSize; i++) {
        final p = AudioPlayer();
        await p.setAudioContext(_audioCtx);
        // Tidak perlu setPlayerMode(mediaPlayer) — itu sudah default
        // Tidak perlu setSource dulu — play(AssetSource) langsung handle
        _clickPool.add(p);
      }

      // ── Success Alert Player ───────────────────────────────────────
      _successPlayer = AudioPlayer();
      await _successPlayer!.setAudioContext(_audioCtx);

      // ── Milestone Level Player ─────────────────────────────────────
      _milestonePlayer = AudioPlayer();
      await _milestonePlayer!.setAudioContext(_audioCtx);

      _isInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('[LoveSoundManager] init error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  /// Suara tap — round-robin pool 8 player, overlap penuh.
  ///
  /// play(AssetSource) di mediaPlayer mode:
  ///   - Atomic: satu call untuk stop-lama + load + play
  ///   - Tidak ada race condition async
  ///   - File kecil (love-click.mp3 = 7KB) → load nyaris instan
  // ──────────────────────────────────────────────────────────────────
  static void playTapSound() {
    if (!_isInitialized || _clickPool.isEmpty) return;

    final player = _clickPool[_clickIndex];
    _clickIndex = (_clickIndex + 1) % _clickPoolSize;

    unawaited(
      player.play(AssetSource('audio/love-click.mp3')).catchError((_) {}),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  /// Suara success alert — jalur independen dari tap.
  // ──────────────────────────────────────────────────────────────────
  static void playSuccessAlert() {
    if (!_isInitialized || _successPlayer == null) return;

    unawaited(
      _successPlayer!
          .play(AssetSource('audio/success-alert.mp3'))
          .catchError((_) {}),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  /// Suara angka level: 100 tap → 1.mp3, 200 tap → 2.mp3, dst.
  // ──────────────────────────────────────────────────────────────────
  static void playMilestoneLevel(int clicks) {
    if (!_isInitialized || _milestonePlayer == null) return;

    final int fileIndex = clicks ~/ 100;
    if (fileIndex < 1) return;

    unawaited(
      _milestonePlayer!
          .play(AssetSource('audio/$fileIndex.mp3'))
          .catchError((_) {}),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  /// Bersihkan semua resource. Dipanggil di dispose() screen.
  // ──────────────────────────────────────────────────────────────────
  static Future<void> dispose() async {
    for (final p in _clickPool) {
      await p.dispose();
    }
    _clickPool.clear();
    _clickIndex = 0;

    await _successPlayer?.dispose();
    _successPlayer = null;

    await _milestonePlayer?.dispose();
    _milestonePlayer = null;

    _isInitialized = false;
  }
}
