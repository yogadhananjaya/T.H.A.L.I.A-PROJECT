import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'screens/auth_flow_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ThaliaApp());
}

class ThaliaApp extends StatefulWidget {
  const ThaliaApp({super.key});

  @override
  State<ThaliaApp> createState() => _ThaliaAppState();
}

class _ThaliaAppState extends State<ThaliaApp> {
  final AuthController _authController = AuthController();
  final DashboardController _dashboardController = DashboardController();

  @override
  void dispose() {
    _authController.dispose();
    _dashboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_authController, _dashboardController]),
      builder: (context, _) {
        return MaterialApp(
          title: 'T.H.A.L.I.A',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(isDark: _authController.isDarkMode),
          home: AuthFlowShell(
            controller: _authController,
            dashboardController: _dashboardController,
          ),
        );
      },
    );
  }
}
