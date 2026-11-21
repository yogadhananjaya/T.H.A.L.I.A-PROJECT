import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/auth_models.dart';
import '../models/dashboard_models.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_shell_screen.dart';
import 'location_access_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'theme_settings_screen.dart';
import 'welcome_screen.dart';

/// Shell Navigasi OOP yang menghubungkan Auth Flow & Dashboard Flow.
/// Dilengkapi [PopScope] agar tombol Back Android bernavigasi antar layar (B05).
class AuthFlowShell extends StatelessWidget {
  const AuthFlowShell({
    super.key,
    required this.controller,
    required this.dashboardController,
  });

  final AuthController controller;
  final DashboardController dashboardController;

  Widget _buildActiveScreen(ThaliaPalette palette) {
    switch (controller.currentStep) {
      case AuthScreenStep.welcome:
        return SafeArea(
          key: const ValueKey('welcome'),
          child: WelcomeScreen(
            controller: controller,
            palette: palette,
          ),
        );
      case AuthScreenStep.login:
        return SafeArea(
          key: const ValueKey('login'),
          top: false,
          child: LoginScreen(
            controller: controller,
            palette: palette,
          ),
        );
      case AuthScreenStep.register:
        return SafeArea(
          key: const ValueKey('register'),
          child: RegisterScreen(
            controller: controller,
            palette: palette,
          ),
        );
      case AuthScreenStep.locationAccess:
        return SafeArea(
          key: const ValueKey('location'),
          child: LocationAccessScreen(
            controller: controller,
            palette: palette,
          ),
        );
      case AuthScreenStep.dashboard:
        return SafeArea(
          key: const ValueKey('dashboard'),
          top: false,
          child: DashboardShellScreen(
            dashboardController: dashboardController,
            authController: controller,
          ),
        );
      case AuthScreenStep.settings:
        return SafeArea(
          key: const ValueKey('settings'),
          child: ThemeSettingsScreen(
            controller: controller,
            palette: palette,
          ),
        );
    }
  }

  Future<void> _handleBackPressed(BuildContext context) async {
    switch (controller.currentStep) {
      case AuthScreenStep.register:
        controller.backFromRegister();
        return;
      case AuthScreenStep.locationAccess:
        controller.navigateTo(AuthScreenStep.register);
        return;
      case AuthScreenStep.settings:
        controller.navigateTo(AuthScreenStep.dashboard);
        return;
      case AuthScreenStep.dashboard:
        if (dashboardController.showingProfile) {
          dashboardController.closeProfile();
          return;
        }
        if (dashboardController.activeTab != DashboardTab.home) {
          dashboardController.selectTab(DashboardTab.home);
          return;
        }
        final exit = await _confirmExitDialog(context);
        if (exit == true) {
          await SystemNavigator.pop();
        }
        return;
      case AuthScreenStep.login:
      case AuthScreenStep.welcome:
        final exit = await _confirmExitDialog(context);
        if (exit == true) {
          await SystemNavigator.pop();
        }
        return;
    }
  }

  Future<bool?> _confirmExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari T.H.A.L.I.A?'),
        content: const Text(
          'Pemantauan cuaca & peringatan dini akan berhenti di layar utama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final palette = ThaliaPalette(isDark: isDark);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _handleBackPressed(context);
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
            child: Scaffold(
              backgroundColor: palette.canvas,
              body: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
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
                    child: _buildActiveScreen(palette),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
