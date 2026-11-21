import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_action_buttons.dart';
import '../widgets/shield_viewfinder_hero.dart';
import '../widgets/tactile_interaction.dart';

/// Layar 1 pada Frame 1 LOGIN.figcraft: "Selamat Datang" (Onboarding).
/// Menggunakan distribusi vertikal proporsional (top bar di atas, CTA di bawah) agar tidak menumpuk di tengah.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final AuthController controller;
  final ThaliaPalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Bagian Atas: Tri-Habitat 3-Segment Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: ThaliaColors.emeraldBright,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: ThaliaColors.skyWave,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: ThaliaColors.navyDeep,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Bagian Tengah: Viewfinder Hero Shield + Teks Selamat Datang
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        StaggeredEntrance(
                          delayMs: 40,
                          child: ShieldViewfinderHero(palette: palette),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: 38,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: ThaliaColors.emeraldBright,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 18),
                        StaggeredEntrance(
                          delayMs: 120,
                          child: Column(
                            children: [
                              Text(
                                'Selamat Datang',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.7,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pantau kondisi lingkungan dan cuaca\nsekitar Anda dengan tenang dan cepat.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Bagian Bawah: Tombol Mulai Sekarang, Link Masuk, & Indikator Halaman
                  Column(
                    children: [
                      StaggeredEntrance(
                        delayMs: 200,
                        child: PrimaryAuthButton(
                          label: 'Mulai Sekarang',
                          showArrow: true,
                          palette: palette,
                          onTap: () =>
                              controller.navigateTo(AuthScreenStep.register),
                        ),
                      ),
                      const SizedBox(height: 18),
                      StaggeredEntrance(
                        delayMs: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: palette.textSecondary,
                              ),
                            ),
                            TactilePressable(
                              onTap: () =>
                                  controller.navigateTo(AuthScreenStep.login),
                              child: Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 3,
                            decoration: BoxDecoration(
                              color: ThaliaColors.emeraldBright,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 3,
                            decoration: BoxDecoration(
                              color: palette.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 3,
                            decoration: BoxDecoration(
                              color: palette.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
