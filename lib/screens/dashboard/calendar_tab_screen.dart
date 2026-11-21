import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/figcraft_assets.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 5: Kalender Musim & Riwayat Cuaca.
/// Grid dibangun dinamis dari tanggal sistem [DateTime.now()] dan data prakiraan API (B26).
class CalendarTabScreen extends StatelessWidget {
  const CalendarTabScreen({
    super.key,
    required this.controller,
    required this.climate,
  });

  final DashboardController controller;
  final ClimatePalette climate;

  static const List<String> _weekHeaders = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _monthShorts = [
    'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
  ];

  /// Membangun sel kalender 5/6 minggu dinamis untuk [month] (Senin sebagai hari ke-1).
  List<({int number, bool isCurrentMonth})> _buildCellsForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final prevMonthDays = DateTime(month.year, month.month, 0).day;
    final leading = firstDay.weekday - 1; // 0 = Senin, 6 = Minggu

    final cells = <({int number, bool isCurrentMonth})>[];
    for (int i = leading - 1; i >= 0; i--) {
      cells.add((number: prevMonthDays - i, isCurrentMonth: false));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add((number: d, isCurrentMonth: true));
    }
    var nextDay = 1;
    while (cells.length % 7 != 0) {
      cells.add((number: nextDay++, isCurrentMonth: false));
    }
    return cells;
  }

  /// Mencari prakiraan API untuk tanggal terpilih bila masuk dalam rentang prakiraan.
  ForecastDayModel? _forecastForDay(int day) {
    final now = DateTime.now();
    for (final f in controller.forecastDays) {
      final parts = f.dateShort.split('/');
      if (parts.length == 2) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (d == day && m == now.month) return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final month = controller.calendarMonth;
    final selectedDay = controller.selectedCalendarDay;
    final rainyDays = controller.rainyCalendarDays;
    final cells = _buildCellsForMonth(month);
    final weekCount = (cells.length / 7).ceil();
    final monthTitle = '${_monthNames[month.month - 1]} ${month.year}';
    final monthShort = _monthShorts[month.month - 1];
    final isToday = selectedDay == DateTime.now().day &&
        month.month == DateTime.now().month &&
        month.year == DateTime.now().year;

    final dayForecast = _forecastForDay(selectedDay);
    final isRainyDay = rainyDays.contains(selectedDay) ||
        (dayForecast?.conditionTitle.toLowerCase().contains('hujan') ?? false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Siklus Musim & Riwayat Cuaca',
            titleText: monthTitle,
            onTapProfile: controller.openProfile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
            child: Column(
              children: [
                // 1. Kartu Grid Kalender Bulanan Dinamis
                StaggeredEntrance(
                  delayMs: 40,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    decoration: BoxDecoration(
                      color: climate.cardFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: climate.border),
                    ),
                    child: Column(
                      children: [
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
                        ...List.generate(weekCount, (weekIndex) {
                          final rowCells =
                              cells.skip(weekIndex * 7).take(7).toList();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: rowCells.map((cell) {
                                final isSelected = cell.isCurrentMonth &&
                                    cell.number == selectedDay;
                                final hasRainMarker = cell.isCurrentMonth &&
                                    rainyDays.contains(cell.number);

                                Color bgColor = Colors.transparent;
                                Color textColor = cell.isCurrentMonth
                                    ? climate.primaryDark
                                    : climate.textSecondary
                                        .withValues(alpha: 0.45);

                                if (isSelected) {
                                  bgColor = climate.activeForecastBg;
                                  textColor = Colors.white;
                                } else if (hasRainMarker) {
                                  bgColor = climate.pillFill;
                                  textColor = climate.primaryBrand;
                                }

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: TactilePressable(
                                      onTap: cell.isCurrentMonth
                                          ? () => controller
                                              .selectCalendarDay(cell.number)
                                          : null,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${cell.number}',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
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
                ),
                const SizedBox(height: 14),

                // 2. Kartu Ringkasan Tanggal Terpilih (dari API prakiraan, B26)
                StaggeredEntrance(
                  delayMs: 110,
                  child: Container(
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
                                '${isToday ? 'HARI INI' : 'TANGGAL'} • $selectedDay $monthShort',
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
                                dayForecast != null
                                    ? '• ${dayForecast.conditionSubtitle.split('•').last.trim()}'
                                    : '• Data Historis',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryBrand,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              dayForecast?.iconAsset ??
                                  (isRainyDay
                                      ? FigcraftAssets.weatherIconRain
                                      : FigcraftAssets.weatherIconPartly),
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dayForecast != null
                              ? '${dayForecast.conditionTitle} • ${dayForecast.temperatureC}°C'
                              : 'Pantauan Wilayah • ${controller.currentForecast.temperatureC}°C',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: climate.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayForecast != null
                              ? '${dayForecast.humidityText}, ${dayForecast.waterLevelText}, ${dayForecast.soilText}.'
                              : 'Tidak ada anomali cuaca ekstrem tercatat pada tanggal ini.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: climate.primaryBrand,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayForecast != null
                              ? 'Ringkasan sensor: ${dayForecast.conditionSubtitle}'
                              : 'Pilih tanggal berikon tetesan air untuk melihat prakiraan hujan terkini.',
                          style: TextStyle(
                            fontSize: 12,
                            color: climate.textSecondary,
                          ),
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
