import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 1: Dashboard Utama (Frame 59 Musim Hujan Biru & Frame 1303 Kemarau Oren)
/// dilengkapi animasi pemilihan hari, suhu, floating hero card, & pintasan Maps.
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
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _floatController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final climate = widget.climate;
    final forecast = ctrl.currentForecast;
    final useSunCard =
        climate.isOrange || forecast.triggersDryOrangePreview;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Geometry (menempel di puncak layar y = 0) + Tombol Profil Kanan Atas
          SizedBox(
            width: double.infinity,
            height: 190,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final dy =
                          math.sin(_floatController.value * math.pi) * 2.5;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      climate.dashboardHeaderAsset,
                      fit: BoxFit.fill,
                    ),
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

          // 2. Konten Utama Dashboard
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 4, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Lokasi (ketuk untuk langsung ke tab Maps & ubah lokasi)
                TactilePressable(
                  onTap: () => ctrl.selectTab(DashboardTab.maps),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: climate.pillFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: climate.border),
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
                const SizedBox(height: 12),

                // 3. Hero Suhu & Kartu Icon Cuaca Beranimasi
                Row(
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
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutBack,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            duration: const Duration(milliseconds: 240),
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
                            duration: const Duration(milliseconds: 240),
                            child: Text(
                              forecast.conditionSubtitle,
                              key: ValueKey<String>(forecast.conditionSubtitle),
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

                    // Hero Weather Card Asset dari login_ui.figcraft
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, _) {
                        final dy =
                            math.sin(_floatController.value * math.pi) * 4.0;
                        return Transform.translate(
                          offset: Offset(0, -dy),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
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
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Baris 3 Kartu Tri-Habitat (Atmosfer, Hidrosfer, Litosfer)
                Row(
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
                              'Pemantauan kelembapan udara mikro & intensitas curah hujan dari sensor BME280.',
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
                              'Pemantauan kondisi aliran air & kualitas pH air permukaan secara real-time.',
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
                              'Pemantauan kejenuhan air dalam tanah & stabilitas lereng terhadap risiko longsor.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Header Prakiraan Cuaca 5 Hari + Mei 2026
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Prakiraan Cuaca 5 Hari',
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
                        'Mei 2026',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryBrand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 6. Baris 5 Kapsul Vertikal Prakiraan Cuaca Interaktif
                Row(
                  children: List.generate(ctrl.forecastDays.length, (index) {
                    final day = ctrl.forecastDays[index];
                    final isSelected = ctrl.selectedForecastIndex == index;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == ctrl.forecastDays.length - 1 ? 0 : 8,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        duration: const Duration(milliseconds: 260),
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
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 260),
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
