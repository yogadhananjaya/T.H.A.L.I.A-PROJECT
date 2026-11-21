import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/interactive_gps_map_card.dart';
import '../../widgets/tactile_interaction.dart';

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

  void _showGoogleMapsSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.climate.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return _GoogleMapsSearchModal(
          authController: widget.authController,
          climate: widget.climate,
          onPlaceSelected: (place) {
            Navigator.of(ctx).pop();
            widget.authController.selectPlaceResult(place);
            _moveMap(place.latitude, place.longitude);
          },
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
                                urlTemplate:
                                    'https://mt1.google.com/vt/lyrs=m&hl=id&x={x}&y={y}&z={z}',
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
                            onTap: () => _showGoogleMapsSearchSheet(context),
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
                          onTap: () => _showGoogleMapsSearchSheet(context),
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

/// Modal Bottom Sheet Pencarian Lokasi Google Maps dengan Search Bar Interaktif.
class _GoogleMapsSearchModal extends StatefulWidget {
  const _GoogleMapsSearchModal({
    required this.authController,
    required this.climate,
    required this.onPlaceSelected,
  });

  final AuthController authController;
  final ClimatePalette climate;
  final ValueChanged<PlaceSearchResult> onPlaceSelected;

  @override
  State<_GoogleMapsSearchModal> createState() => _GoogleMapsSearchModalState();
}

class _GoogleMapsSearchModalState extends State<_GoogleMapsSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceSearchResult> _results = AuthController.defaultIndonesianPlaces;
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final res = await widget.authController.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = res;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 14, 22, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: climate.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cari & Pilih Wilayah Pantauan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: climate.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cari nama jalan, kecamatan, atau kota di Google Maps:',
            style: TextStyle(
              fontSize: 12.5,
              color: climate.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Search Input Box Google Maps
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: climate.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: climate.primaryBrand, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: climate.primaryBrand,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: climate.primaryDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Cari wilayah (mis. Cikarang, Manggarai, Bogor)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: climate.textSecondary,
                      ),
                    ),
                  ),
                ),
                if (_isSearching)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: climate.primaryBrand,
                    ),
                  )
                else if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: climate.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Hasil Pencarian Lokasi
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 270),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final place = _results[index];
                return TactilePressable(
                  onTap: () => widget.onPlaceSelected(place),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: climate.cardFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: climate.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: climate.pillFill,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: climate.primaryBrand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place.subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: climate.textSecondary,
                                ),
                              ),
                            ],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
