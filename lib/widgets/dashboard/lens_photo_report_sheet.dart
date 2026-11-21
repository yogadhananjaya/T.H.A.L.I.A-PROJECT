import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../tactile_interaction.dart';

/// Tampilan Laporan Foto bergaya Google Lens (Screenshots 2 & 3):
/// - Foto tampil penuh di belakang dengan bingkai fokus Lens [ ] yang bisa digeser/diketuk.
/// - DraggableScrollableSheet muncul di bawah (peek 34%), dan ketika ditarik ke atas (88%)
///   menampilkan seluruh isi form Lengkapi Laporan Foto.
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

class _LensPhotoReportSheetState extends State<LensPhotoReportSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  late final TextEditingController _descController = TextEditingController(
    text: widget.controller.reportDescription,
  );

  // Titik fokus bingkai Google Lens [ ] yang bisa diketuk di atas foto
  Alignment _lensBoxAlignment = const Alignment(0.0, -0.22);

  @override
  void dispose() {
    _sheetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _expandSheetToFull() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.88,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final ctrl = widget.controller;

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // 1. Layar Penuh Foto + Bingkai Fokus Google Lens [ ] Interaktif
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final size = MediaQuery.sizeOf(context);
                final nx = ((details.localPosition.dx / size.width) * 2 - 1)
                    .clamp(-0.45, 0.45);
                final ny = ((details.localPosition.dy / size.height) * 2 - 1)
                    .clamp(-0.55, 0.05);
                setState(() => _lensBoxAlignment = Alignment(nx, ny));
              },
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

                  // Overlay gelap tipis di sekitar foto seperti Google Lens
                  Container(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),

                  // Bingkai Fokus Putih Google Lens [ ] di atas objek foto
                  AnimatedAlign(
                    alignment: _lensBoxAlignment,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(
                      width: 210,
                      height: 185,
                      child: CustomPaint(
                        painter: const _GoogleLensCornerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Top Bar Google Lens: Tombol Back, Judul "THALIA Lens", & Badge Foto
          Positioned(
            top: 42,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TactilePressable(
                  onTap: ctrl.retakePhoto,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.42),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  'THALIA Lens',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
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
                      const SizedBox(width: 6),
                      Text(
                        ctrl.formattedCaptureTime,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Draggable Bottom Sheet Gaya Google Lens (Peek 34% -> Tarik ke Atas 88%)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeOutCubic,
            builder: (context, slide, child) => FractionalTranslation(
              translation: Offset(0, slide),
              child: child,
            ),
            child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.36,
            minChildSize: 0.28,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.36, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: climate.canvas,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: climate.textSecondary.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pill Preview Thumbnail Gaya Google Lens (Ketuk atau tarik ke atas)
                    TactilePressable(
                      onTap: _expandSheetToFull,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: climate.surfaceWhite,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: climate.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: climate.activeForecastBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ctrl.capturedPhotoBytes != null
                                  ? Image.memory(
                                      ctrl.capturedPhotoBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: climate.warmDot,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tangkapan Visual • ${ctrl.selectedIncidentCategory}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: climate.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tarik ke atas untuk isi laporan lengkap ↑',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: climate.primaryBrand,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 22,
                              color: climate.primaryBrand,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                      'Lokasi: ${widget.locationName} • ${ctrl.formattedCaptureTime}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: climate.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                      children:
                          DashboardController.incidentCategories.map((category) {
                        final selected =
                            ctrl.selectedIncidentCategory == category;
                        return TactilePressable(
                          onTap: () {
                            ctrl.selectIncidentCategory(category);
                            _expandSheetToFull();
                          },
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

                    // Input Deskripsi Kondisi (muncul penuh saat ditarik ke atas)
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
                            onTap: _expandSheetToFull,
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
                    const SizedBox(height: 14),
                    if (ctrl.reportFormError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFEA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE07A5F)),
                        ),
                        child: Text(
                          ctrl.reportFormError!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9E2B15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

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
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}

/// Painter siku putih membulat khas Google Lens (Screenshot 2).
class _GoogleLensCornerPainter extends CustomPainter {
  const _GoogleLensCornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    const rad = 16.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, rad)
        ..quadraticBezierTo(0, 0, rad, 0)
        ..lineTo(len, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - rad, 0)
        ..quadraticBezierTo(w, 0, w, rad)
        ..lineTo(w, len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - rad)
        ..quadraticBezierTo(0, h, rad, h)
        ..lineTo(len, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - rad, h)
        ..quadraticBezierTo(w, h, w, h - rad)
        ..lineTo(w, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLensCornerPainter oldDelegate) => false;
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
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.25),
      28,
      Paint()..color = climate.warmDot,
    );
    canvas.drawOval(
      Rect.fromLTWH(-40, size.height * 0.36, size.width * 0.85, 220),
      Paint()..color = climate.primaryBrand.withValues(alpha: 0.65),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.56, size.width, size.height * 0.44),
      Paint()..color = climate.primaryBrand.withValues(alpha: 0.45),
    );
    canvas.drawRect(
      Rect.fromLTWH(24, size.height * 0.56, size.width - 48, 2),
      Paint()..color = climate.warmDot,
    );
  }

  @override
  bool shouldRepaint(covariant _CapturedBackdropPainter oldDelegate) => false;
}
