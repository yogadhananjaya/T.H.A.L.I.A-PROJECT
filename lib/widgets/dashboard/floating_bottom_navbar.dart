import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../tactile_interaction.dart';

/// Bottom Navigation Bar mengambang dengan tombol tengah Kamera Squircle
/// sesuai desain login_ui.figcraft.
class FloatingBottomNavbar extends StatelessWidget {
  const FloatingBottomNavbar({
    super.key,
    required this.activeTab,
    required this.climate,
    required this.onSelectTab,
  });

  final DashboardTab activeTab;
  final ClimatePalette climate;
  final ValueChanged<DashboardTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final isCameraActive = activeTab == DashboardTab.camera;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: 86,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Dock Putih Utama
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: climate.surfaceWhite,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: climate.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: climate.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavTabButton(
                    tab: DashboardTab.home,
                    icon: Icons.home_outlined,
                    isActive: activeTab == DashboardTab.home,
                    climate: climate,
                    onTap: () => onSelectTab(DashboardTab.home),
                  ),
                  _NavTabButton(
                    tab: DashboardTab.maps,
                    icon: Icons.map_outlined,
                    isActive: activeTab == DashboardTab.maps,
                    climate: climate,
                    onTap: () => onSelectTab(DashboardTab.maps),
                  ),
                  const SizedBox(width: 64),
                  _NavTabButton(
                    tab: DashboardTab.history,
                    icon: Icons.description_outlined,
                    isActive: activeTab == DashboardTab.history,
                    climate: climate,
                    onTap: () => onSelectTab(DashboardTab.history),
                  ),
                  _NavTabButton(
                    tab: DashboardTab.calendar,
                    icon: Icons.calendar_today_outlined,
                    isActive: activeTab == DashboardTab.calendar,
                    climate: climate,
                    onTap: () => onSelectTab(DashboardTab.calendar),
                  ),
                ],
              ),
            ),

            // Tombol Kamera Squircle Tengah yang Menonjol ke Atas
            Positioned(
              top: 0,
              child: TactilePressable(
                onTap: () => onSelectTab(DashboardTab.camera),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: climate.canvas,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: climate.border, width: 1.2),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: isCameraActive
                              ? climate.primaryBrand
                              : climate.activeForecastBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 23,
                              color: Colors.white,
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: climate.warmDot,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kamera',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isCameraActive
                            ? climate.primaryBrand
                            : climate.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.tab,
    required this.icon,
    required this.isActive,
    required this.climate,
    required this.onTap,
  });

  final DashboardTab tab;
  final IconData icon;
  final bool isActive;
  final ClimatePalette climate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                color: isActive ? climate.pillFill : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 19,
                color: isActive ? climate.primaryBrand : climate.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? climate.primaryDark : climate.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
