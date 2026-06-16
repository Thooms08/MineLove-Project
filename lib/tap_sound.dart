import 'love_sound_manager.dart';

/// Wrapper tipis untuk memicu suara tap love.
/// Setiap panggilan play() langsung meneruskan ke LoveSoundManager
/// yang menggunakan pool 12 player (round-robin), sehingga:
///   - Tidak ada antrean / queue
///   - Overlapping penuh: tap secepat apapun tetap bunyi
///   - Tidak ada sound yang terpotong atau berhenti acak
class TapSound {
  TapSound._(); // tidak boleh diinstansiasi

  /// Picu suara tap love. Aman dipanggil berkali-kali secara bersamaan.
  static void play() {
    LoveSoundManager.playTapSound();
  }
}
