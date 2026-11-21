import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../config/map_tile_cache.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/interactive_gps_map_card.dart';
import '../../widgets/tactile_interaction.dart';
import '../location_search_screen.dart';

/// Tab 2: Peta Lokasi Anda (Frame 195 login_ui.figcraft)
/// terintegrasi otomatis dengan Google Maps tiles, Geolocator GPS, & fitur pencarian lokasi Google Maps.
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
  final NetworkTileProvider _tileProvider = MapTileCache.createTileProvider();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _moveMap(double lat, double lng) {
    try {
      _mapController.move(LatLng(lat, lng), 15.8);
    } catch (_) {}
  }

  /// Membuka layar Cari Lokasi (frame 22/23 desain): peta penuh, kolom cari, dan "Pilih Lokasi Ini".
  Future<void> _openLocationSearch(BuildContext context) async {
    final picked = await LocationSearchScreen.open(
      context,
      dashboardController: widget.dashboardController,
      authController: widget.authController,
    );
    if (picked == true && mounted) {
      final gps = widget.authController.gpsModel;
      _moveMap(gps.latitude, gps.longitude);
    }
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
                // 1. Kartu Peta Google Maps Interaktif sesuai Frame 195
                StaggeredEntrance(
                  delayMs: 40,
                  child: Container(
                    width: double.infinity,
                    height: 332,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: climate.border, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Kartografi Google Maps (jalan tol kuning, jalan putih, taman hijau, sungai)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GoogleMapsCartographyPainter(
                              isDark: climate.isDark,
                              centerLat: gps.latitude,
                              centerLng: gps.longitude,
                            ),
                          ),
                        ),

                        // Live Google Maps Tile Layer
                        Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              // Transparan agar kartografi di bawahnya tetap terlihat saat tile belum dimuat.
                              backgroundColor: Colors.transparent,
                              initialCenter: LatLng(
                                gps.latitude,
                                gps.longitude,
                              ),
                              initialZoom: 15.8,
                              onTap: (_, point) {
                                widget.authController.updatePickedMapPoint(
                                  point.latitude,
                                  point.longitude,
                                );
                              },
                            ),
                            children: [
                              TileLayer(
                                tileProvider: _tileProvider,
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.thalia.ui_presu',
                              ),
                            ],
                          ),
                        ),

                        // Lingkaran Radar + Pin Lokasi + Label Cuaca di atas Pin
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
                                  color: climate.primaryBrand.withValues(
                                    alpha: 0.14,
                                  ),
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

                        // Pill Kiri Atas: • Visual Lokasi: Cikarang (ketuk untuk cari lokasi)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: GestureDetector(
                            onTap: () => _openLocationSearch(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: climate.surfaceWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: climate.border),
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
                ),
                const SizedBox(height: 14),

                // 2. Kartu Pengaturan Lokasi Bawah sesuai Frame 195
                StaggeredEntrance(
                  delayMs: 100,
                  child: Container(
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
                            Expanded(
                              child: Text(
                                'Pengaturan Lokasi',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryDark,
                                ),
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

                        // Box Nama Wilayah + Tombol Ganti › (membuka pencarian Google Maps)
                        TactilePressable(
                          onTap: () => _openLocationSearch(context),
                          child: Container(
                            height: 44,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
