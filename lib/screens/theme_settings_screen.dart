import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/figcraft_assets.dart';
import '../widgets/tactile_interaction.dart';

/// Layar 2 pada Frame 2 LOGIN.figcraft: "Pengaturan" (Tema Tampilan Terang/Gelap).
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final AuthController controller;
  final ThaliaPalette palette;

  @override
  Widget build(BuildContext context) {
    final selected = controller.themeOption;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Back ke Profil/Dashboard + Judul "Pengaturan"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TactilePressable(
                onTap: () => controller.navigateTo(AuthScreenStep.dashboard),
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
              Text(
                'Pengaturan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 28),

          // 2. Label Section: TEMA TAMPILAN
          Text(
            'TEMA TAMPILAN',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // 3. Kartu Pemilih Tema (Terang vs Gelap + Switch Ikuti Tema Sistem)
          StaggeredEntrance(
            delayMs: 60,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeOptionCard(
                          title: 'Terang',
                          subtitle: selected == ThemeOption.light
                              ? 'Dipilih'
                              : 'Mode terang',
                          assetPath: FigcraftAssets.themeLightCard,
                          isSelected: selected == ThemeOption.light,
                          palette: palette,
                          onTap: () =>
                              controller.selectThemeOption(ThemeOption.light),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeOptionCard(
                          title: 'Gelap',
                          subtitle: selected == ThemeOption.dark
                              ? 'Dipilih'
                              : 'Mode malam',
                          assetPath: FigcraftAssets.themeDarkCard,
                          isSelected: selected == ThemeOption.dark,
                          palette: palette,
                          onTap: () =>
                              controller.selectThemeOption(ThemeOption.dark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: palette.cardBorder, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ikuti Tema Sistem',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Otomatis ikut pengaturan HP',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: controller.followSystemTheme,
                        activeTrackColor: ThaliaColors.emeraldBright,
                        onChanged: controller.toggleFollowSystemTheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120),

          // 4. Footer Identitas Aplikasi THALIA (dengan data versi '--')
          Divider(color: palette.cardBorder, height: 1),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Image.asset(
                  FigcraftAssets.shieldLogo,
                  width: 38,
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'THALIA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi -- • Tri-Habitat Analysis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Build -- • Stabil',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textSecondary.withValues(alpha: 0.75),
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

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String assetPath;
  final bool isSelected;
  final ThaliaPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? ThaliaColors.emeraldBright.withValues(alpha: 0.08)
              : palette.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? ThaliaColors.emeraldBright : palette.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                assetPath,
                height: 104,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? ThaliaColors.emeraldPrimary
                            : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThaliaColors.emeraldBright
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: isSelected
                          ? ThaliaColors.emeraldBright
                          : palette.cardBorder,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
