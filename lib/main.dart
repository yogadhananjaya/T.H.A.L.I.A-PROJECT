import 'dart:io';
import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'models/auth_models.dart';
import 'screens/auth_flow_shell.dart';
import 'services/thalia_services.dart';
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
  const ThaliaApp({super.key, this.hasSeenWelcome = false, this.services});

  final bool hasSeenWelcome;

  /// Kosong = dipilih otomatis dari ApiConfig (data contoh atau server sungguhan).
  final ThaliaServices? services;

  @override
  State<ThaliaApp> createState() => _ThaliaAppState();
}

class _ThaliaAppState extends State<ThaliaApp> {
  late final ThaliaServices _services =
      widget.services ?? ThaliaServices.fromConfig();
  late final AuthController _authController = AuthController(
    hasSeenWelcome: widget.hasSeenWelcome,
    authService: _services.auth,
  );
  late final DashboardController _dashboardController =
      DashboardController(api: _services.api);

  AuthScreenStep? _lastStep;
  double? _loadedLat;
  double? _loadedLng;

  @override
  void initState() {
    super.initState();
    _lastStep = _authController.currentStep;
    _authController.addListener(_onAuthChanged);
  }

  /// Memuat data dashboard saat pengguna masuk, dan memuat ulang bila lokasi berubah.
  void _onAuthChanged() {
    final step = _authController.currentStep;
    final gps = _authController.gpsModel;
    final inDashboard = step == AuthScreenStep.dashboard;
    final justEntered = inDashboard && _lastStep != AuthScreenStep.dashboard;
    final moved = inDashboard &&
        (gps.latitude != _loadedLat || gps.longitude != _loadedLng);
    _lastStep = step;

    if (justEntered || moved) {
      _loadedLat = gps.latitude;
      _loadedLng = gps.longitude;
      _dashboardController.loadDashboardData(
        latitude: gps.latitude,
        longitude: gps.longitude,
      );
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
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
