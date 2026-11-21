import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/lens_photo_report_sheet.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 3: Kamera Lapangan (Frame 275 login_ui.figcraft)
/// - Preview kamera belakang langsung tampil di dalam kartu viewfinder (package `camera`).
/// - Tombol shutter langsung memotret, lalu layar Google Lens muncul dan form laporan
///   naik dari bawah (peek), tinggal ditarik ke atas untuk mengisi.
/// - Tombol galeri tetap memakai image_picker; bila kamera gagal dibuka, shutter
///   jatuh kembali ke kamera bawaan sistem.
class CameraTabScreen extends StatefulWidget {
  const CameraTabScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
    required this.climate,
  });

  final DashboardController dashboardController;
  final AuthController authController;
  final ClimatePalette climate;

  @override
  State<CameraTabScreen> createState() => _CameraTabScreenState();
}

class _CameraTabScreenState extends State<CameraTabScreen>
    with WidgetsBindingObserver {
  CameraController? _cam;
  String? _cameraMessage;
  bool _permissionPermanentlyDenied = false;
  bool _requestingPermission = false;
  bool _capturing = false;
  bool _lastShowLens = false;
  int _initToken = 0;

  DashboardController get _dash => widget.dashboardController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastShowLens = _dash.showLensReportSheet;
    _dash.addListener(_onDashChanged);
    if (!_lastShowLens) _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dash.removeListener(_onDashChanged);
    _initToken++;
    final c = _cam;
    _cam = null;
    c?.dispose();
    super.dispose();
  }

  /// Kamera dimatikan saat layar Lens tampil (hemat baterai) dan dinyalakan lagi
  /// ketika pengguna menekan "Ambil Ulang".
  void _onDashChanged() {
    final showLens = _dash.showLensReportSheet;
    if (showLens == _lastShowLens) return;
    _lastShowLens = showLens;
    if (showLens) {
      _stopCamera();
    } else {
      _startCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_dash.showLensReportSheet || _requestingPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cam == null) _startCamera();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopCamera();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _stopCamera() {
    _initToken++;
    final c = _cam;
    _cam = null;
    if (mounted) setState(() {});
    if (c != null) {
      // Dilepas setelah frame berikutnya supaya CameraPreview sudah keluar dari tree.
      WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
    }
  }

  Future<void> _startCamera() async {
    if (_cam != null) return;
    final token = ++_initToken;
    if (mounted) setState(() => _cameraMessage = null);

    try {
      _requestingPermission = true;
      final status = await Permission.camera.request();
      _requestingPermission = false;
      if (!mounted || token != _initToken) return;

      if (!status.isGranted) {
        setState(() {
          _permissionPermanentlyDenied = status.isPermanentlyDenied;
          _cameraMessage = status.isPermanentlyDenied
              ? 'Izin kamera ditolak. Aktifkan lewat Pengaturan aplikasi.'
              : 'Izin kamera dibutuhkan untuk memotret kondisi lapangan.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (!mounted || token != _initToken) return;
      if (cameras.isEmpty) {
        setState(() => _cameraMessage = 'Kamera tidak ditemukan di perangkat ini.');
        return;
      }

      final description = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted || token != _initToken) {
        await controller.dispose();
        return;
      }
      await _applyFlash(controller);
      setState(() => _cam = controller);
    } on CameraException catch (e) {
      _requestingPermission = false;
      if (!mounted || token != _initToken) return;
      setState(() {
        _cameraMessage = e.code.startsWith('CameraAccessDenied')
            ? 'Izin kamera ditolak. Aktifkan lewat Pengaturan aplikasi.'
            : 'Kamera gagal dibuka (${e.code}).';
        _permissionPermanentlyDenied = e.code.startsWith('CameraAccessDenied');
      });
    } catch (_) {
      _requestingPermission = false;
      if (!mounted || token != _initToken) return;
      setState(() => _cameraMessage = 'Kamera gagal dibuka. Coba lagi.');
    }
  }

  Future<void> _applyFlash(CameraController c) async {
    final mode = switch (_dash.flashMode) {
      'On' => FlashMode.always,
      'Off' => FlashMode.off,
      _ => FlashMode.auto,
    };
    try {
      await c.setFlashMode(mode);
    } catch (_) {}
  }

  void _onFlashTap() {
    _dash.cycleFlashMode();
    final c = _cam;
    if (c != null) _applyFlash(c);
  }

  Future<void> _onShutterTap() async {
    final c = _cam;
    if (c == null || !c.value.isInitialized) {
      // Kamera belum siap: abaikan bila masih memuat, pakai kamera sistem bila gagal.
      if (_cameraMessage != null) {
        await _dash.captureOrPickFieldPhoto(source: ImageSource.camera);
      }
      return;
    }
    if (_capturing || c.value.isTakingPicture) return;

    setState(() => _capturing = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      try {
        await File(file.path).delete();
      } catch (_) {}
      if (!mounted) return;
      _dash.setCapturedPhotoFromCamera(bytes);
    } catch (_) {
      if (mounted) {
        setState(() => _cameraMessage = 'Gagal mengambil foto. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _onRetryPermission() async {
    if (_permissionPermanentlyDenied) {
      await openAppSettings();
    } else {
      _startCamera();
    }
  }

  Widget _buildCameraLayer() {
    final c = _cam;
    if (c != null && c.value.isInitialized) {
      final size = c.value.previewSize;
      if (size != null) {
        // previewSize berorientasi landscape, ditukar agar pas dengan layar portrait.
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.height,
              height: size.width,
              child: CameraPreview(c),
            ),
          ),
        );
      }
      return CameraPreview(c);
    }
    return CustomPaint(
      painter: _CameraViewfinderPainter(
        climate: widget.climate,
        drawIllustration: true,
        drawBrackets: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final gps = widget.authController.gpsModel;
    final dash = _dash;
    final shortArea = gps.resolvedAddress.split(',').first.trim();
    final coordText =
        '${gps.latitude.toStringAsFixed(2)}, ${gps.longitude.toStringAsFixed(2)}';

    // Mode Google Lens setelah foto diambil / dipilih dari galeri
    if (dash.showLensReportSheet) {
      return LensPhotoReportSheet(
        controller: dash,
        climate: climate,
        locationName: gps.resolvedAddress,
        gpsCoordText: coordText,
      );
    }

    final cameraReady = _cam != null && _cam!.value.isInitialized;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Dokumentasi Cuaca & Lingkungan',
            titleText: 'Kamera Lapangan',
            onTapProfile: dash.openProfile,
          ),
          StaggeredEntrance(
            delayMs: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
              child: Container(
                width: double.infinity,
                height: 492,
                decoration: BoxDecoration(
                  color: climate.activeForecastBg,
                  borderRadius: BorderRadius.circular(26),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // 1. Preview kamera langsung (atau ilustrasi saat kamera belum siap)
                    Positioned.fill(child: _buildCameraLayer()),

                    // 1b. Empat siku putih [ ] di atas preview
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CameraViewfinderPainter(
                            climate: climate,
                            drawIllustration: false,
                            drawBrackets: true,
                          ),
                        ),
                      ),
                    ),

                    // 1c. Status: memuat kamera / pesan izin & error
                    if (!cameraReady)
                      Positioned.fill(
                        child: Align(
                          alignment: const Alignment(0, -0.12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: _cameraMessage == null
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                      color: Colors.white,
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _cameraMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TactilePressable(
                                        onTap: _onRetryPermission,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 9,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            _permissionPermanentlyDenied
                                                ? 'Buka Pengaturan'
                                                : 'Coba Lagi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: climate.activeForecastBg,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                    // 2. Bar Atas Viewfinder: Flash & lokasi
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TactilePressable(
                            onTap: _onFlashTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                'Flash: ${dash.flashMode}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              '$shortArea • ${_dash.formattedCaptureTime}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Teks Instruksi & Tombol Galeri + Shutter Kamera di Bawah
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        children: [
                          Text(
                            'Arahkan ke lokasi • Ketuk tombol kamera',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              shadows: const [
                                Shadow(blurRadius: 6, color: Colors.black54),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 76,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Tombol Pilih dari Galeri / File Manager
                                Align(
                                  alignment: const Alignment(-0.68, 0),
                                  child: TactilePressable(
                                    onTap: () => dash.captureOrPickFieldPhoto(
                                      source: ImageSource.gallery,
                                    ),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: climate.primaryBrand.withValues(
                                          alpha: 0.55,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.6,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(
                                            Icons.landscape_rounded,
                                            size: 22,
                                            color: Colors.white,
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: climate.warmDot,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Tombol Shutter: memotret langsung dari preview
                                Opacity(
                                  opacity: _capturing ? 0.55 : 1,
                                  child: TactilePressable(
                                    onTap: _onShutterTap,
                                    child: Container(
                                      width: 74,
                                      height: 74,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          width: 2.2,
                                        ),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 26,
                                          color: climate.activeForecastBg,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraViewfinderPainter extends CustomPainter {
  const _CameraViewfinderPainter({
    required this.climate,
    required this.drawIllustration,
    required this.drawBrackets,
  });

  final ClimatePalette climate;
  final bool drawIllustration;
  final bool drawBrackets;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawIllustration) {
      canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.30),
        23,
        Paint()..color = climate.warmDot,
      );
      canvas.drawOval(
        Rect.fromLTWH(-40, size.height * 0.42, size.width * 0.88, 190),
        Paint()..color = climate.primaryBrand.withValues(alpha: 0.48),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.12),
        Paint()..color = climate.primaryBrand.withValues(alpha: 0.58),
      );
      canvas.drawLine(
        Offset(22, size.height * 0.62),
        Offset(size.width - 22, size.height * 0.62),
        Paint()
          ..color = climate.warmDot
          ..strokeWidth = 2.0,
      );
    }

    if (!drawBrackets) return;

    final bracketPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final l = size.width * 0.16;
    final r = size.width * 0.84;
    final t = size.height * 0.20;
    final b = size.height * 0.65;
    const len = 28.0;
    const rad = 12.0;

    canvas.drawPath(
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + rad)
        ..quadraticBezierTo(l, t, l + rad, t)
        ..lineTo(l + len, t),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r - len, t)
        ..lineTo(r - rad, t)
        ..quadraticBezierTo(r, t, r, t + rad)
        ..lineTo(r, t + len),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l, b - len)
        ..lineTo(l, b - rad)
        ..quadraticBezierTo(l, b, l + rad, b)
        ..lineTo(l + len, b),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r - len, b)
        ..lineTo(r - rad, b)
        ..quadraticBezierTo(r, b, r, b - rad)
        ..lineTo(r, b - len),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CameraViewfinderPainter oldDelegate) =>
      oldDelegate.drawIllustration != drawIllustration ||
      oldDelegate.drawBrackets != drawBrackets ||
      oldDelegate.climate.season != climate.season;
}
