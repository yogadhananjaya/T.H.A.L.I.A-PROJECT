import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/api_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'models/api_models.dart';
import 'models/auth_models.dart';
import 'screens/auth_flow_shell.dart';
import 'screens/splash_screen.dart';
import 'services/alert_notification_service.dart';
import 'services/thalia_services.dart';
import 'theme/app_theme.dart';
import 'utils/privacy_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary agar error tak terduga tercatat aman tanpa membocorkan PII/token.
  FlutterError.onError = (details) {
    debugPrint('[THALIA][FlutterError] ${PrivacyGuard.sanitizeErrorMessage(details.exception)}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[THALIA][AsyncError] ${PrivacyGuard.sanitizeErrorMessage(error)}');
    return true;
  };
  // Kunci orientasi potret agar preview kamera & layout dashboard tetap konsisten (B33).
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  // Batasi cache gambar di memori agar aplikasi ringan dan tidak membengkak di penyimpanan/RAM.
  PaintingBinding.instance.imageCache.maximumSize = 40;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 15 << 20; // 15 MB

  final prefs = await AuthController.loadInitialPrefs();
  runApp(
    ThaliaApp(
      hasSeenWelcome: prefs.hasSeenWelcome,
      initialTheme: prefs.theme,
      initialFollowSystem: prefs.followSystem,
      initialSession: prefs.session,
    ),
  );
}

class ThaliaApp extends StatefulWidget {
  const ThaliaApp({
    super.key,
    this.hasSeenWelcome = false,
    this.initialTheme = ThemeOption.light,
    this.initialFollowSystem = false,
    this.initialSession,
    this.services,
    this.showSplash = true,
  });

  final bool hasSeenWelcome;
  final ThemeOption initialTheme;
  final bool initialFollowSystem;
  final AuthSession? initialSession;

  /// Kosong = dipilih otomatis dari ApiConfig (data contoh atau server sungguhan).
  final ThaliaServices? services;

  /// Menentukan apakah Splash Screen animasi pembuka ditampilkan saat startup.
  final bool showSplash;

  @override
  State<ThaliaApp> createState() => _ThaliaAppState();
}

class _ThaliaAppState extends State<ThaliaApp> {
  late bool _showingSplash = widget.showSplash;
  late final ThaliaServices _services =
      widget.services ?? ThaliaServices.fromConfig();
  late final AuthController _authController = AuthController(
    hasSeenWelcome: widget.hasSeenWelcome,
    authService: _services.auth,
  );
  late final DashboardController _dashboardController =
      DashboardController(api: _services.api);
  late final AlertNotificationService _alertService =
      AlertNotificationService(apiClient: _services.apiClient);

  AuthScreenStep? _lastStep;
  bool _hasEnteredDashboardSession = false;
  double? _loadedLat;
  double? _loadedLng;
  Timer? _coordinateDebounce;

  @override
  void initState() {
    super.initState();
    _services.apiClient?.onUnauthorized = _authController.handleUnauthorized;
    if (widget.initialSession != null) {
      _services.apiClient?.accessToken = widget.initialSession!.accessToken;
    }
    _authController.applyInitialPrefs(
      theme: widget.initialTheme,
      followSystem: widget.initialFollowSystem,
      session: widget.initialSession,
    );
    _lastStep = _authController.currentStep;
    _authController.addListener(_onAuthChanged);
    _alertService.onAlertReceived = _dashboardController.setEmergencyAlert;
    _alertService.initialize();
    if (_authController.currentStep == AuthScreenStep.dashboard) {
      _onAuthChanged();
    }
  }

  /// Memuat data dashboard saat pertama masuk sesi, debounce saat koordinat digeser,
  /// dan reset dashboard saat logout (B08, B11, B12).
  void _onAuthChanged() {
    final step = _authController.currentStep;
    final gps = _authController.gpsModel;
    final inDashboard = step == AuthScreenStep.dashboard;
    final isAuthenticatedArea =
        inDashboard || step == AuthScreenStep.settings;

    if (!isAuthenticatedArea && _hasEnteredDashboardSession) {
      _hasEnteredDashboardSession = false;
      _loadedLat = null;
      _loadedLng = null;
      _coordinateDebounce?.cancel();
      _alertService.stopBackupPolling();
      _dashboardController.reset();
    }

    final justLoggedIn =
        inDashboard && !_hasEnteredDashboardSession && _lastStep != AuthScreenStep.settings;
    final moved = inDashboard &&
        (gps.latitude != _loadedLat || gps.longitude != _loadedLng);
    _lastStep = step;

    if (justLoggedIn) {
      _hasEnteredDashboardSession = true;
      _loadedLat = gps.latitude;
      _loadedLng = gps.longitude;
      _coordinateDebounce?.cancel();
      _alertService.startBackupPolling();
      _dashboardController.loadDashboardData(
        latitude: gps.latitude,
        longitude: gps.longitude,
      );
      if (widget.services == null && !ApiConfig.useMockData) {
        _dashboardController.startLiveSync();
      }
    } else if (moved) {
      _hasEnteredDashboardSession = true;
      _loadedLat = gps.latitude;
      _loadedLng = gps.longitude;
      _coordinateDebounce?.cancel();
      _coordinateDebounce = Timer(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        _dashboardController.loadDashboardData(
          latitude: gps.latitude,
          longitude: gps.longitude,
        );
      });
    }
  }

  @override
  void dispose() {
    _coordinateDebounce?.cancel();
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _dashboardController.dispose();
    _alertService.dispose();
    _services.apiClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stableShell = AuthFlowShell(
      controller: _authController,
      dashboardController: _dashboardController,
    );

    return AnimatedBuilder(
      animation: _authController,
      builder: (context, child) {
        final mode = _authController.followSystemTheme
            ? ThemeMode.system
            : (_authController.isDarkMode ? ThemeMode.dark : ThemeMode.light);
        return MaterialApp(
          title: 'T.H.A.L.I.A',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.build(isDark: false),
          darkTheme: AppTheme.build(isDark: true),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            child: _showingSplash
                ? SplashScreen(
                    key: const ValueKey('splash'),
                    onCompleted: () {
                      if (mounted) {
                        setState(() => _showingSplash = false);
                      }
                    },
                  )
                : KeyedSubtree(
                    key: const ValueKey('app-shell'),
                    child: child!,
                  ),
          ),
        );
      },
      child: stableShell,
    );
  }
}
