import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_action_buttons.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/figcraft_assets.dart';
import '../widgets/tactile_interaction.dart';

/// Layar 2 pada Frame 1 LOGIN.figcraft: "Daftar Akun Baru" (Register).
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final AuthController controller;
  final ThaliaPalette palette;

  @override
  Widget build(BuildContext context) {
    final reg = controller.registerModel;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Tombol Back + Mini Shield Logo THALIA tepat di tengah
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TactilePressable(
                    onTap: () => controller.navigateTo(AuthScreenStep.welcome),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  FigcraftAssets.shieldLogo,
                  width: 26,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Judul & Subjudul
          StaggeredEntrance(
            delayMs: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi data diri Anda untuk mulai memantau sekitar.',
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Kartu Unggah Foto Profil (Terintegrasi Galeri / File Manager)
          StaggeredEntrance(
            delayMs: 80,
            child: TactilePressable(
              onTap: controller.pickProfilePhotoFromGallery,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: ThaliaColors.mintBannerFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: ThaliaColors.emeraldBright,
                                width: 1.2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: reg.profileImageBytes != null
                                ? Image.memory(
                                    reg.profileImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      FigcraftAssets.avatarUploadIcon,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 21,
                              height: 21,
                              decoration: BoxDecoration(
                                color: ThaliaColors.emeraldBright,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: palette.card,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                reg.hasProfilePhoto
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto Profil',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            reg.profileImageName ?? 'JPG / PNG, maks. 2 MB',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.loginInputFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        reg.hasProfilePhoto ? 'Ganti' : 'Unggah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Form Input dengan placeholder sesuai permintaan user
          StaggeredEntrance(
            delayMs: 120,
            child: AuthInputField(
              label: 'Nama Lengkap',
              palette: palette,
              hintText: 'Masukin nama lengkap',
              initialValue: reg.fullName,
              useCardSurface: true,
              onChanged: controller.updateRegisterName,
            ),
          ),
          const SizedBox(height: 12),

          StaggeredEntrance(
            delayMs: 160,
            child: AuthInputField(
              label: 'Alamat Email',
              palette: palette,
              hintText: 'Email',
              initialValue: reg.email,
              useCardSurface: true,
              keyboardType: TextInputType.emailAddress,
              onChanged: controller.updateRegisterEmail,
            ),
          ),
          const SizedBox(height: 12),

          StaggeredEntrance(
            delayMs: 200,
            child: AuthInputField(
              label: 'Kata Sandi',
              palette: palette,
              hintText: '',
              initialValue: reg.password,
              useCardSurface: true,
              isPassword: true,
              obscureText: reg.obscurePassword,
              onToggleVisibility: controller.toggleRegisterPasswordVisibility,
              onChanged: controller.updateRegisterPassword,
            ),
          ),
          const SizedBox(height: 12),

          StaggeredEntrance(
            delayMs: 240,
            child: AuthInputField(
              label: 'Konfirmasi Kata Sandi',
              palette: palette,
              hintText: '',
              initialValue: reg.confirmPassword,
              useCardSurface: true,
              isPassword: true,
              obscureText: reg.obscureConfirmPassword,
              onToggleVisibility: controller.toggleRegisterConfirmVisibility,
              onChanged: controller.updateRegisterConfirmPassword,
            ),
          ),
          const SizedBox(height: 14),

          // 5. Box Lokasi warna putih bersih sesuai Screenshot 6 (tidak terpotong)
          StaggeredEntrance(
            delayMs: 280,
            child: TactilePressable(
              onTap: () =>
                  controller.navigateTo(AuthScreenStep.locationAccess),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: palette.cardBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Lokasi: ${reg.detectedLocation}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.only(bottom: 1.5),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: palette.isDark
                                ? palette.textPrimary
                                : ThaliaColors.navyDeep,
                            width: 1.3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Tambah Lokasi →',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: palette.isDark
                              ? palette.textPrimary
                              : ThaliaColors.navyDeep,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 6. Checkbox Syarat & Kebijakan THALIA
          StaggeredEntrance(
            delayMs: 310,
            child: TactilePressable(
              onTap: controller.toggleTermsAgreed,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: reg.agreedToTerms
                          ? ThaliaColors.emeraldBright
                          : palette.card,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: ThaliaColors.emeraldBright,
                        width: 1.5,
                      ),
                    ),
                    child: reg.agreedToTerms
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saya menyetujui Syarat & Kebijakan THALIA',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 7. Tombol Daftar Sekarang ->
          StaggeredEntrance(
            delayMs: 340,
            child: PrimaryAuthButton(
              label: 'Daftar Sekarang',
              showArrow: true,
              palette: palette,
              onTap: () => controller.navigateTo(AuthScreenStep.login),
            ),
          ),
          const SizedBox(height: 16),

          // 8. Link Sudah punya akun? Masuk
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.textSecondary,
                ),
              ),
              TactilePressable(
                onTap: () => controller.navigateTo(AuthScreenStep.login),
                child: Text(
                  'Masuk',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
