import 'dart:io';
import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'screens/auth_flow_shell.dart';
import 'theme/app_theme.dart';

/// Mengizinkan koneksi HTTPS untuk tile Google Maps & API geocoding meskipun jam sistem/emulator berada di tahun 2026.
class _ThaliaHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _ThaliaHttpOverrides();
  // Batasi cache gambar di memori agar aplikasi ringan dan tidak membengkak di penyimpanan/RAM
  PaintingBinding.instance.imageCache.maximumSize = 40;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 15 << 20; // 15 MB
  final hasSeenWelcome = await AuthController.loadHasSeenWelcome();
  runApp(ThaliaApp(hasSeenWelcome: hasSeenWelcome));
}

class ThaliaApp extends StatefulWidget {
  const ThaliaApp({super.key, this.hasSeenWelcome = false});

  final bool hasSeenWelcome;

  @override
  State<ThaliaApp> createState() => _ThaliaAppState();
}

class _ThaliaAppState extends State<ThaliaApp> {
  late final AuthController _authController =
      AuthController(hasSeenWelcome: widget.hasSeenWelcome);
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
