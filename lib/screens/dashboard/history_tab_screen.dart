import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Tab 4: Riwayat Laporan (Frame 347 login_ui.figcraft).
/// Mendukung pull-to-refresh (B04), detail laporan (B23), empty state (B23),
/// serta tombol kirim ulang untuk laporan lokal yang gagal (B13).
class HistoryTabScreen extends StatelessWidget {
  const HistoryTabScreen({
    super.key,
    required this.controller,
    required this.climate,
    this.isStaffVerifier = false,
  });

  final DashboardController controller;
  final ClimatePalette climate;
  final bool isStaffVerifier;

  void _showReportDetail(BuildContext context, FieldReportItemModel report) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: climate.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: climate.primaryDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: climate.pillFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      report.statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: climate.primaryBrand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.timeAndHabitat,
                style: TextStyle(fontSize: 12.5, color: climate.textSecondary),
              ),
              if (report.gpsCoordinates != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Koordinat GPS: ${report.gpsCoordinates}',
                  style: TextStyle(fontSize: 12, color: climate.textSecondary),
                ),
              ],
              if (report.capturedPhotoBytes != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    report.capturedPhotoBytes!,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                report.fullDescription ?? report.metricSummary,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: climate.primaryDark,
                ),
              ),
              if (report.verifiedBy != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: climate.pillFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diverifikasi oleh: ${report.verifiedBy}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: climate.primaryDark,
                        ),
                      ),
                      if (report.verificationNote != null &&
                          report.verificationNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          report.verificationNote!,
                          style: TextStyle(
                            fontSize: 12,
                            color: climate.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (isStaffVerifier &&
                  !report.isCompleted &&
                  !report.isRejected &&
                  !report.isFailed &&
                  !report.id.startsWith('LOCAL-')) ...[
                const SizedBox(height: 16),
                Text(
                  'Verifikasi Petugas / Staff',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: climate.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await controller.verifyReport(
                            report.id,
                            approve: false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB33A22),
                          side: const BorderSide(color: Color(0xFFB33A22)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await controller.verifyReport(
                            report.id,
                            approve: true,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text('Setujui (Asli)'),
                      ),
                    ),
                  ],
                ),
              ],
              if (report.isFailed) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.retryFailedReport(report.id);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Kirim Ulang Laporan'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = controller.reportFilter;
    final reports = controller.filteredReports;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubpageWaveHeader(
              climate: climate,
              eyebrowText: 'Catatan Laporan Lapangan',
              titleText: 'Riwayat Laporan',
              onTapProfile: controller.openProfile,
            ),
            if (controller.isLoading)
              const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFEA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE07A5F)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 16,
                              color: Color(0xFFB33A22),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.loadError!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8C2714),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: controller.refresh,
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

                  // 1. Baris Filter Pill
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

                  // 2. Empty state atau Daftar Kartu Laporan (B23)
                  if (reports.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 34,
                      ),
                      decoration: BoxDecoration(
                        color: climate.cardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: climate.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: climate.textSecondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada laporan pada kategori ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: climate.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gunakan tab Kamera untuk mengirim laporan kondisi lapangan terbaru.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: climate.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(reports.length, (index) {
                      final report = reports[index];
                      return StaggeredEntrance(
                        delayMs: 50 + (index * 55),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReportHistoryCard(
                            report: report,
                            climate: climate,
                            onTap: () => _showReportDetail(context, report),
                            onRetry: report.isFailed
                                ? () => controller.retryFailedReport(report.id)
                                : null,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
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
    required this.onTap,
    this.onRetry,
  });

  final FieldReportItemModel report;
  final ClimatePalette climate;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: climate.cardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: report.isFailed ? const Color(0xFFE07A5F) : climate.border,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: report.isFailed
                      ? const Color(0xFFD9534F)
                      : report.accentBarColor,
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
                              cacheWidth: 120,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: report.isFailed
                                ? const Color(0xFFFFEFEA)
                                : climate.pillFill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '• ${report.statusLabel}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: report.isFailed
                                  ? const Color(0xFFB33A22)
                                  : climate.primaryBrand,
                            ),
                          ),
                        ),
                        if (onRetry != null) ...[
                          const Spacer(),
                          TextButton.icon(
                            onPressed: onRetry,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 15),
                            label: const Text(
                              'Kirim Ulang',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
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
