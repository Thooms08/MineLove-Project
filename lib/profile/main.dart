import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../audio_helper.dart';
import '../theme.dart';
import '../main.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final AudioPlayer _bgmPlayer = AudioPlayer();

  final TextEditingController _partnerNameCtrl = TextEditingController();
  final TextEditingController _userNameCtrl = TextEditingController();
  File? _partnerImage;
  File? _userImage;

  @override
  void initState() {
    super.initState();
    _playWelcomeSound(); // Manggil SFX pas baru nyampe halaman ini
    _playBGM(); // Manggil BGM biar ga sepi
  }

  // Fungsi muterin suara pas pertama kali buka Setup Profile
  void _playWelcomeSound() async {
    unawaited(
      MindLoveAudio.playOneShot('audio/setup-profile.mp3', volume: 1.0),
    );
  }

  void _playBGM() async {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('audio/backsound.mp3'));
  }

  Future<void> _pickImage(bool isPartner) async {
    unawaited(MindLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));
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

  void _saveProfile() async {
    unawaited(MindLoveAudio.playOneShot('audio/click.mp3', volume: 0.9));

    // Validasi kalau nama kosong gak bisa disimpen
    if (_partnerNameCtrl.text.isEmpty || _userNameCtrl.text.isEmpty) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_name', _partnerNameCtrl.text);
    await prefs.setString('user_name', _userNameCtrl.text);
    if (_partnerImage != null) {
      await prefs.setString('partner_image', _partnerImage!.path);
    }
    if (_userImage != null) {
      await prefs.setString('user_image', _userImage!.path);
    }

    // Set flag kalo user udah pernah setup profile
    await prefs.setBool('has_profile', true);

    unawaited(
      MindLoveAudio.playOneShot('audio/success-alert.mp3', volume: 1.0),
    );
    _showSuccessAlert();
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
                Icon(Icons.favorite, color: MindLoveTheme.loveRed, size: 50),
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

    // Otomatis pindah ke main.dart (HomeScreen) setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _bgmPlayer.stop(); // Stop BGM di halaman ini biar ga double pas di home
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  void dispose() {
    // Matiin semua player pas halamannya ditutup biar ga bocor memory
    _bgmPlayer.dispose();
    _partnerNameCtrl.dispose();
    _userNameCtrl.dispose();
    super.dispose();
  }

  Widget _buildProfileInput(
    bool isPartner,
    File? image,
    TextEditingController controller,
    String label,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImage(isPartner),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MindLoveTheme.neonBlue, width: 2),
              boxShadow: MindLoveTheme.redGlow,
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
              color: MindLoveTheme.surface,
            ),
            child: image == null
                ? const Icon(Icons.add_a_photo, color: Colors.white54)
                : null,
          ),
        ),
        const SizedBox(height: 16),
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
              borderSide: BorderSide(color: MindLoveTheme.loveRed),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindLoveTheme.deepMidnight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Setup Pasangan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  // Sesuai request: Pacar (Partner) Kiri, Lu (User) Kanan
                  Expanded(
                    child: _buildProfileInput(
                      true,
                      _partnerImage,
                      _partnerNameCtrl,
                      "Nama Pacar",
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildProfileInput(
                      false,
                      _userImage,
                      _userNameCtrl,
                      "Nama Kamu",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _saveProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: MindLoveTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: MindLoveTheme.redGlow,
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
    );
  }
}
