import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../audio_helper.dart';
import '../theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final AudioPlayer _bgmPlayer = AudioPlayer();

  final TextEditingController _partnerNameCtrl = TextEditingController();
  final TextEditingController _userNameCtrl = TextEditingController();

  File? _partnerImage;
  File? _userImage;

  // ─── Nilai awal (sebelum diedit) — dipakai untuk deteksi perubahan ───────
  // Catatan: _initialUserName dipakai untuk preview nama user saat ini.
  // _initialPartnerName & _initialPartnerImagePath dipakai untuk deteksi
  // apakah profil pasangan diubah (memicu popup ganti pasangan).
  // Tidak ada "_initialUserImagePath" karena perubahan foto profil sendiri
  // tidak memicu logika apapun (preview cukup dari _userImage).
  String _initialPartnerName = "";
  String _initialUserName = "";
  String _initialPartnerImagePath = "";

  bool _isLoading = true;

  // FIX: state loading khusus saat proses reset progress love ke 0
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _playWelcomeSound();
    _playBGM();
    _loadCurrentProfile();
  }

  // Sama seperti profile/main.dart — SFX pas buka halaman ini
  void _playWelcomeSound() async {
    unawaited(
      MineLoveAudio.playOneShot('audio/setup-profile.mp3', volume: 1.0),
    );
  }

  void _playBGM() async {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('audio/backsound.mp3'));
  }

  Future<void> _loadCurrentProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final partnerName = prefs.getString('partner_name') ?? "";
    final userName = prefs.getString('user_name') ?? "";
    final partnerImagePath = prefs.getString('partner_image') ?? "";
    final userImagePath = prefs.getString('user_image') ?? "";

    setState(() {
      _partnerNameCtrl.text = partnerName;
      _userNameCtrl.text = userName;
      _partnerImage = partnerImagePath.isNotEmpty
          ? File(partnerImagePath)
          : null;
      _userImage = userImagePath.isNotEmpty ? File(userImagePath) : null;

      _initialPartnerName = partnerName;
      _initialUserName = userName;
      _initialPartnerImagePath = partnerImagePath;

      _isLoading = false;
    });
  }

  Future<void> _pickImage(bool isPartner) async {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        if (isPartner) {
          _partnerImage = File(pickedFile.path);
        } else {
          _userImage = File(pickedFile.path);
        }
      });
    }
  }

  void _handleBack() {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
    _bgmPlayer.stop();
    Navigator.of(context).pop();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Tombol "Simpan" ditekan.
  // FIX: Deteksi dulu apakah profil PASANGAN (nama/foto partner) berubah.
  // - Jika TIDAK berubah (hanya profil sendiri / "You" yang diubah, atau
  //   tidak ada perubahan sama sekali) → simpan langsung tanpa popup.
  // - Jika profil pasangan berubah → munculkan popup konfirmasi 3 pilihan.
  // ─────────────────────────────────────────────────────────────────────
  void _onSavePressed() {
    unawaited(MineLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));

    if (_partnerNameCtrl.text.trim().isEmpty ||
        _userNameCtrl.text.trim().isEmpty) {
      return;
    }

    final bool partnerNameChanged =
        _partnerNameCtrl.text.trim() != _initialPartnerName;
    final bool partnerImageChanged =
        (_partnerImage?.path ?? "") != _initialPartnerImagePath;
    final bool partnerChanged = partnerNameChanged || partnerImageChanged;

    if (partnerChanged) {
      _showChangePartnerDialog();
    } else {
      _saveProfile(resetProgress: false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Popup konfirmasi ganti pasangan — 3 pilihan:
  // "Batal", "Cuma Mau Ganti Profile", "Lanjut Ganti Pasangan"
  // ─────────────────────────────────────────────────────────────────────
  void _showChangePartnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_border,
                  color: MineLoveTheme.loveRed,
                  size: 46,
                ),
                const SizedBox(height: 16),
                const Text(
                  "karena hati ini akan diberikan ke orang baru, "
                  "progress love kamu akan dimulai dari awal. "
                  "Yakin mau lanjut Ganti Pasangan Baru? 🥺❤️",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Tombol "Lanjut Ganti Pasangan" ───────────────────
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      unawaited(
                        MineLoveAudio.playOneShot(
                          'audio/click.mp3',
                          volume: 0.9,
                        ),
                      );
                      Navigator.of(context).pop();
                      _saveProfile(resetProgress: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: MineLoveTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: MineLoveTheme.redGlow,
                      ),
                      child: const Center(
                        child: Text(
                          "Lanjut Ganti Pasangan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tombol "Cuma Mau Ganti Profile" ──────────────────
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      unawaited(
                        MineLoveAudio.playOneShot(
                          'audio/click.mp3',
                          volume: 0.9,
                        ),
                      );
                      Navigator.of(context).pop();
                      _saveProfile(resetProgress: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: MineLoveTheme.surfaceElevated.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Cuma Mau Ganti Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Tombol "Batal" ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      unawaited(
                        MineLoveAudio.playOneShot(
                          'audio/click.mp3',
                          volume: 0.9,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Simpan profil ke SharedPreferences.
  // Jika [resetProgress] true → tampilkan animasi loading lalu reset
  // 'love_clicks' ke 0 sebelum menampilkan popup sukses.
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _saveProfile({required bool resetProgress}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_name', _partnerNameCtrl.text.trim());
    await prefs.setString('user_name', _userNameCtrl.text.trim());

    if (_partnerImage != null) {
      await prefs.setString('partner_image', _partnerImage!.path);
    }
    if (_userImage != null) {
      await prefs.setString('user_image', _userImage!.path);
    }

    if (resetProgress) {
      // FIX: Tampilkan animasi loading saat proses reset progress ke 0
      await _runResetProgressWithLoading(prefs);
    }

    unawaited(
      MineLoveAudio.playOneShot('audio/success-alert.mp3', volume: 1.0),
    );
    _showSuccessAlert();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Animasi loading sederhana (overlay fullscreen) selama proses reset
  // progress love ke 0. Memberi jeda agar transisi terasa "diproses",
  // bukan instan tanpa feedback.
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _runResetProgressWithLoading(SharedPreferences prefs) async {
    setState(() => _isResetting = true);

    // Jeda kecil agar overlay loading sempat ter-render & terlihat user
    await Future.delayed(const Duration(milliseconds: 1200));

    await prefs.setInt('love_clicks', 0);

    if (!mounted) return;
    setState(() => _isResetting = false);
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, color: MineLoveTheme.loveRed, size: 50),
                SizedBox(height: 16),
                Text(
                  "Berhasil Disimpan!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Otomatis kembali ke halaman sebelumnya (HomeScreen) setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _bgmPlayer.stop();
      Navigator.of(context)
        ..pop() // tutup dialog sukses
        ..pop(); // kembali ke HomeScreen
    });
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _partnerNameCtrl.dispose();
    _userNameCtrl.dispose();
    super.dispose();
  }

  // ─── Avatar dengan preview foto + nama saat ini ──────────────────────────
  // FIX: Beda dari profile/main.dart — di sini ditampilkan preview foto
  // & nama PROFIL SAAT INI di atas, baru di bawahnya input untuk ganti.
  Widget _buildProfileInput(
    bool isPartner,
    File? image,
    TextEditingController controller,
    String label,
    String currentName,
  ) {
    return Column(
      children: [
        // ── Preview foto profil saat ini ────────────────────────────
        GestureDetector(
          onTap: () => _pickImage(isPartner),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MineLoveTheme.neonBlue, width: 2),
              boxShadow: MineLoveTheme.redGlow,
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
              color: MineLoveTheme.surface,
            ),
            child: image == null
                ? const Icon(Icons.add_a_photo, color: Colors.white54)
                : null,
          ),
        ),
        const SizedBox(height: 10),

        // ── Preview nama profil saat ini ────────────────────────────
        Text(
          currentName.isNotEmpty ? currentName : "Belum diatur",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // ── Input untuk ganti nama ───────────────────────────────────
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: MineLoveTheme.loveRed),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MineLoveTheme.deepMidnight,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: MineLoveTheme.loveRed,
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ── Header: tombol back + judul ─────────
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _handleBack,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: MineLoveTheme.surfaceElevated
                                          .withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    "Edit Profile",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Spacer kanan agar judul tetap center
                                // (lebar disamakan dengan tombol back)
                                const SizedBox(width: 44),
                              ],
                            ),
                            const SizedBox(height: 40),

                            Row(
                              children: [
                                // Pacar (Partner) Kiri
                                Expanded(
                                  child: _buildProfileInput(
                                    true,
                                    _partnerImage,
                                    _partnerNameCtrl,
                                    "Nama Pacar",
                                    _initialPartnerName,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Lu (User) Kanan
                                Expanded(
                                  child: _buildProfileInput(
                                    false,
                                    _userImage,
                                    _userNameCtrl,
                                    "Nama Kamu",
                                    _initialUserName,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 60),
                            GestureDetector(
                              onTap: _onSavePressed,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: MineLoveTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: MineLoveTheme.redGlow,
                                ),
                                child: const Center(
                                  child: Text(
                                    "Simpan",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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

            // ── Overlay loading saat reset progress love ke 0 ─────────
            if (_isResetting)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: MineLoveTheme.loveRed,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Mereset progress love...",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
    );
  }
}