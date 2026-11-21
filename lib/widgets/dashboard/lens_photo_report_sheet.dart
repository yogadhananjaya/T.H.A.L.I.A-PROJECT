import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../tactile_interaction.dart';

/// Pop-up Form Laporan Foto dari bawah ke atas (gaya Google Lens / Google Photos)
/// yang menutupi sebagian foto hasil tangkapan kamera sesuai Frame 20 login_ui.figcraft.
class LensPhotoReportSheet extends StatefulWidget {
  const LensPhotoReportSheet({
    super.key,
    required this.controller,
    required this.climate,
    required this.locationName,
    required this.gpsCoordText,
  });

  final DashboardController controller;
  final ClimatePalette climate;
  final String locationName;
  final String gpsCoordText;

  @override
  State<LensPhotoReportSheet> createState() => _LensPhotoReportSheetState();
}

class _LensPhotoReportSheetState extends State<LensPhotoReportSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _descController = TextEditingController(
    text: widget.controller.reportDescription,
  );
  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _descController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final ctrl = widget.controller;
    final curved = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    return Container(
      color: climate.activeForecastBg,
      child: Stack(
        children: [
          // 1. Bagian Atas: Backdrop Foto yang Baru Diambil / Dipilih dari Galeri
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ctrl.capturedPhotoBytes != null)
                  Image.memory(
                    ctrl.capturedPhotoBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  CustomPaint(
                    painter: _CapturedBackdropPainter(climate: climate),
                  ),

                // Tombol Back Kiri Atas
                Positioned(
                  top: 44,
                  left: 20,
                  child: TactilePressable(
                    onTap: ctrl.retakePhoto,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Badge Kanan Atas: • Foto • 09:41 WIB
                Positioned(
                  top: 48,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: climate.warmDot,
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Foto • 09:41 WIB',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Pop-up Bottom Sheet Muncul dari Bawah ke Atas Menutupi Sebagian Foto (Gaya Google Lens)
          Positioned.fill(
            top: 175,
            child: AnimatedBuilder(
              animation: curved,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1.0 - curved.value) * 320),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                decoration: BoxDecoration(
                  color: climate.canvas,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle Bar Tengah
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: climate.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Lengkapi Laporan Foto',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: climate.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lokasi: ${widget.locationName} • 09:41 WIB',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: climate.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Pilihan Chip Jenis Kejadian
                      Text(
                        'Jenis Kejadian',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DashboardController.incidentCategories
                            .map((category) {
                          final selected =
                              ctrl.selectedIncidentCategory == category;
                          return TactilePressable(
                            onTap: () => ctrl.selectIncidentCategory(category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? climate.primaryBrand
                                    : climate.surfaceWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? climate.primaryBrand
                                      : climate.border,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : climate.primaryDark,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Input Deskripsi Kondisi
                      Text(
                        'Deskripsi Kondisi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: climate.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: climate.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              controller: _descController,
                              maxLines: 4,
                              maxLength: 300,
                              onChanged: ctrl.updateReportDescription,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: climate.primaryDark,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                counterText: '',
                              ),
                            ),
                            Text(
                              '${ctrl.reportDescription.length} / 300',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: climate.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Koordinat GPS otomatis dilampirkan (${widget.gpsCoordText})',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: climate.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tombol Ambil Ulang & Kirim Laporan ->
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TactilePressable(
                              onTap: ctrl.retakePhoto,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: climate.surfaceWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: climate.border),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Ambil Ulang',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: climate.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: TactilePressable(
                              onTap: () => ctrl.submitFieldPhotoReport(
                                locationName: widget.locationName,
                              ),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: climate.primaryBrand,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kirim Laporan',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapturedBackdropPainter extends CustomPainter {
  const _CapturedBackdropPainter({required this.climate});
  final ClimatePalette climate;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = climate.activeForecastBg,
    );
    // Bukit & Matahari/Bulan sesuai Frame 20 login_ui.figcraft
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.45),
      26,
      Paint()..color = climate.warmDot,
    );
    canvas.drawOval(
      Rect.fromLTWH(-30, size.height * 0.44, size.width * 0.75, 130),
      Paint()..color = climate.primaryBrand.withValues(alpha: 0.65),
    );
    canvas.drawRect(
      Rect.fromLTWH(26, size.height * 0.68, size.width - 52, 2),
      Paint()..color = climate.warmDot,
    );
  }

  @override
  bool shouldRepaint(covariant _CapturedBackdropPainter oldDelegate) => false;
}
