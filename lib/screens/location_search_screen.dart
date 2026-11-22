import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../config/map_tile_cache.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/dashboard_models.dart';
import '../widgets/tactile_interaction.dart';

/// Layar 22 (Hujan) dan 23 (Panas) pada login_ui.figcraft: "Cari Lokasi".
/// Peta penuh dengan pin di tengah, kolom cari bergaya Google Maps di atas,
/// daftar hasil, dan panel "Pilih Lokasi Ini" di bawah.
class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
  });

  final DashboardController dashboardController;
  final AuthController authController;

  /// Mengembalikan true bila pengguna menekan "Pilih Lokasi Ini".
  static Future<bool?> open(
    BuildContext context, {
    required DashboardController dashboardController,
    required AuthController authController,
  }) {
    return Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return LocationSearchScreen(
            dashboardController: dashboardController,
            authController: authController,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  /// Tile OpenStreetMap gratis tanpa Google Maps API key (B36).
  static const String _tileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  static const double _zoom = 16;

  final MapController _map = MapController();
  final NetworkTileProvider _tileProvider = MapTileCache.createTileProvider();
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  Timer? _searchDebounce;
  Timer? _resolveDebounce;

  late LatLng _center;
  late String _placeName;
  late String _placeSubtitle;

  List<PlaceSearchResult> _results = AuthController.defaultIndonesianPlaces;
  PlaceSearchResult? _selectedResult;

  bool _isSearching = false;
  bool _isResolving = false;
  bool _isLocating = false;
  bool _hintVisible = true;

  @override
  void initState() {
    super.initState();
    final gps = widget.authController.gpsModel;
    _center = LatLng(gps.latitude, gps.longitude);
    _placeName = gps.resolvedAddress;
    _placeSubtitle = 'Lokasi pantauan saat ini';
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _resolveDebounce?.cancel();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  // --- Pencarian ---

  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 280), () async {
      final found = await widget.authController.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _results = found;
        _isSearching = false;
      });
    });
  }

  void _clearQuery() {
    _query.clear();
    _onQueryChanged('');
  }

  void _selectResult(PlaceSearchResult place) {
    _focus.unfocus();
    setState(() => _selectedResult = place);
    _jumpTo(
      LatLng(place.latitude, place.longitude),
      name: place.name,
      subtitle: place.subtitle,
    );
  }

  // --- Peta ---

  /// Memindahkan peta dan langsung mengisi nama tempat (tanpa menunggu geocoding).
  void _jumpTo(LatLng point, {required String name, required String subtitle}) {
    _resolveDebounce?.cancel();
    setState(() {
      _center = point;
      _placeName = name;
      _placeSubtitle = subtitle;
      _isResolving = false;
    });
    try {
      _map.move(point, _zoom);
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _center = camera.center;
    _selectedResult = null;
    _resolveDebounce?.cancel();
    setState(() {
      _hintVisible = false;
      _isResolving = true;
    });
    _resolveDebounce = Timer(const Duration(milliseconds: 550), _resolveCenter);
  }

  Future<void> _resolveCenter() async {
    final point = _center;
    final name = await widget.authController.describePoint(
      point.latitude,
      point.longitude,
    );
    if (!mounted || point != _center) return;
    setState(() {
      _placeName = name;
      _placeSubtitle = 'Titik dipilih dari peta';
      _isResolving = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    _focus.unfocus();
    setState(() => _isLocating = true);

    await widget.authController.requestAndDetectGpsLocation();
    if (!mounted) return;

    final gps = widget.authController.gpsModel;
    setState(() => _isLocating = false);

    if (!gps.isGpsEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Lokasi belum aktif. Izinkan akses lokasi lalu coba lagi.'),
          ),
        );
      return;
    }
    _selectedResult = null;
    _jumpTo(
      LatLng(gps.latitude, gps.longitude),
      name: gps.resolvedAddress,
      subtitle: 'Lokasi GPS • ${gps.accuracyLabel}',
    );
  }

  void _confirm() {
    widget.authController.selectPlaceResult(
      PlaceSearchResult(
        name: _placeName,
        subtitle: _placeSubtitle,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
    Navigator.of(context).pop(true);
  }

  double _distanceKm(PlaceSearchResult place) {
    const earthKm = 6371.0;
    final lat1 = _center.latitude * math.pi / 180;
    final lat2 = place.latitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (place.longitude - _center.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earthKm * math.asin(math.min(1.0, math.sqrt(a)));
  }

  String _distanceText(PlaceSearchResult place) {
    final km = _distanceKm(place);
    return km >= 100 ? '${km.round()} km' : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.dashboardController,
        widget.authController,
      ]),
      builder: (context, _) {
        final climate = ClimatePalette(
          season: widget.dashboardController.seasonMode,
          isDark: widget.authController.isDarkMode,
        );
        final padding = MediaQuery.paddingOf(context);
        final sheetHeight = 168.0 + padding.bottom;
        final searchTop = padding.top + 8;
        final panelTop = searchTop + 52 + 8;

        return Scaffold(
          backgroundColor: climate.canvas,
          // Keyboard menimpa panel bawah, bukan mengecilkan peta (titik pusat tidak bergeser).
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Latar peta bertema (tampil bila tile belum dimuat / tanpa internet).
              Positioned.fill(
                child: CustomPaint(painter: _MapBackdropPainter(climate: climate)),
              ),
              Positioned.fill(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _zoom,
                    backgroundColor: Colors.transparent,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (tapPosition, point) => _focus.unfocus(),
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      tileProvider: _tileProvider,
                      urlTemplate: _tileUrl,
                      userAgentPackageName: 'com.thalia.app',
                    ),
                  ],
                ),
              ),

              // Pin tetap di tengah layar; peta yang digeser di bawahnya.
              Positioned.fill(
                child: IgnorePointer(
                  child: _CenterPin(climate: climate, showHint: _hintVisible),
                ),
              ),

              // Tombol pusatkan ke GPS.
              Positioned(
                right: 18,
                bottom: sheetHeight + 18,
                child: TactilePressable(
                  onTap: _useCurrentLocation,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: climate.surfaceWhite,
                      border: Border.all(color: climate.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLocating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: climate.primaryBrand,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 22,
                            color: climate.primaryBrand,
                          ),
                  ),
                ),
              ),

              // Panel konfirmasi di bawah.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ConfirmSheet(
                  climate: climate,
                  height: sheetHeight,
                  placeName: _placeName,
                  subtitle: _isResolving
                      ? 'Memuat alamat...'
                      : '$_placeSubtitle • ${_center.latitude.toStringAsFixed(3)}, ${_center.longitude.toStringAsFixed(3)}',
                  onConfirm: _confirm,
                ),
              ),

              // Daftar hasil / autocomplete (hanya saat kolom cari aktif).
              if (_focus.hasFocus)
                Positioned(
                  top: panelTop,
                  left: 16,
                  right: 16,
                  child: _AutocompletePanel(
                    climate: climate,
                    results: _results,
                    selected: _selectedResult,
                    isLocating: _isLocating,
                    distanceText: _distanceText,
                    onUseCurrentLocation: _useCurrentLocation,
                    onSelect: _selectResult,
                  ),
                ),

              // Kolom cari.
              Positioned(
                top: searchTop,
                left: 16,
                right: 16,
                child: _SearchBar(
                  climate: climate,
                  controller: _query,
                  focusNode: _focus,
                  isSearching: _isSearching,
                  onChanged: _onQueryChanged,
                  onClear: _clearQuery,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.climate,
    required this.controller,
    required this.focusNode,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
  });

  final ClimatePalette climate;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: climate.surfaceWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: climate.border, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: climate.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              onChanged: onChanged,
              cursorColor: climate.primaryBrand,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: climate.primaryDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari wilayah (mis. Cikarang, Bogor)',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: climate.textSecondary,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: climate.canvas,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: climate.textSecondary,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: climate.pillFill,
            ),
            alignment: Alignment.center,
            child: isSearching
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: climate.primaryBrand,
                    ),
                  )
                : Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: climate.primaryBrand,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AutocompletePanel extends StatelessWidget {
  const _AutocompletePanel({
    required this.climate,
    required this.results,
    required this.selected,
    required this.isLocating,
    required this.distanceText,
    required this.onUseCurrentLocation,
    required this.onSelect,
  });

  final ClimatePalette climate;
  final List<PlaceSearchResult> results;
  final PlaceSearchResult? selected;
  final bool isLocating;
  final String Function(PlaceSearchResult place) distanceText;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<PlaceSearchResult> onSelect;

  @override
  Widget build(BuildContext context) {
    // Tinggi dibatasi agar daftar panjang bisa digulir dan tidak menembus layar.
    final maxHeight = math.min(
      60.0 + 56.0 * 5,
      MediaQuery.sizeOf(context).height * 0.42,
    );

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: climate.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: climate.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TactilePressable(
            onTap: onUseCurrentLocation,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: climate.pillFill,
                    ),
                    alignment: Alignment.center,
                    child: isLocating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: climate.primaryBrand,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 17,
                            color: climate.primaryBrand,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gunakan Lokasi Saat Ini',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: climate.primaryBrand,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Deteksi otomatis via GPS • Akurat',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: climate.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, indent: 14, endIndent: 14, color: climate.border),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
              itemCount: results.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 50,
                endIndent: 8,
                color: climate.border,
              ),
              itemBuilder: (context, index) {
                final place = results[index];
                final isSelected = identical(place, selected);
                return TactilePressable(
                  onTap: () => onSelect(place),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? climate.canvas : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? climate.primaryBrand
                                : climate.canvas,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 17,
                            color: isSelected
                                ? Colors.white
                                : climate.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                maxLines: 1,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: climate.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          distanceText(place),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? climate.primaryBrand
                                : climate.textSecondary,
                          ),
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

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.climate,
    required this.height,
    required this.placeName,
    required this.subtitle,
    required this.onConfirm,
  });

  final ClimatePalette climate;
  final double height;
  final String placeName;
  final String subtitle;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      decoration: BoxDecoration(
        color: climate.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: climate.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: climate.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: climate.pillFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 22,
                  color: climate.primaryBrand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: climate.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: climate.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TactilePressable(
            onTap: onConfirm,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: climate.primaryBrand,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Pilih Lokasi Ini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin tetap di tengah: lingkaran radius, bayangan, pin tetesan, dan petunjuk geser.
/// Ujung pin tepat berada di titik pusat layar (= titik pusat peta).
class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.climate, required this.showHint});

  final ClimatePalette climate;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: climate.primaryBrand.withValues(alpha: 0.10),
            border: Border.all(
              color: climate.primaryBrand.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
        ),
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -22),
          child: CustomPaint(
            size: const Size(32, 44),
            painter: _TeardropPinPainter(color: climate.primaryBrand),
          ),
        ),
        if (showHint)
          Transform.translate(
            offset: const Offset(0, -68),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: climate.activeForecastBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Geser peta atur titik',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TeardropPinPainter extends CustomPainter {
  const _TeardropPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path()
      ..moveTo(r, h)
      ..cubicTo(r * 0.4, h * 0.78, 0, h * 0.58, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(w, h * 0.58, w - r * 0.4, h * 0.78, r, h)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(r, r), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Latar peta bergaya desain (taman, blok kota, sungai, jalan lokal, arteri, tol).
/// Warnanya mengikuti tema Hujan / Panas / Gelap dan tampil di bawah tile peta sungguhan.
class _MapBackdropPainter extends CustomPainter {
  const _MapBackdropPainter({required this.climate});

  final ClimatePalette climate;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = climate.isDark;
    final orange = climate.isOrange;

    final base = dark
        ? const Color(0xFF14212E)
        : (orange ? const Color(0xFFF6F0E9) : const Color(0xFFEDF3F8));
    final park = dark
        ? const Color(0xFF1F3A2E)
        : (orange ? const Color(0xFFE6E4D2) : const Color(0xFFD8ECE3));
    final block = dark
        ? const Color(0xFF1B2C3B)
        : (orange ? const Color(0xFFEDE2D7) : const Color(0xFFE1ECF5));
    final river = dark
        ? const Color(0xFF23527A)
        : (orange ? const Color(0xFFC7DDEA) : const Color(0xFFB6DAF4));
    final road = dark ? const Color(0xFF2C3E50) : Colors.white;
    final arterialCasing = dark
        ? const Color(0xFF34495E)
        : (orange ? const Color(0xFFE3D3C5) : const Color(0xFFCEDCE8));
    final tollCasing =
        dark ? const Color(0xFF8A6D1B) : const Color(0xFFDFB664);
    final tollCore = dark ? const Color(0xFFB7950B) : const Color(0xFFF7D896);

    // Koordinat mengikuti kanvas desain 390 x 700, diskalakan ke ukuran layar.
    final sx = size.width / 390;
    final sy = size.height / 700;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Rect rect(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy);

    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final parkPaint = Paint()..color = park;
    for (final r in [rect(-12, 340, 118, 112), rect(274, 452, 126, 124)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        parkPaint,
      );
    }
    final blockPaint = Paint()..color = block;
    for (final r in [
      rect(24, 500, 96, 84),
      rect(246, 344, 110, 74),
      rect(132, 584, 124, 68),
      rect(18, 120, 96, 84),
      rect(250, 150, 110, 74),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        blockPaint,
      );
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(p(-10, 470).dx, p(-10, 470).dy)
      ..cubicTo(
        p(100, 430).dx, p(100, 430).dy,
        p(180, 560).dx, p(180, 560).dy,
        p(260, 540).dx, p(260, 540).dy,
      )
      ..cubicTo(
        p(320, 525).dx, p(320, 525).dy,
        p(360, 590).dx, p(360, 590).dy,
        p(400, 610).dx, p(400, 610).dy,
      );
    canvas.drawPath(riverPath, stroke(river, 20));

    final localRoad = stroke(road, 5);
    for (final y in [389.0, 472.0, 571.0, 200.0, 90.0]) {
      canvas.drawLine(p(-10, y), p(400, y + 6), localRoad);
    }
    for (final x in [76.0, 273.0]) {
      canvas.drawLine(p(x, -10), p(x + 6, 710), localRoad);
    }

    canvas.drawLine(p(182, -10), p(182, 710), stroke(arterialCasing, 12));
    canvas.drawLine(p(182, -10), p(182, 710), stroke(road, 9));

    final tollPath = Path()
      ..moveTo(p(-10, 500).dx, p(-10, 500).dy)
      ..quadraticBezierTo(
        p(190, 480).dx, p(190, 480).dy,
        p(400, 536).dx, p(400, 536).dy,
      );
    canvas.drawPath(tollPath, stroke(tollCasing, 13));
    canvas.drawPath(tollPath, stroke(tollCore, 9.5));
  }

  @override
  bool shouldRepaint(covariant _MapBackdropPainter oldDelegate) =>
      oldDelegate.climate.isDark != climate.isDark ||
      oldDelegate.climate.isOrange != climate.isOrange;
}
