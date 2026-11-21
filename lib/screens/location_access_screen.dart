import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_action_buttons.dart';
import '../widgets/figcraft_assets.dart';
import '../widgets/interactive_gps_map_card.dart';
import '../widgets/tactile_interaction.dart';

/// Layar 3 pada Frame 1 LOGIN.figcraft: "Izinkan Akses Lokasi"
/// dengan kartu toggle GPS Otomatis sesuai Screenshot 5 & izin lokasi native Android.
class LocationAccessScreen extends StatelessWidget {
  const LocationAccessScreen({
    super.key,
    required this.controller,
    required this.palette,
  });

  final AuthController controller;
  final ThaliaPalette palette;

  Future<void> _openManualSearchSheet(BuildContext context) async {
    var results = AuthController.defaultIndonesianPlaces;
    var searching = false;
    final queryCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Daerah Secara Manual',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: queryCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari kecamatan atau kota (mis. Cikarang)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: palette.loginInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (q) async {
                      setModalState(() => searching = true);
                      final found = await controller.searchPlaces(q);
                      if (ctx.mounted) {
                        setModalState(() {
                          results = found;
                          searching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (searching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'Lokasi tidak ditemukan. Coba kata kunci lain.',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final place = results[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(
                              place.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              place.subtitle,
                              style: TextStyle(color: palette.textSecondary),
                            ),
                            onTap: () {
                              controller.selectPlaceResult(place);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    queryCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gps = controller.gpsModel;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bagian Atas: Top Bar (Logo tepat di tengah) + Judul
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TactilePressable(
                                onTap: () => controller
                                    .navigateTo(AuthScreenStep.register),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: palette.card,
                                    borderRadius: BorderRadius.circular(11),
                                    border:
                                        Border.all(color: palette.cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            Image.asset(
                              FigcraftAssets.shieldLogo,
                              width: 26,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      StaggeredEntrance(
                        delayMs: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Izinkan Akses Lokasi',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Nyalakan lokasi agar THALIA otomatis mendeteksi wilayah Anda untuk pantauan cuaca & sensor sekitar.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 2. Bagian Tengah: Kartu Peta GPS & Google Maps Interaktif
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: StaggeredEntrance(
                      delayMs: 100,
                      child: InteractiveGpsMapCard(
                        palette: palette,
                        gpsModel: gps,
                        onTapRequestGps: controller.requestAndDetectGpsLocation,
                        onMapPointPicked: controller.updatePickedMapPoint,
                      ),
                    ),
                  ),

                  // 3. Bagian Bawah: Kartu Toggle GPS Otomatis (Screenshot 5) + Simpan Lokasi
                  Column(
                    children: [
                      StaggeredEntrance(
                        delayMs: 160,
                        child: _GpsAutomaticToggleCard(
                          palette: palette,
                          isEnabled: gps.isGpsEnabled,
                          isScanning: gps.isScanning,
                          onToggle: controller.toggleGpsAutomatic,
                        ),
                      ),
                      if (controller.locationError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFEA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE07A5F)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_off_rounded,
                                size: 17,
                                color: Color(0xFFB33A22),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.locationError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8C2714),
                                  ),
                                ),
                              ),
                              if (controller.locationPermissionDeniedForever)
                                TextButton(
                                  onPressed: controller.openLocationAppSettings,
                                  child: const Text(
                                    'Pengaturan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      StaggeredEntrance(
                        delayMs: 210,
                        child: PrimaryAuthButton(
                          label: 'Simpan Lokasi',
                          palette: palette,
                          onTap: () => controller.saveDetectedLocation(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TactilePressable(
                          onTap: () => _openManualSearchSheet(context),
                          child: Text(
                            'Pilih Daerah Secara Manual',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                              decoration: TextDecoration.underline,
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
        );
      },
    );
  }
}

/// Kartu putih "GPS Otomatis" dengan ikon crosshair & custom dark toggle switch
/// persis sesuai Screenshot 5.
class _GpsAutomaticToggleCard extends StatelessWidget {
  const _GpsAutomaticToggleCard({
    required this.palette,
    required this.isEnabled,
    required this.isScanning,
    required this.onToggle,
  });

  final ThaliaPalette palette;
  final bool isEnabled;
  final bool isScanning;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.cardBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.isDark
                    ? const Color(0xFF21312E)
                    : const Color(0xFFF2EFE7),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: isScanning
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.textPrimary,
                      ),
                    )
                  : Icon(
                      Icons.gps_fixed_rounded,
                      size: 21,
                      color: palette.textPrimary,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Otomatis',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deteksi lokasi wilayah akurat',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Custom Dark Pill Toggle Switch sesuai Screenshot 5
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 52,
              height: 28,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: isEnabled
                    ? ThaliaColors.forestDark
                    : const Color(0xFFD5D1C6),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment:
                  isEnabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
