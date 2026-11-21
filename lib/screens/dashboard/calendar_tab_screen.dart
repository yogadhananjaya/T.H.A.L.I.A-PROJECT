import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/figcraft_assets.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 5: Kalender Musim & Riwayat Cuaca (Frame 531 login_ui.figcraft).
class CalendarTabScreen extends StatelessWidget {
  const CalendarTabScreen({
    super.key,
    required this.controller,
    required this.climate,
  });

  final DashboardController controller;
  final ClimatePalette climate;

  static const List<String> _weekHeaders = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  static const List<({int number, bool isCurrentMonth})> _calendarCells = [
    (number: 27, isCurrentMonth: false),
    (number: 28, isCurrentMonth: false),
    (number: 29, isCurrentMonth: false),
    (number: 30, isCurrentMonth: false),
    (number: 1, isCurrentMonth: true),
    (number: 2, isCurrentMonth: true),
    (number: 3, isCurrentMonth: true),
    (number: 4, isCurrentMonth: true),
    (number: 5, isCurrentMonth: true),
    (number: 6, isCurrentMonth: true),
    (number: 7, isCurrentMonth: true),
    (number: 8, isCurrentMonth: true),
    (number: 9, isCurrentMonth: true),
    (number: 10, isCurrentMonth: true),
    (number: 11, isCurrentMonth: true),
    (number: 12, isCurrentMonth: true),
    (number: 13, isCurrentMonth: true),
    (number: 14, isCurrentMonth: true),
    (number: 15, isCurrentMonth: true),
    (number: 16, isCurrentMonth: true),
    (number: 17, isCurrentMonth: true),
    (number: 18, isCurrentMonth: true),
    (number: 19, isCurrentMonth: true),
    (number: 20, isCurrentMonth: true),
    (number: 21, isCurrentMonth: true),
    (number: 22, isCurrentMonth: true),
    (number: 23, isCurrentMonth: true),
    (number: 24, isCurrentMonth: true),
    (number: 25, isCurrentMonth: true),
    (number: 26, isCurrentMonth: true),
    (number: 27, isCurrentMonth: true),
    (number: 28, isCurrentMonth: true),
    (number: 29, isCurrentMonth: true),
    (number: 30, isCurrentMonth: true),
    (number: 31, isCurrentMonth: true),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedDay = controller.selectedCalendarDay;
    final isRainyDay =
        DashboardController.rainyCalendarDays.contains(selectedDay);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Siklus Musim & Riwayat Cuaca',
            titleText: 'Mei 2026',
            onTapProfile: controller.openProfile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
            child: Column(
              children: [
                // 1. Kartu Grid Kalender Bulanan sesuai Frame 531
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: climate.border),
                  ),
                  child: Column(
                    children: [
                      // Header Hari S S R K J S M
                      Row(
                        children: List.generate(_weekHeaders.length, (i) {
                          final isWeekend = i >= 5;
                          return Expanded(
                            child: Center(
                              child: Text(
                                _weekHeaders[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isWeekend
                                      ? climate.primaryBrand
                                      : climate.primaryDark,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),

                      // 5 Baris Minggu
                      ...List.generate(5, (weekIndex) {
                        final rowCells = _calendarCells
                            .skip(weekIndex * 7)
                            .take(7)
                            .toList();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: rowCells.map((cell) {
                              final isSelected = cell.isCurrentMonth &&
                                  cell.number == selectedDay;
                              final hasRainMarker = cell.isCurrentMonth &&
                                  DashboardController.rainyCalendarDays
                                      .contains(cell.number);
                              final isLightRainBadge =
                                  cell.number == 8 || cell.number == 23;

                              Color bgColor = Colors.transparent;
                              Color textColor = cell.isCurrentMonth
                                  ? climate.primaryDark
                                  : climate.textSecondary
                                      .withValues(alpha: 0.45);

                              if (isSelected) {
                                bgColor = climate.activeForecastBg;
                                textColor = Colors.white;
                              } else if (hasRainMarker) {
                                bgColor = isLightRainBadge
                                    ? const Color(0xFF7CBDE9)
                                    : climate.primaryBrand;
                                textColor = isLightRainBadge
                                    ? climate.primaryDark
                                    : Colors.white;
                              }

                              return Expanded(
                                child: Center(
                                  child: TactilePressable(
                                    onTap: cell.isCurrentMonth
                                        ? () => controller
                                            .selectCalendarDay(cell.number)
                                        : null,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 38,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${cell.number}',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: (isSelected ||
                                                      hasRainMarker)
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          if (hasRainMarker || isSelected) ...[
                                            const SizedBox(height: 2),
                                            Icon(
                                              Icons.water_drop_rounded,
                                              size: 11,
                                              color: textColor,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Kartu Ringkasan Tanggal Terpilih Bawah sesuai Frame 531
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: climate.cardFill,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: climate.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: climate.activeForecastBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'HARI INI • $selectedDay MEI',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: climate.pillFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '• Status Aman',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: climate.primaryBrand,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Image.asset(
                            isRainyDay
                                ? FigcraftAssets.weatherIconRain
                                : FigcraftAssets.weatherIconPartly,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isRainyDay
                            ? 'Hujan Ringan • 26°C'
                            : 'Berawan Cerah • 28°C',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRainyDay
                            ? 'Kelembapan 77%, curah hujan 2.0 mm/jam.'
                            : 'Kelembapan 68%, curah hujan 0.2 mm/jam.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryBrand,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Keterangan: Aman beraktivitas, siapkan payung.',
                        style: TextStyle(
                          fontSize: 12,
                          color: climate.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• Hari Ini   • Hujan Lebat   • Hujan Ringan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryDark,
                        ),
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
