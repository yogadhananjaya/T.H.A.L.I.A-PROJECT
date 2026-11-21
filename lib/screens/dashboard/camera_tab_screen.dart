import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/lens_photo_report_sheet.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 3: Kamera Lapangan (Frame 275 login_ui.figcraft)
/// mendukung izin akses Kamera & Galeri lalu menampilkan pop-up form dari bawah ke atas (Frame 20).
class CameraTabScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final gps = authController.gpsModel;
    final shortArea = gps.resolvedAddress.split(',').first.trim();
    final coordText =
        '${gps.latitude.toStringAsFixed(2)}, ${gps.longitude.toStringAsFixed(2)}';

    // Ketika selesai ambil foto / pilih dari galeri, tampilkan pop-up form dari bawah ke atas
    // menutupi sebagian foto seperti Google Lens / Google Photos (Frame 20).
    if (dashboardController.showLensReportSheet) {
      return LensPhotoReportSheet(
        controller: dashboardController,
        climate: climate,
        locationName: gps.resolvedAddress,
        gpsCoordText: coordText,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Dokumentasi Cuaca & Lingkungan',
            titleText: 'Kamera Lapangan',
            onTapProfile: dashboardController.openProfile,
          ),
          Padding(
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
                  // 1. Ilustrasi Viewfinder Lapangan (Bukit, Matahari, Garis Horizon)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CameraViewfinderPainter(climate: climate),
                    ),
                  ),

                  // 2. Bar Atas Viewfinder: Flash: Auto & Cikarang • 09:41 WIB
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TactilePressable(
                          onTap: dashboardController.cycleFlashMode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Flash: ${dashboardController.flashMode}',
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
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            '$shortArea • 09:41 WIB',
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
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 76,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Tombol Pilih dari Galeri / File Manager (Kiri)
                              Align(
                                alignment: const Alignment(-0.68, 0),
                                child: TactilePressable(
                                  onTap: () => dashboardController
                                      .captureOrPickFieldPhoto(
                                    source: ImageSource.gallery,
                                  ),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: climate.primaryBrand.withValues(
                                        alpha: 0.45,
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

                              // Tombol Shutter Kamera Utama (Tengah)
                              TactilePressable(
                                onTap: () =>
                                    dashboardController.captureOrPickFieldPhoto(
                                  source: ImageSource.camera,
                                ),
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
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
        ],
      ),
    );
  }
}

class _CameraViewfinderPainter extends CustomPainter {
  const _CameraViewfinderPainter({required this.climate});
  final ClimatePalette climate;

  @override
  void paint(Canvas canvas, Size size) {
    // Matahari/bulan oranye di kanan atas viewfinder
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.30),
      23,
      Paint()..color = climate.warmDot,
    );

    // Siluet bukit biru
    canvas.drawOval(
      Rect.fromLTWH(-40, size.height * 0.42, size.width * 0.88, 190),
      Paint()..color = climate.primaryBrand.withValues(alpha: 0.48),
    );

    // Permukaan air bawah
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.12),
      Paint()..color = climate.primaryBrand.withValues(alpha: 0.58),
    );

    // Garis horizon oranye
    canvas.drawLine(
      Offset(22, size.height * 0.62),
      Offset(size.width - 22, size.height * 0.62),
      Paint()
        ..color = climate.warmDot
        ..strokeWidth = 2.0,
    );

    // 4 Siku Viewfinder Putih Membulat [ ] sesuai Frame 275
    final bracketPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final l = size.width * 0.16;
    final r = size.width * 0.84;
    final t = size.height * 0.20;
    final b = size.height * 0.65;
    const len = 28.0;
    const rad = 12.0;

    // Top-left
    final tl = Path()
      ..moveTo(l, t + len)
      ..lineTo(l, t + rad)
      ..quadraticBezierTo(l, t, l + rad, t)
      ..lineTo(l + len, t);
    canvas.drawPath(tl, bracketPaint);

    // Top-right
    final tr = Path()
      ..moveTo(r - len, t)
      ..lineTo(r - rad, t)
      ..quadraticBezierTo(r, t, r, t + rad)
      ..lineTo(r, t + len);
    canvas.drawPath(tr, bracketPaint);

    // Bottom-left
    final bl = Path()
      ..moveTo(l, b - len)
      ..lineTo(l, b - rad)
      ..quadraticBezierTo(l, b, l + rad, b)
      ..lineTo(l + len, b);
    canvas.drawPath(bl, bracketPaint);

    // Bottom-right
    final br = Path()
      ..moveTo(r - len, b)
      ..lineTo(r - rad, b)
      ..quadraticBezierTo(r, b, r, b - rad)
      ..lineTo(r, b - len);
    canvas.drawPath(br, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _CameraViewfinderPainter oldDelegate) => false;
}
