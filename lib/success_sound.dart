import 'love_sound_manager.dart';

/// Menangani semua sound yang terjadi saat milestone kelipatan 100.
/// Berjalan di jalur audio TERPISAH dari tap sound,
/// sehingga tidak ada suara yang saling memotong.
class SuccessSound {
  SuccessSound._();

  /// Dipanggil setiap klik dari _handleLoveClick().
  /// Jika [clicks] adalah kelipatan 100, mainkan dua suara sekaligus:
  ///   1. success-alert.mp3  (jalur _successPlayer)
  ///   2. N.mp3              (jalur _milestonePlayer, N = clicks / 100)
  ///
  /// Contoh: clicks=300 → mainkan success-alert.mp3 + 3.mp3 bersamaan
  static void handleMilestone(int clicks) {
    if (clicks % 100 != 0) return;

    // Jalur 1: suara "ting!" notifikasi berhasil
    LoveSoundManager.playSuccessAlert();

    // Jalur 2: suara angka level (100→1.mp3, 200→2.mp3, dst)
    // Kirim nilai clicks aslinya — kalkulasi fileIndex ada di dalam manager
    LoveSoundManager.playMilestoneLevel(clicks);
  }
}
