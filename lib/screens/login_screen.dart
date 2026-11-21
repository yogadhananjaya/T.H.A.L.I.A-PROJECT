import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_action_buttons.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/login_wave_banner.dart';
import '../widgets/session_options_row.dart';
import '../widgets/tactile_interaction.dart';
import '../widgets/thalia_brand_header.dart';

/// Halaman Masuk Akun (Login) sesuai Frame 2 kiri pada LOGIN.figcraft.
/// Konsisten dengan tab Daftar Akun Baru (placeholder 'Email' dan sandi kosong '').
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final AuthController controller;
  final ThaliaPalette palette;

  void _showResetPasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Sandi Otentikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan email terdaftar untuk menerima tautan pemulihan sandi.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              AuthInputField(
                label: 'Email / ID Petugas Resmi',
                palette: palette,
                hintText: 'Email',
                showStatusDot: true,
              ),
              const SizedBox(height: 18),
              PrimaryAuthButton(
                label: 'Kirim Tautan Reset',
                palette: palette,
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = controller.loginModel;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Gelombang Tri-Habitat menempel penuh di puncak layar
          const LoginWaveBanner(),

          // 2. Konten Form Masuk Akun
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaggeredEntrance(
                  delayMs: 40,
                  child: ThaliaBrandHeader(palette: palette),
                ),
                const SizedBox(height: 28),

                // Input Email / ID Petugas Resmi (konsisten dengan tab lain)
                StaggeredEntrance(
                  delayMs: 100,
                  child: AuthInputField(
                    label: 'Email / ID Petugas Resmi',
                    palette: palette,
                    hintText: 'Email',
                    initialValue: login.emailOrOfficerId,
                    onChanged: controller.updateLoginEmail,
                    showStatusDot: true,
                    useCardSurface: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 18),

                // Input Kata Sandi Otentikasi (kosong tanpa '--' sesuai permintaan user)
                StaggeredEntrance(
                  delayMs: 160,
                  child: AuthInputField(
                    label: 'Kata Sandi Otentikasi',
                    palette: palette,
                    hintText: '',
                    initialValue: login.password,
                    onChanged: controller.updateLoginPassword,
                    isPassword: true,
                    obscureText: login.obscurePassword,
                    useCardSurface: true,
                    onToggleVisibility:
                        controller.toggleLoginPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 18),

                // Checkbox Simpan Sesi Perangkat & Reset Sandi?
                StaggeredEntrance(
                  delayMs: 210,
                  child: SessionOptionsRow(
                    palette: palette,
                    rememberSession: login.rememberDeviceSession,
                    onToggleRemember: controller.toggleRememberSession,
                    onTapResetPassword: () => _showResetPasswordSheet(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Banner feedback interaktif bila tombol ditekan
                if (controller.feedbackBanner != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: controller.feedbackIsError
                          ? const Color(0xFFFEF2F2)
                          : ThaliaColors.mintBannerFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.feedbackIsError
                            ? const Color(0xFFEF4444)
                            : ThaliaColors.emeraldPrimary,
                      ),
                    ),
                    child: Text(
                      controller.feedbackBanner!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: controller.feedbackIsError
                            ? const Color(0xFFB91C1C)
                            : ThaliaColors.forestDark,
                      ),
                    ),
                  ),
                ],

                // Tombol Utama: Masuk ke Dashboard
                StaggeredEntrance(
                  delayMs: 260,
                  child: PrimaryAuthButton(
                    label: 'Masuk ke Dashboard',
                    palette: palette,
                    isLoading: controller.isSubmitting,
                    onTap: controller.submitLogin,
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol Sekunder: Daftar Akun Baru
                StaggeredEntrance(
                  delayMs: 310,
                  child: SecondaryAuthButton(
                    label: 'Daftar Akun Baru',
                    palette: palette,
                    onTap: () =>
                        controller.navigateTo(AuthScreenStep.register),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
