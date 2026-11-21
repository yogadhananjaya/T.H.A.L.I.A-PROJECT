import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/figcraft_assets.dart';

/// Navigasi 5 Tab Utama di Dashboard Shell sesuai login_ui.figcraft.
enum DashboardTab {
  home('Home'),
  maps('Maps'),
  camera('Kamera'),
  history('Riwayat'),
  calendar('Kalender');

  const DashboardTab(this.label);
  final String label;
}

/// Tema Musim: Musim Hujan (Biru - Default Basic) vs Kemarau Panjang (Oren).
enum SeasonMode {
  rainyBlue('Musim Hujan (Biru)'),
  dryOrange('Kemarau Panjang (Oren)');

  const SeasonMode(this.label);
  final String label;
}

/// Kelas OOP Palet Musim Dinamis (Biru Musim Hujan vs Oren Kemarau Panjang).
final class ClimatePalette {
  const ClimatePalette({
    required this.season,
    this.isDark = false,
  });

  final SeasonMode season;
  final bool isDark;

  bool get isOrange => season == SeasonMode.dryOrange;

  Color get canvas => isDark
      ? const Color(0xFF0E1A26)
      : (isOrange ? const Color(0xFFFAF5F0) : const Color(0xFFF4F7FA));

  Color get primaryDark => isDark
      ? const Color(0xFFF2F7FC)
      : (isOrange ? const Color(0xFF3D1512) : const Color(0xFF132B47));

  Color get primaryBrand =>
      isOrange ? const Color(0xFFB52D1E) : const Color(0xFF245E96);

  Color get accentHighlight =>
      isOrange ? const Color(0xFFDF4E26) : const Color(0xFF2B70B0);

  Color get warmDot =>
      isOrange ? const Color(0xFFF4A938) : const Color(0xFFDF9A42);

  Color get cardFill => isDark
      ? const Color(0xFF16283B)
      : (isOrange ? const Color(0xFFF2E6DC) : const Color(0xFFE7EFF6));

  Color get pillFill => isDark
      ? const Color(0xFF1E364F)
      : (isOrange ? const Color(0xFFFBE3C8) : const Color(0xFFDCEBF7));

  Color get surfaceWhite =>
      isDark ? const Color(0xFF132435) : const Color(0xFFFFFFFF);

  Color get border => isDark
      ? const Color(0xFF28435C)
      : (isOrange ? const Color(0xFFE5D1C3) : const Color(0xFFD0DFEC));

  Color get textSecondary => isDark
      ? const Color(0xFF9AB2C9)
      : (isOrange ? const Color(0xFF6E5A4F) : const Color(0xFF51697D));

  Color get activeForecastBg =>
      isOrange ? const Color(0xFFB52D1E) : const Color(0xFF132B47);

  String get dashboardHeaderAsset => isOrange
      ? FigcraftAssets.dashboardHeaderOrange
      : FigcraftAssets.dashboardHeaderBlue;

  String get subpageWaveAsset => isOrange
      ? FigcraftAssets.subpageWaveOrange
      : FigcraftAssets.subpageWaveBlue;

  String get heroWeatherCardAsset => isOrange
      ? FigcraftAssets.heroWeatherSunCard
      : FigcraftAssets.heroWeatherRainCard;
}

/// Model OOP untuk Kartu Tri-Habitat di Dashboard (Atmosfer, Hidrosfer, Litosfer).
final class HabitatMetricCardModel {
  const HabitatMetricCardModel({
    required this.title,
    required this.valueText,
    required this.dotColor,
    required this.detailDescription,
  });

  final String title;
  final String valueText;
  final Color dotColor;
  final String detailDescription;
}

/// Model OOP untuk Prakiraan Cuaca 5 Hari di Dashboard.
final class ForecastDayModel {
  const ForecastDayModel({
    required this.dayShort,
    required this.dateShort,
    required this.temperatureC,
    required this.conditionTitle,
    required this.conditionSubtitle,
    required this.iconAsset,
    required this.humidityText,
    required this.waterLevelText,
    required this.soilText,
    this.triggersDryOrangePreview = false,
  });

  final String dayShort;
  final String dateShort;
  final int temperatureC;
  final String conditionTitle;
  final String conditionSubtitle;
  final String iconAsset;
  final String humidityText;
  final String waterLevelText;
  final String soilText;
  final bool triggersDryOrangePreview;
}

enum ReportFilterTab {
  all('Semua'),
  completed('Selesai'),
  inProgress('Proses');

  const ReportFilterTab(this.label);
  final String label;
}

/// Model OOP untuk Riwayat Laporan Lapangan (Frame 5 & Hasil Input Kamera).
final class FieldReportItemModel {
  const FieldReportItemModel({
    required this.id,
    required this.title,
    required this.timeAndHabitat,
    required this.metricSummary,
    required this.statusLabel,
    required this.isCompleted,
    required this.iconAsset,
    required this.accentBarColor,
    this.capturedPhotoBytes,
    this.categoryLabel,
    this.gpsCoordinates,
  });

  final String id;
  final String title;
  final String timeAndHabitat;
  final String metricSummary;
  final String statusLabel;
  final bool isCompleted;
  final String iconAsset;
  final Color accentBarColor;
  final Uint8List? capturedPhotoBytes;
  final String? categoryLabel;
  final String? gpsCoordinates;
}
