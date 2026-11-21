import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 1: Dashboard Utama (Frame 59 Musim Hujan Biru & Frame 1303 Kemarau Oren)
/// memiliki animasi idle khusus pada bagian kubah & tetesan hujan biru di atas (Screenshot 2),
/// sementara elemen bawah hanya menggunakan animasi masuk sekali jalan yang halus.
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({
    super.key,
    required this.controller,
    required this.climate,
    required this.locationName,
  });

  final DashboardController controller;
  final ClimatePalette climate;
  final String locationName;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _topHeaderIdleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _topHeaderIdleController.dispose();
    super.dispose();
  }

  void _showHabitatDetailSheet(
    BuildContext context, {
    required String title,
    required String value,
    required String description,
  }) {
    final climate = widget.climate;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: climate.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Habitat • $title',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: climate.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: climate.primaryBrand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: climate.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _currentMonthYearLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final climate = widget.climate;
    final forecast = ctrl.currentForecast;
    final useSunCard =
        climate.isOrange || forecast.triggersDryOrangePreview;

    return RefreshIndicator(
      onRefresh: ctrl.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 1. Header Geometry Atas dengan Animasi Idle Kubah & Tetesan Air (Screenshot 2)
          SizedBox(
            width: double.infinity,
            height: 194,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _topHeaderIdleController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _AnimatedDashboardTopHeaderPainter(
                          climate: climate,
                          progress: _topHeaderIdleController.value,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 44,
                  right: 20,
                  child: TactilePressable(
                    onTap: ctrl.openProfile,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: climate.primaryDark.withValues(alpha: 0.36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Konten Utama Dashboard (Hanya Animasi Masuk Halus, Tanpa Animasi Idle)
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 2, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Lokasi (ketuk untuk langsung ke tab Maps & ubah lokasi)
                StaggeredEntrance(
                  delayMs: 30,
                  child: TactilePressable(
                    onTap: () => ctrl.selectTab(DashboardTab.maps),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: climate.pillFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: climate.isOrange
                              ? climate.accentHighlight
                              : climate.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: climate.primaryBrand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.locationName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: climate.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Indikator status pemuatan, galat server, atau mode data contoh (B04)
                if (ctrl.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(minHeight: 3),
                    ),
                  ),
                if (ctrl.loadError != null || ctrl.isSampleData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ctrl.loadError != null
                            ? const Color(0xFFFFEFEA)
                            : climate.pillFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ctrl.loadError != null
                              ? const Color(0xFFE07A5F)
                              : climate.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ctrl.loadError != null
                                ? Icons.cloud_off_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: ctrl.loadError != null
                                ? const Color(0xFFB33A22)
                                : climate.primaryBrand,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ctrl.loadError ??
                                  'Menampilkan data contoh (mode simulasi lokal).',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: ctrl.loadError != null
                                    ? const Color(0xFF8C2714)
                                    : climate.textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: ctrl.isLoading ? null : ctrl.refresh,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Muat Ulang',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Hero Suhu & Kartu Icon Cuaca
                StaggeredEntrance(
                  delayMs: 65,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 24,
                                    end: forecast.temperatureC.toDouble(),
                                  ),
                                  duration: const Duration(milliseconds: 360),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, val, _) {
                                    return Text(
                                      '${val.round()}',
                                      style: TextStyle(
                                        fontSize: 78,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                        letterSpacing: -3.0,
                                        color: climate.primaryDark,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 15,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: climate.accentHighlight,
                                            width: 2.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'C',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                          color: climate.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                forecast.conditionTitle,
                                key: ValueKey<String>(forecast.conditionTitle),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: climate.isOrange
                                      ? climate.primaryBrand
                                      : climate.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                forecast.conditionSubtitle,
                                key: ValueKey<String>(
                                  forecast.conditionSubtitle,
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: climate.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: Image.asset(
                          useSunCard
                              ? 'assets/images/hero_weather_sun_card.png'
                              : 'assets/images/hero_weather_rain_card.png',
                          key: ValueKey<bool>(useSunCard),
                          width: 114,
                          height: 112,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Baris 3 Kartu Tri-Habitat (Atmosfer, Hidrosfer, Litosfer)
                StaggeredEntrance(
                  delayMs: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TriHabitatMiniCard(
                          title: 'Atmosfer',
                          valueText: forecast.humidityText,
                          dotColor: climate.warmDot,
                          climate: climate,
                          onTap: () => _showHabitatDetailSheet(
                            context,
                            title: 'Atmosfer',
                            value: forecast.humidityText,
                            description:
                                'Pemantauan suhu & kelembapan udara mikro serta tekanan atmosfer (${forecast.conditionSubtitle}).',
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _TriHabitatMiniCard(
                          title: 'Hidrosfer',
                          valueText: forecast.waterLevelText,
                          dotColor: climate.primaryBrand,
                          climate: climate,
                          onTap: () => _showHabitatDetailSheet(
                            context,
                            title: 'Hidrosfer',
                            value: forecast.waterLevelText,
                            description:
                                'Pemantauan tinggi muka air & intensitas hujan permukaan secara real-time (${forecast.waterLevelText}).',
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _TriHabitatMiniCard(
                          title: 'Litosfer',
                          valueText: forecast.soilText,
                          dotColor: climate.accentHighlight,
                          climate: climate,
                          onTap: () => _showHabitatDetailSheet(
                            context,
                            title: 'Litosfer',
                            value: forecast.soilText,
                            description:
                                'Pemantauan kejenuhan air dalam tanah & stabilitas lereng terhadap risiko longsor (${forecast.soilText}).',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Header Prakiraan Cuaca dinamis + Bulan/Tahun Sistem (B26, B28)
                StaggeredEntrance(
                  delayMs: 135,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Prakiraan Cuaca ${ctrl.forecastDays.length} Hari',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: climate.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ctrl.selectTab(DashboardTab.calendar),
                        child: Text(
                          _currentMonthYearLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: climate.primaryBrand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 6. Baris Kapsul Vertikal Prakiraan Cuaca Interaktif (scroll bila > 5 hari, B28)
                StaggeredEntrance(
                  delayMs: 170,
                  child: ctrl.forecastDays.length <= 5
                      ? Row(
                          children: List.generate(ctrl.forecastDays.length, (index) {
                            final day = ctrl.forecastDays[index];
                            final isSelected = ctrl.selectedForecastIndex == index;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == ctrl.forecastDays.length - 1
                                      ? 0
                                      : 8,
                                ),
                                child: _ForecastDayCapsule(
                                  day: day,
                                  isSelected: isSelected,
                                  climate: climate,
                                  onTap: () => ctrl.selectForecastDay(index),
                                ),
                              ),
                            );
                          }),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(ctrl.forecastDays.length, (index) {
                              final day = ctrl.forecastDays[index];
                              final isSelected = ctrl.selectedForecastIndex == index;
                              return SizedBox(
                                width: 68,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == ctrl.forecastDays.length - 1
                                        ? 0
                                        : 8,
                                  ),
                                  child: _ForecastDayCapsule(
                                    day: day,
                                    isSelected: isSelected,
                                    climate: climate,
                                    onTap: () => ctrl.selectForecastDay(index),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Painter vektor presisi node 1248 dari login_ui.figcraft (Screenshot 2)
/// dengan animasi idle halus pada kubah awan biru & 3 tangkai tetesan hujan.
class _AnimatedDashboardTopHeaderPainter extends CustomPainter {
  const _AnimatedDashboardTopHeaderPainter({
    required this.climate,
    required this.progress,
  });

  final ClimatePalette climate;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390.0;
    final sy = size.height / 196.0;
    final s1 = math.sin(progress * math.pi) * 4.5 * sy;
    final s2 = math.cos(progress * math.pi) * 3.8 * sy;

    if (climate.isOrange) {
      // Varian Kemarau Panjang / Cuaca Panas (Oren) - Presisi SVG Node 1304
      // 1. Sunbeam Peach Halo (#FBE3C8)
      final haloPath = Path()
        ..moveTo(0, 0)
        ..lineTo(390 * sx, 0)
        ..lineTo(390 * sx, 154 * sy + s1 * 0.5)
        ..cubicTo(
          296.67 * sx,
          174 * sy + s1,
          204.67 * sx,
          167.33 * sy - s2,
          114 * sx,
          134 * sy + s1 * 0.6,
        )
        ..cubicTo(
          67.33 * sx,
          116.67 * sy,
          29.33 * sx,
          114.67 * sy,
          0,
          128 * sy,
        )
        ..close();
      canvas.drawPath(haloPath, Paint()..color = const Color(0xFFFBE3C8));

      // 2. Sun Burnt Left Arc (#B52D1E)
      final leftArc = Path()
        ..moveTo(0, 0)
        ..lineTo(184 * sx, 0)
        ..cubicTo(
          164 * sx,
          78.67 * sy + s2 * 0.5,
          102.67 * sx,
          116 * sy - s1 * 0.5,
          0,
          112 * sy,
        )
        ..close();
      canvas.drawPath(leftArc, Paint()..color = const Color(0xFFB52D1E));

      // 3. Solar Orange Main Disc (#DF4E26) - center (259, 55), r = 107
      canvas.drawCircle(
        Offset(259 * sx, 55 * sy + s1 * 0.4),
        (107 + progress * 2.0) * sx,
        Paint()..color = const Color(0xFFDF4E26),
      );

      // 4. Solar Gold Inner Sun (#F4A938) - center (277, 39), r = 63
      canvas.drawCircle(
        Offset(277 * sx, 39 * sy - s2 * 0.4),
        (63 + progress * 2.5) * sx,
        Paint()..color = const Color(0xFFF4A938),
      );

      // 5. Tiga Sinar Matahari Bawah (Node 1309, 1310, 1311) dengan animasi idle
      final rayShift = s1 * 1.1;
      canvas.drawLine(
        Offset(170 * sx, 146 * sy),
        Offset(162 * sx, 170 * sy + rayShift),
        Paint()
          ..color = const Color(0xFFB52D1E)
          ..strokeWidth = 2.5 * sx
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(254 * sx, 162 * sy),
        Offset(254 * sx, 184 * sy - s2 * 1.2),
        Paint()
          ..color = const Color(0xFFDF4E26)
          ..strokeWidth = 2.5 * sx
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(326 * sx, 146 * sy),
        Offset(334 * sx, 170 * sy + rayShift),
        Paint()
          ..color = const Color(0xFFF4A938)
          ..strokeWidth = 2.5 * sx
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // 1. Rain Mist Left Base (#BAD8EE) - x: -14, y: -16, w: 192, h: 152
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-14 * sx, -16 * sy, 192 * sx, 152 * sy + s1 * 0.5),
        bottomRight: Radius.circular(84 * sx),
        bottomLeft: Radius.circular(56 * sx),
      ),
      Paint()..color = const Color(0xFFBAD8EE),
    );

    // 2. Rain Navy Cloud Arch (#152F4E) - x: 42, y: -20, w: 162, h: 156
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(42 * sx, -20 * sy, 162 * sx, 156 * sy - s2 * 0.5),
        bottomLeft: Radius.circular(81 * sx),
        bottomRight: Radius.circular(81 * sx),
      ),
      Paint()..color = const Color(0xFF152F4E),
    );

    // 3. Rain Cobalt Dome (#255E94) - x: 154, y: -10, w: 154, h: 168
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(154 * sx, -10 * sy, 154 * sx, 168 * sy + s1 * 0.7),
        bottomLeft: Radius.circular(77 * sx),
        bottomRight: Radius.circular(77 * sx),
      ),
      Paint()..color = const Color(0xFF255E94),
    );

    // 4. Rain Sky Blue Orb (#64AEE0) - x: 254, y: -26, w: 156, h: 156
    canvas.drawOval(
      Rect.fromLTWH(
        254 * sx + s2 * 0.4,
        -26 * sy + s1 * 0.4,
        156 * sx,
        156 * sy,
      ),
      Paint()..color = const Color(0xFF64AEE0),
    );

    // 5. Rain Ice Highlight (#91C8EC) - x: 226, y: 66, w: 78, h: 78
    canvas.drawOval(
      Rect.fromLTWH(
        226 * sx - s1 * 0.5,
        66 * sy - s2 * 0.5,
        78 * sx,
        78 * sy,
      ),
      Paint()..color = const Color(0xFF91C8EC),
    );

    // 6. Tangkai & Tetesan Hujan 1 (x: 102, y: 136..168, tip y: 176)
    final drop1Shift = s1 * 1.3;
    canvas.drawLine(
      Offset(102 * sx, 134 * sy),
      Offset(102 * sx, 168 * sy + drop1Shift),
      Paint()
        ..color = const Color(0xFF152F4E)
        ..strokeWidth = 2.0 * sx
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(102 * sx, 176 * sy + drop1Shift),
      4.2 * sx,
      Paint()..color = const Color(0xFF64AEE0),
    );

    // 7. Tangkai & Tetesan Hujan 2 (x: 204, y: 156..180, tip y: 188)
    final drop2Shift = -s2 * 1.2;
    canvas.drawLine(
      Offset(204 * sx, 154 * sy),
      Offset(204 * sx, 180 * sy + drop2Shift),
      Paint()
        ..color = const Color(0xFF255E94)
        ..strokeWidth = 2.0 * sx
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(204 * sx, 188 * sy + drop2Shift),
      4.2 * sx,
      Paint()..color = const Color(0xFF255E94),
    );

    // 8. Tangkai & Tetesan Hujan 3 (x: 265, y: 142..176, tip y: 184)
    final drop3Shift = s2 * 1.4;
    canvas.drawLine(
      Offset(265 * sx, 140 * sy),
      Offset(265 * sx, 176 * sy + drop3Shift),
      Paint()
        ..color = const Color(0xFF64AEE0)
        ..strokeWidth = 2.0 * sx
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(265 * sx, 184 * sy + drop3Shift),
      4.2 * sx,
      Paint()..color = const Color(0xFF152F4E),
    );
  }

  @override
  bool shouldRepaint(
    covariant _AnimatedDashboardTopHeaderPainter oldDelegate,
  ) =>
      oldDelegate.progress != progress || oldDelegate.climate != climate;
}

class _TriHabitatMiniCard extends StatelessWidget {
  const _TriHabitatMiniCard({
    required this.title,
    required this.valueText,
    required this.dotColor,
    required this.climate,
    required this.onTap,
  });

  final String title;
  final String valueText;
  final Color dotColor;
  final ClimatePalette climate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: climate.cardFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: climate.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: climate.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                valueText,
                key: ValueKey<String>(valueText),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: climate.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastDayCapsule extends StatelessWidget {
  const _ForecastDayCapsule({
    required this.day,
    required this.isSelected,
    required this.climate,
    required this.onTap,
  });

  final ForecastDayModel day;
  final bool isSelected;
  final ClimatePalette climate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 196,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? climate.activeForecastBg : climate.cardFill,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? climate.primaryBrand : climate.border,
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: climate.activeForecastBg.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  day.dayShort,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : climate.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.dateShort,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.78)
                        : climate.textSecondary,
                  ),
                ),
              ],
            ),
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              child: Image.asset(
                day.iconAsset,
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              '${day.temperatureC}°',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? climate.warmDot : climate.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
