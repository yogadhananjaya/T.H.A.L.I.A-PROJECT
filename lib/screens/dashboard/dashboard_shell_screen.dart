import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/floating_bottom_navbar.dart';
import 'calendar_tab_screen.dart';
import 'camera_tab_screen.dart';
import 'history_tab_screen.dart';
import 'home_tab_screen.dart';
import 'maps_tab_screen.dart';
import 'profile_screen.dart';

/// Shell OOP Dashboard yang menyatukan 5 Tab (Home, Maps, Kamera, Riwayat, Kalender) + Profil Saya.
/// Memakai [IndexedStack] agar posisi peta & scroll tidak hilang saat berpindah tab (B34).
class DashboardShellScreen extends StatelessWidget {
  const DashboardShellScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
  });

  final DashboardController dashboardController;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dashboardController,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final climate = ClimatePalette(
          season: dashboardController.seasonMode,
          isDark: isDark,
        );
        final activeTab = dashboardController.activeTab;
        final hideNavbar = activeTab == DashboardTab.camera &&
            dashboardController.showLensReportSheet &&
            !dashboardController.showingProfile;

        return ColoredBox(
          color: climate.canvas,
          child: Column(
            children: [
              Expanded(
                child: dashboardController.showingProfile
                    ? ProfileScreen(
                        key: const ValueKey('profile'),
                        dashboardController: dashboardController,
                        authController: authController,
                        climate: climate,
                      )
                    : IndexedStack(
                        index: activeTab.index,
                        children: [
                          HomeTabScreen(
                            key: const ValueKey('tab_home'),
                            controller: dashboardController,
                            climate: climate,
                            locationName: authController.gpsModel.resolvedAddress,
                          ),
                          MapsTabScreen(
                            key: const ValueKey('tab_maps'),
                            dashboardController: dashboardController,
                            authController: authController,
                            climate: climate,
                          ),
                          // Kamera hanya diinisialisasi saat tab Kamera aktif (B34).
                          activeTab == DashboardTab.camera
                              ? CameraTabScreen(
                                  key: const ValueKey('tab_camera'),
                                  dashboardController: dashboardController,
                                  authController: authController,
                                  climate: climate,
                                )
                              : const SizedBox.shrink(),
                          HistoryTabScreen(
                            key: const ValueKey('tab_history'),
                            controller: dashboardController,
                            climate: climate,
                            isStaffVerifier:
                                authController.activeSession?.isStaffVerifier ??
                                    false,
                          ),
                          CalendarTabScreen(
                            key: const ValueKey('tab_calendar'),
                            controller: dashboardController,
                            climate: climate,
                          ),
                        ],
                      ),
              ),
              if (!hideNavbar)
                FloatingBottomNavbar(
                  activeTab: activeTab,
                  climate: climate,
                  onSelectTab: dashboardController.selectTab,
                ),
            ],
          ),
        );
      },
    );
  }
}
