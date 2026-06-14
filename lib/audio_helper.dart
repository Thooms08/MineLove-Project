import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';

class MineLoveAudio {
  // Pool ukuran 6 — cukup untuk tap cepat + milestone sound sekaligus
  static const int _poolSize = 6;
  static final Queue<AudioPlayer> _pool = Queue();
  static bool _poolReady = false;

  static final AudioContext _mixingContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    stayAwake: true,
  ).build();

  /// Panggil ini sekali saat app start (di initState HomeScreen / ContentScreen)
  /// supaya player sudah warm ketika user pertama kali tap.
  static Future<void> warmUp() async {
    if (_poolReady) return;
    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setAudioContext(_mixingContext);
      _pool.add(p);
    }
    _poolReady = true;
  }

  /// Ambil player dari pool → play → kembalikan ke pool setelah selesai.
  /// Latency nyaris nol karena player sudah di-init sebelumnya.
  static Future<void> playOneShot(
    String assetPath, {
    double volume = 1.0,
  }) async {
    // Jika pool belum siap, warm up dulu (fallback aman)
    if (!_poolReady) await warmUp();

    AudioPlayer player;
    if (_pool.isNotEmpty) {
      player = _pool.removeFirst();
    } else {
      // Pool habis (tap sangat cepat) → buat baru sekali ini
      player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setAudioContext(_mixingContext);
    }

    try {
      await player.stop(); // Reset state dari play sebelumnya
      await player.play(
        AssetSource(assetPath),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
      // Tunggu selesai, lalu kembalikan ke pool
      unawaited(
        player.onPlayerComplete.first.then((_) {
          if (_pool.length < _poolSize) {
            _pool.add(player);
          } else {
            player.dispose();
          }
        }),
      );
    } catch (_) {
      // Kembalikan ke pool meski error
      if (_pool.length < _poolSize) {
        _pool.add(player);
      } else {
        await player.dispose();
      }
    }
  }

  static Future<AudioPlayer> playLooping(
    String assetPath, {
    double volume = 1.0,
  }) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(
      AssetSource(assetPath),
      volume: volume,
      ctx: _mixingContext,
    );
    return player;
  }

  static Future<void> disposePool() async {
    for (final p in _pool) {
      await p.dispose();
    }
    _pool.clear();
    _poolReady = false;
  }
}