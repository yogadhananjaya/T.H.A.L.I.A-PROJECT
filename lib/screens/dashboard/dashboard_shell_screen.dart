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
/// Menggunakan StackFit.expand tanpa membungkus ulang currentChild sehingga animasi masuk
/// hanya jalan 1 kali dengan mulus dan semua tab menempel penuh dari puncak layar (y = 0).
class DashboardShellScreen extends StatelessWidget {
  const DashboardShellScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
  });

  final DashboardController dashboardController;
  final AuthController authController;

  Widget _buildTabContent(ClimatePalette climate) {
    if (dashboardController.showingProfile) {
      return ProfileScreen(
        key: const ValueKey('profile'),
        dashboardController: dashboardController,
        authController: authController,
        climate: climate,
      );
    }

    switch (dashboardController.activeTab) {
      case DashboardTab.home:
        return HomeTabScreen(
          key: const ValueKey('tab_home'),
          controller: dashboardController,
          climate: climate,
          locationName: authController.gpsModel.resolvedAddress,
        );
      case DashboardTab.maps:
        return MapsTabScreen(
          key: const ValueKey('tab_maps'),
          dashboardController: dashboardController,
          authController: authController,
          climate: climate,
        );
      case DashboardTab.camera:
        return CameraTabScreen(
          key: const ValueKey('tab_camera'),
          dashboardController: dashboardController,
          authController: authController,
          climate: climate,
        );
      case DashboardTab.history:
        return HistoryTabScreen(
          key: const ValueKey('tab_history'),
          controller: dashboardController,
          climate: climate,
        );
      case DashboardTab.calendar:
        return CalendarTabScreen(
          key: const ValueKey('tab_calendar'),
          controller: dashboardController,
          climate: climate,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dashboardController,
      builder: (context, _) {
        final climate = ClimatePalette(
          season: dashboardController.seasonMode,
          isDark: authController.isDarkMode,
        );
        final hideNavbar =
            dashboardController.activeTab == DashboardTab.camera &&
                dashboardController.showLensReportSheet &&
                !dashboardController.showingProfile;

        return ColoredBox(
          color: climate.canvas,
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      fit: StackFit.expand,
                      children: <Widget>[
                        ...previousChildren,
                        ?currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _buildTabContent(climate),
                ),
              ),
              if (!hideNavbar)
                FloatingBottomNavbar(
                  activeTab: dashboardController.activeTab,
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
