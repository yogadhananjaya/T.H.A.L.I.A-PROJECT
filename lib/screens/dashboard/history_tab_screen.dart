import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 4: Riwayat Laporan (Frame 347 login_ui.figcraft).
class HistoryTabScreen extends StatelessWidget {
  const HistoryTabScreen({
    super.key,
    required this.controller,
    required this.climate,
  });

  final DashboardController controller;
  final ClimatePalette climate;

  @override
  Widget build(BuildContext context) {
    final filter = controller.reportFilter;
    final reports = controller.filteredReports;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SubpageWaveHeader(
            climate: climate,
            eyebrowText: 'Catatan Laporan Lapangan',
            titleText: 'Riwayat Laporan',
            onTapProfile: controller.openProfile,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Baris Filter Pill: Semua (12) | Selesai (10) | Proses (2)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'Semua (${controller.totalReportsCount})',
                        isSelected: filter == ReportFilterTab.all,
                        climate: climate,
                        onTap: () =>
                            controller.setReportFilter(ReportFilterTab.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Selesai (${controller.completedReportsCount})',
                        isSelected: filter == ReportFilterTab.completed,
                        climate: climate,
                        onTap: () => controller
                            .setReportFilter(ReportFilterTab.completed),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'Proses (${controller.inProgressReportsCount})',
                        isSelected: filter == ReportFilterTab.inProgress,
                        climate: climate,
                        onTap: () => controller
                            .setReportFilter(ReportFilterTab.inProgress),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Daftar Kartu Laporan Lapangan dengan animasi masuk halus
                ...List.generate(reports.length, (index) {
                  final report = reports[index];
                  return StaggeredEntrance(
                    delayMs: 50 + (index * 55),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportHistoryCard(
                        report: report,
                        climate: climate,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.climate,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final ClimatePalette climate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? climate.activeForecastBg : climate.cardFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? climate.activeForecastBg : climate.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : climate.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _ReportHistoryCard extends StatelessWidget {
  const _ReportHistoryCard({
    required this.report,
    required this.climate,
  });

  final FieldReportItemModel report;
  final ClimatePalette climate;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: climate.cardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: climate.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis aksen vertikal kiri sesuai Frame 347
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: report.accentBarColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: climate.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.timeAndHabitat,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: climate.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (report.capturedPhotoBytes != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              report.capturedPhotoBytes!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Image.asset(
                            report.iconAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      report.metricSummary,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: climate.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: climate.pillFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '• ${report.statusLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: climate.primaryBrand,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
