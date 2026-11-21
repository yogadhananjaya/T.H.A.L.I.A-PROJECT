import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import 'figcraft_assets.dart';

/// Kartu Peta Interaktif terintegrasi Google Maps Tiles & Geolocator GPS (tanpa animasi idle).
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

class _InteractiveGpsMapCardState extends State<InteractiveGpsMapCard> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant InteractiveGpsMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpsModel.latitude != widget.gpsModel.latitude ||
        oldWidget.gpsModel.longitude != widget.gpsModel.longitude) {
      try {
        _mapController.move(
          LatLng(widget.gpsModel.latitude, widget.gpsModel.longitude),
          16.0,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
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
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Kartografi bergaya Google Maps (jalan tol kuning, jalan lokal putih, sungai, taman)
          Positioned.fill(
            child: CustomPaint(
              painter: GoogleMapsCartographyPainter(
                isDark: palette.isDark,
                centerLat: widget.gpsModel.latitude,
                centerLng: widget.gpsModel.longitude,
              ),
            ),
          ),

          // 2. Peta Interaktif Google Maps Tile Layer Asli
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 16.0,
                onTap: (_, point) {
                  widget.onMapPointPicked(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://mt1.google.com/vt/lyrs=m&hl=id&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.thalia.ui_presu',
                ),
              ],
            ),
          ),

          // 3. Bingkai target hijau putus-putus + 4 siku sudut [ ] + Pin (statis tanpa animasi idle)
          IgnorePointer(
            child: SizedBox(
              width: 104,
              height: 104,
              child: CustomPaint(
                painter: const _TargetBracketPainter(),
                child: Center(
                  child: Image.asset(
                    FigcraftAssets.locationPinMarker,
                    width: 34,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 4. Badge kiri atas: • GPS Otomatis
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
                      color: Color(0x16000000),
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

          // 5. Pill status bawah: Deteksi Otomatis Wilayah | Akurat
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
                            : 'Deteksi Otomatis Wilayah (${widget.gpsModel.resolvedAddress})',
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

class _TargetBracketPainter extends CustomPainter {
  const _TargetBracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 9.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = ThaliaColors.emeraldBright.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );

    final dashPaint = Paint()
      ..color = ThaliaColors.emeraldBright.withValues(alpha: 0.5)
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

    canvas.drawLine(Offset(l, t + len), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + len, t), cornerPaint);
    canvas.drawLine(Offset(r - len, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + len), cornerPaint);
    canvas.drawLine(Offset(l, b - len), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + len, b), cornerPaint);
    canvas.drawLine(Offset(r - len, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - len), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _TargetBracketPainter oldDelegate) => false;
}

/// Kartografi bergaya Google Maps asli (jalan arteri kuning #FDE293, jalan lokal putih,
/// taman kota hijau #C8E6C9, sungai #9CC0F9, dan blok bangunan) agar peta selalu tampak
/// seperti Google Maps meskipun tile sedang dimuat atau koneksi emulator terbatas.
class GoogleMapsCartographyPainter extends CustomPainter {
  const GoogleMapsCartographyPainter({
    this.isDark = false,
    this.centerLat = -6.2845,
    this.centerLng = 107.1705,
  });

  final bool isDark;
  final double centerLat;
  final double centerLng;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Warna Dasar Lahan Google Maps (#F1F3F4)
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = isDark ? const Color(0xFF1D2C3A) : const Color(0xFFF2EFE9),
    );

    // Offset pan halus mengikuti koordinat
    final dx = ((centerLng * 1000) % 24) - 12;
    final dy = ((centerLat * 1000) % 24) - 12;
    canvas.save();
    canvas.translate(dx, dy);

    // 2. Area Taman / Ruang Terbuka Hijau Google Maps (#CBE6A3 / #C8E6C9)
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF233D32) : const Color(0xFFD5E8C4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.14, 92, 68),
        const Radius.circular(10),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.66, size.height * 0.56, 108, 76),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // 3. Blok-blok Bangunan Google Maps (#E8EAED)
    final buildingPaint = Paint()
      ..color = isDark ? const Color(0xFF263747) : const Color(0xFFE4E0D7);
    final blocks = [
      Rect.fromLTWH(size.width * 0.12, size.height * 0.52, 48, 36),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.62, 54, 34),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.16, 62, 40),
      Rect.fromLTWH(size.width * 0.76, size.height * 0.26, 48, 44),
      Rect.fromLTWH(size.width * 0.38, size.height * 0.12, 46, 30),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(5)),
        buildingPaint,
      );
    }

    // 4. Aliran Sungai Google Maps (#9CC0F9)
    final riverPath = Path()
      ..moveTo(size.width * 0.12, -20)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.32,
        size.width * 0.52,
        size.height * 0.55,
        size.width * 0.85,
        size.height + 20,
      );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = isDark ? const Color(0xFF285580) : const Color(0xFF9CC0F9)
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 5. Jaringan Jalan Lokal Putih Google Maps
    final streetCasing = Paint()
      ..color = isDark ? const Color(0xFF34495E) : const Color(0xFFDADCE0)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final streetFill = Paint()
      ..color = isDark ? const Color(0xFF2C3E50) : Colors.white
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final localRoads = [
      [Offset(-20, size.height * 0.28), Offset(size.width + 20, size.height * 0.24)],
      [Offset(-20, size.height * 0.72), Offset(size.width + 20, size.height * 0.68)],
      [Offset(size.width * 0.26, -20), Offset(size.width * 0.32, size.height + 20)],
      [Offset(size.width * 0.72, -20), Offset(size.width * 0.66, size.height + 20)],
    ];
    for (final road in localRoads) {
      canvas.drawLine(road[0], road[1], streetCasing);
      canvas.drawLine(road[0], road[1], streetFill);
    }

    // 6. Jalan Raya Arteri Kuning Khas Google Maps (#FDE293 dengan outline #F6AD01)
    final highwayPath = Path()
      ..moveTo(-20, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.42,
        size.width + 20,
        size.height * 0.54,
      );
    canvas.drawPath(
      highwayPath,
      Paint()
        ..color = isDark ? const Color(0xFF8A6D1B) : const Color(0xFFF5B400)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      highwayPath,
      Paint()
        ..color = isDark ? const Color(0xFFB7950B) : const Color(0xFFFDE293)
        ..strokeWidth = 9.5
        ..style = PaintingStyle.stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GoogleMapsCartographyPainter oldDelegate) =>
      oldDelegate.centerLat != centerLat ||
      oldDelegate.centerLng != centerLng ||
      oldDelegate.isDark != isDark;
}
