import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 2: Peta Lokasi Anda (Frame 195 login_ui.figcraft)
/// terintegrasi otomatis dengan Google Maps tiles, Geolocator GPS, & pengubah daerah.
class MapsTabScreen extends StatefulWidget {
  const MapsTabScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
    required this.climate,
  });

  final DashboardController dashboardController;
  final AuthController authController;
  final ClimatePalette climate;

  @override
  State<MapsTabScreen> createState() => _MapsTabScreenState();
}

class _MapsTabScreenState extends State<MapsTabScreen> {
  final MapController _mapController = MapController();

  static const List<({String name, double lat, double lng})> _presetRegions = [
    (name: 'Cikarang Utara, Bekasi', lat: -6.2845, lng: 107.1705),
    (name: 'Bantaran Ciliwung, Jakarta', lat: -6.2250, lng: 106.8620),
    (name: 'Cibinong, Bogor', lat: -6.4816, lng: 106.8542),
    (name: 'Jababeka, Cikarang', lat: -6.2980, lng: 107.1475),
  ];

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _moveMap(double lat, double lng) {
    try {
      _mapController.move(LatLng(lat, lng), 15.5);
    } catch (_) {}
  }

  void _showChangeLocationSheet(BuildContext context) {
    final climate = widget.climate;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: climate.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Wilayah Pantauan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: climate.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ketuk titik langsung di peta atau pilih stasiun wilayah di bawah:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: climate.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ..._presetRegions.map((region) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TactilePressable(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      widget.authController.updatePickedMapPoint(
                        region.lat,
                        region.lng,
                      );
                      _moveMap(region.lat, region.lng);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: climate.cardFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: climate.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            region.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: climate.primaryDark,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: climate.primaryBrand,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final dash = widget.dashboardController;
    final gps = widget.authController.gpsModel;
    final forecast = dash.currentForecast;
    final shortArea = gps.resolvedAddress.split(',').first.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Visual Wilayah & Pengaturan Lokasi',
            titleText: 'Peta Lokasi Anda',
            onTapProfile: dash.openProfile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
            child: Column(
              children: [
                // 1. Kartu Peta Interaktif (358px) sesuai Frame 195 login_ui.figcraft
                Container(
                  width: double.infinity,
                  height: 332,
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: climate.border, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fallback vector grid
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BlueMapGridPainter(climate: climate),
                        ),
                      ),

                      // Live Google Maps Tile Layer
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.9,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(
                                gps.latitude,
                                gps.longitude,
                              ),
                              initialZoom: 15.5,
                              onTap: (_, point) {
                                widget.authController.updatePickedMapPoint(
                                  point.latitude,
                                  point.longitude,
                                );
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                userAgentPackageName: 'com.thalia.ui_presu',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Lingkaran Radar Putus-putus + Pin Lokasi + Label Cuaca di atas Pin
                      IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: climate.activeForecastBg,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$shortArea • ${forecast.temperatureC}°C ${forecast.conditionTitle.split(" ").first}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    climate.primaryBrand.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: climate.primaryBrand,
                                  width: 1.4,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: climate.primaryBrand.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 32,
                                  color: climate.primaryBrand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pill Kiri Atas: • Visual Lokasi: Cikarang
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: climate.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: climate.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: climate.primaryBrand,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Visual Lokasi: $shortArea',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pill Kanan Bawah: Radius 5 km • Air 110cm
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: climate.surfaceWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: climate.border),
                          ),
                          child: Text(
                            'Radius ${dash.monitoringRadiusKm} km • ${forecast.waterLevelText}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: climate.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Kartu Pengaturan Lokasi Bawah sesuai Frame 195 login_ui.figcraft
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: climate.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pengaturan Lokasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: climate.primaryDark,
                            ),
                          ),
                          TactilePressable(
                            onTap: () async {
                              await widget.authController
                                  .requestAndDetectGpsLocation();
                              final updated = widget.authController.gpsModel;
                              _moveMap(updated.latitude, updated.longitude);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: climate.primaryBrand,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                gps.isScanning ? 'Memindai...' : '• Auto GPS',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Box Nama Wilayah + Tombol Ganti >
                      TactilePressable(
                        onTap: () => _showChangeLocationSheet(context),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: climate.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: climate.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  gps.resolvedAddress,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: climate.primaryDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Ganti ›',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryBrand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Baris Radius Pantauan & Simpan Lokasi
                      Row(
                        children: [
                          Expanded(
                            child: TactilePressable(
                              onTap: dash.cycleMonitoringRadius,
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: climate.pillFill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Radius Pantauan: ${dash.monitoringRadiusKm} km',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: climate.primaryBrand,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TactilePressable(
                            onTap: () => dash.selectTab(DashboardTab.home),
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              decoration: BoxDecoration(
                                color: climate.activeForecastBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Simpan Lokasi',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueMapGridPainter extends CustomPainter {
  const _BlueMapGridPainter({required this.climate});
  final ClimatePalette climate;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = climate.border.withValues(alpha: 0.65)
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final x = (size.width / 5) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final riverPath = Path()
      ..moveTo(size.width * 0.14, 0)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.44,
        size.width * 0.82,
        size.height,
      );

    canvas.drawPath(
      riverPath,
      Paint()
        ..color = climate.primaryBrand.withValues(alpha: 0.35)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = climate.primaryBrand
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BlueMapGridPainter oldDelegate) => false;
}
