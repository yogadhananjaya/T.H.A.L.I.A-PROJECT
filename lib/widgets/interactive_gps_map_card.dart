import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import 'figcraft_assets.dart';

/// Kartu Peta Interaktif terintegrasi Google Maps Tiles & Geolocator GPS
/// sesuai tampilan Screenshot 5 (Izinkan Akses Lokasi).
class InteractiveGpsMapCard extends StatefulWidget {
  const InteractiveGpsMapCard({
    super.key,
    required this.palette,
    required this.gpsModel,
    required this.onTapRequestGps,
    required this.onMapPointPicked,
  });

  final ThaliaPalette palette;
  final GpsLocationModel gpsModel;
  final VoidCallback onTapRequestGps;
  final void Function(double lat, double lng) onMapPointPicked;

  @override
  State<InteractiveGpsMapCard> createState() => _InteractiveGpsMapCardState();
}

class _InteractiveGpsMapCardState extends State<InteractiveGpsMapCard>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _radarController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void didUpdateWidget(covariant InteractiveGpsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpsModel.latitude != widget.gpsModel.latitude ||
        oldWidget.gpsModel.longitude != widget.gpsModel.longitude) {
      try {
        _mapController.move(
          LatLng(widget.gpsModel.latitude, widget.gpsModel.longitude),
          16.2,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final centerLatLng = LatLng(
      widget.gpsModel.latitude,
      widget.gpsModel.longitude,
    );

    return Container(
      width: double.infinity,
      height: 286,
      decoration: BoxDecoration(
        color: palette.isDark
            ? const Color(0xFF192624)
            : const Color(0xFFECE9E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Fallback vector grid (tampil instan & saat offline/test)
          Positioned.fill(
            child: CustomPaint(
              painter: _GpsGridMapPainter(isDark: palette.isDark),
            ),
          ),

          // 2. Peta Interaktif Google Maps Tile Layer (terpusat pada koordinat GPS rumah user)
          if (widget.gpsModel.isGpsEnabled)
            Positioned.fill(
              child: Opacity(
                opacity: 0.92,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centerLatLng,
                    initialZoom: 16.2,
                    onTap: (_, point) {
                      widget.onMapPointPicked(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.thalia.ui_presu',
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTapRequestGps,
              ),
            ),

          // 3. Bingkai target radar hijau putus-putus + 4 siku sudut [ ] + Pin dari FigCraft
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, _) {
                final t = _radarController.value;
                return SizedBox(
                  width: 108,
                  height: 108,
                  child: CustomPaint(
                    painter: _TargetBracketPainter(progress: t),
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, -3.5 * t),
                        child: Image.asset(
                          FigcraftAssets.locationPinMarker,
                          width: 34,
                          height: 46,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Badge kiri atas: • GPS Otomatis (bisa dipencet untuk minta izin lokasi)
          Positioned(
            top: 14,
            left: 14,
            child: GestureDetector(
              onTap: widget.onTapRequestGps,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.gpsModel.isGpsEnabled
                            ? ThaliaColors.emeraldBright
                            : ThaliaColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'GPS Otomatis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Pill status bawah sesuai Screenshot 5: Deteksi Otomatis Wilayah | Akurat
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: GestureDetector(
              onTap: widget.onTapRequestGps,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ThaliaColors.forestDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.gpsModel.isScanning
                            ? 'Memindai lokasi rumah...'
                            : (widget.gpsModel.isGpsEnabled
                                ? 'Deteksi Otomatis Wilayah (${widget.gpsModel.resolvedAddress})'
                                : 'Deteksi Otomatis Wilayah'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.gpsModel.accuracyLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ThaliaColors.emeraldBright,
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

/// Painter untuk kotak radar hijau putus-putus + 4 siku [ ] persis seperti Screenshot 5.
class _TargetBracketPainter extends CustomPainter {
  const _TargetBracketPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 10.0 - (progress * 2.0);
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    // Fill hijau lembut
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = ThaliaColors.emeraldBright.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Garis putus-putus kotak dalam
    final dashPaint = Paint()
      ..color = ThaliaColors.emeraldBright.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + 5.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), dashPaint);
        d += 9.0;
      }
    }

    // 4 Siku Sudut Tegas (#4EB26D) sesuai Screenshot 5
    final cornerPaint = Paint()
      ..color = ThaliaColors.emeraldPrimary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const len = 14.0;
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;

    // Kiri Atas
    canvas.drawLine(Offset(l, t + len), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + len, t), cornerPaint);
    // Kanan Atas
    canvas.drawLine(Offset(r - len, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + len), cornerPaint);
    // Kiri Bawah
    canvas.drawLine(Offset(l, b - len), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + len, b), cornerPaint);
    // Kanan Bawah
    canvas.drawLine(Offset(r - len, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - len), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _TargetBracketPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GpsGridMapPainter extends CustomPainter {
  const _GpsGridMapPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF253734) : const Color(0xFFE0DDD3)
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final x = (size.width / 5) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF21312E) : const Color(0xFFE1DED4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 66, 46, 42),
        const Radius.circular(6),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 110, 118, 54, 42),
        const Radius.circular(6),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(78, 178, 56, 36),
        const Radius.circular(6),
      ),
      blockPaint,
    );

    final riverPath = Path()
      ..moveTo(size.width * 0.08, 0)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.38,
        size.width * 0.56,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.65,
        size.width * 0.88,
        size.height,
      );

    final riverPaint = Paint()
      ..color = ThaliaColors.skyWave
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(riverPath, riverPaint);
  }

  @override
  bool shouldRepaint(covariant _GpsGridMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
