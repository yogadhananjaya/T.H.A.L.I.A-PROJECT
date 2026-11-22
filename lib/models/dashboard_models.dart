import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/figcraft_assets.dart';
import 'api_models.dart';

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
/// Mendukung [orangeBlend] (0.0 = Biru penuh, 1.0 = Oren penuh) untuk transisi warna slow-morph.
final class ClimatePalette {
  const ClimatePalette({
    required this.season,
    this.isDark = false,
    double? orangeBlend,
  }) : orangeBlend = orangeBlend ?? (season == SeasonMode.dryOrange ? 1.0 : 0.0);

  final SeasonMode season;
  final bool isDark;
  final double orangeBlend;

  bool get isOrange => orangeBlend >= 0.5;

  Color _blend(Color blue, Color orange) =>
      Color.lerp(blue, orange, orangeBlend.clamp(0.0, 1.0))!;

  Color get canvas => isDark
      ? const Color(0xFF0E1A26)
      : _blend(const Color(0xFFF4F7FA), const Color(0xFFFAF5F0));

  Color get primaryDark => isDark
      ? const Color(0xFFF2F7FC)
      : _blend(const Color(0xFF132B47), const Color(0xFF3D1512));

  Color get primaryBrand =>
      _blend(const Color(0xFF245E96), const Color(0xFFB52D1E));

  Color get accentHighlight =>
      _blend(const Color(0xFF2B70B0), const Color(0xFFDF4E26));

  Color get warmDot =>
      _blend(const Color(0xFFDF9A42), const Color(0xFFF4A938));

  Color get cardFill => isDark
      ? const Color(0xFF16283B)
      : _blend(const Color(0xFFE7EFF6), const Color(0xFFF2E6DC));

  Color get pillFill => isDark
      ? const Color(0xFF1E364F)
      : _blend(const Color(0xFFDCEBF7), const Color(0xFFFBE3C8));

  Color get surfaceWhite =>
      isDark ? const Color(0xFF132435) : const Color(0xFFFFFFFF);

  Color get border => isDark
      ? const Color(0xFF28435C)
      : _blend(const Color(0xFFD0DFEC), const Color(0xFFE5D1C3));

  Color get textSecondary => isDark
      ? const Color(0xFF9AB2C9)
      : _blend(const Color(0xFF51697D), const Color(0xFF6E5A4F));

  Color get activeForecastBg =>
      _blend(const Color(0xFF132B47), const Color(0xFFB52D1E));

  String get heroWeatherCardAsset => isOrange
      ? FigcraftAssets.heroWeatherSunCard
      : FigcraftAssets.heroWeatherRainCard;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClimatePalette &&
          season == other.season &&
          isDark == other.isDark &&
          orangeBlend == other.orangeBlend;

  @override
  int get hashCode => Object.hash(season, isDark, orangeBlend);
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

/// Status risiko per habitat/hari yang dihitung backend (rule-based).
enum RiskStatus {
  safe('aman', 'Aman'),
  warning('waspada', 'Waspada'),
  danger('bahaya', 'Bahaya');

  const RiskStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// Nilai tidak dikenal dianggap Aman.
  static RiskStatus fromApi(String? value) {
    final v = (value ?? '').toLowerCase();
    for (final status in RiskStatus.values) {
      if (status.apiValue == v) return status;
    }
    return RiskStatus.safe;
  }
}

const List<String> _dayShortNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const List<String> _monthShortNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _two(int n) => n.toString().padLeft(2, '0');

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

  /// Membaca satu hari prakiraan dari JSON backend. Kontrak lengkap di API_INTEGRATION.md.
  /// Field wajib minimal: `date` (YYYY-MM-DD) dan `condition_code`; sisanya opsional.
  factory ForecastDayModel.fromJson(Map<String, dynamic> json) {
    final code = (json['condition_code'] as String? ?? '').toLowerCase();
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    final rain = (json['rainfall_mm_per_hour'] as num?)?.toDouble();
    final humidity = (json['humidity_pct'] as num?)?.round();
    final water = (json['water_level_cm'] as num?)?.round();
    final soil = (json['soil_moisture_pct'] as num?)?.round();
    final status = RiskStatus.fromApi(json['status'] as String?);

    final rainText = rain == null ? '-' : rain.toStringAsFixed(1);
    final subtitle = json['condition_subtitle'] as String? ??
        'Curah $rainText mm/jam • Status ${status.label}';

    final seasonMode = (json['season_mode'] as String? ?? '').toLowerCase();
    final isDryOrange = seasonMode == 'dry_orange' ||
        (seasonMode.isEmpty && (code == 'sunny' || code == 'clear'));

    return ForecastDayModel(
      dayShort: json['day_short'] as String? ??
          (date == null ? '-' : _dayShortNames[date.weekday - 1]),
      dateShort: date == null ? '-' : '${date.day}/${date.month}',
      temperatureC: (json['temperature_c'] as num?)?.round() ?? 0,
      conditionTitle: json['condition_title'] as String? ?? _conditionTitle(code),
      conditionSubtitle: subtitle,
      iconAsset: _conditionIcon(code),
      humidityText: 'Lembap ${humidity ?? '-'}%',
      waterLevelText: 'Air ${water ?? '-'} cm',
      soilText: 'Tanah ${soil ?? '-'}%',
      triggersDryOrangePreview: isDryOrange,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'dayShort': dayShort,
        'dateShort': dateShort,
        'temperatureC': temperatureC,
        'conditionTitle': conditionTitle,
        'conditionSubtitle': conditionSubtitle,
        'iconAsset': iconAsset,
        'humidityText': humidityText,
        'waterLevelText': waterLevelText,
        'soilText': soilText,
        'triggersDryOrangePreview': triggersDryOrangePreview,
      };

  factory ForecastDayModel.fromCacheJson(Map<String, dynamic> json) {
    return ForecastDayModel(
      dayShort: json['dayShort'] as String? ?? '-',
      dateShort: json['dateShort'] as String? ?? '-',
      temperatureC: (json['temperatureC'] as num?)?.round() ?? 0,
      conditionTitle: json['conditionTitle'] as String? ?? 'Cerah',
      conditionSubtitle: json['conditionSubtitle'] as String? ?? '-',
      iconAsset: json['iconAsset'] as String? ?? FigcraftAssets.weatherIconPartly,
      humidityText: json['humidityText'] as String? ?? 'Lembap -%',
      waterLevelText: json['waterLevelText'] as String? ?? 'Air - cm',
      soilText: json['soilText'] as String? ?? 'Tanah -%',
      triggersDryOrangePreview: json['triggersDryOrangePreview'] as bool? ?? false,
    );
  }

  static String _conditionTitle(String code) {
    switch (code) {
      case 'sunny':
      case 'clear':
        return 'Cerah Terik';
      case 'partly_cloudy':
        return 'Berawan Cerah';
      case 'cloudy':
        return 'Mendung Tebal';
      case 'light_rain':
        return 'Hujan Ringan';
      case 'rain':
        return 'Hujan Lebat';
      case 'storm':
      case 'thunderstorm':
        return 'Hujan Petir';
      default:
        return 'Berawan';
    }
  }

  static String _conditionIcon(String code) {
    switch (code) {
      case 'sunny':
      case 'clear':
        return FigcraftAssets.weatherIconSun;
      case 'cloudy':
        return FigcraftAssets.weatherIconCloud;
      case 'light_rain':
      case 'rain':
        return FigcraftAssets.weatherIconRain;
      case 'storm':
      case 'thunderstorm':
        return FigcraftAssets.weatherIconStorm;
      default:
        return FigcraftAssets.weatherIconPartly;
    }
  }

  /// Data contoh: tampil sebelum API menjawab dan dipakai MockThaliaApiService.
  static const List<ForecastDayModel> samples = [
    ForecastDayModel(
      dayShort: 'Sen',
      dateShort: '12/5',
      temperatureC: 26,
      conditionTitle: 'Hujan Ringan',
      conditionSubtitle: 'Curah 2.0 mm/jam • Status Aman',
      iconAsset: FigcraftAssets.weatherIconRain,
      humidityText: 'Lembap 77%',
      waterLevelText: 'Air 110 cm',
      soilText: 'Tanah 52%',
    ),
    ForecastDayModel(
      dayShort: 'Sel',
      dateShort: '13/5',
      temperatureC: 28,
      conditionTitle: 'Berawan Cerah',
      conditionSubtitle: 'Curah 0.4 mm/jam • Status Aman',
      iconAsset: FigcraftAssets.weatherIconPartly,
      humidityText: 'Lembap 70%',
      waterLevelText: 'Air 98 cm',
      soilText: 'Tanah 48%',
    ),
    ForecastDayModel(
      dayShort: 'Rab',
      dateShort: '14/5',
      temperatureC: 27,
      conditionTitle: 'Mendung Tebal',
      conditionSubtitle: 'Curah 1.2 mm/jam • Status Aman',
      iconAsset: FigcraftAssets.weatherIconCloud,
      humidityText: 'Lembap 74%',
      waterLevelText: 'Air 105 cm',
      soilText: 'Tanah 50%',
    ),
    ForecastDayModel(
      dayShort: 'Kam',
      dateShort: '15/5',
      temperatureC: 31,
      conditionTitle: 'Cerah Terik',
      conditionSubtitle: 'Indeks UV 9 (Tinggi) • Terasa 34°C',
      iconAsset: FigcraftAssets.weatherIconSun,
      humidityText: 'Lembap 48%',
      waterLevelText: 'Air 82 cm',
      soilText: 'Tanah 34%',
      triggersDryOrangePreview: true,
    ),
    ForecastDayModel(
      dayShort: 'Jum',
      dateShort: '16/5',
      temperatureC: 25,
      conditionTitle: 'Hujan Petir',
      conditionSubtitle: 'Curah 14.5 mm/jam • Waspada',
      iconAsset: FigcraftAssets.weatherIconStorm,
      humidityText: 'Lembap 86%',
      waterLevelText: 'Air 135 cm',
      soilText: 'Tanah 64%',
    ),
  ];

  /// Membangun data contoh prakiraan 5 hari berbasis tanggal sistem saat ini (B26).
  static List<ForecastDayModel> samplesForToday([DateTime? anchor]) {
    final now = anchor ?? DateTime.now();
    return List<ForecastDayModel>.generate(samples.length, (i) {
      final d = now.add(Duration(days: i));
      final base = samples[i];
      return ForecastDayModel(
        dayShort: _dayShortNames[d.weekday - 1],
        dateShort: '${d.day}/${d.month}',
        temperatureC: base.temperatureC,
        conditionTitle: base.conditionTitle,
        conditionSubtitle: base.conditionSubtitle,
        iconAsset: base.iconAsset,
        humidityText: base.humidityText,
        waterLevelText: base.waterLevelText,
        soilText: base.soilText,
        triggersDryOrangePreview: false,
      );
    });
  }
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
    this.fullDescription,
    this.isFailed = false,
    this.isSyncing = false,
    this.isRejected = false,
    this.verifiedBy,
    this.verificationNote,
    this.pendingDraft,
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
  final String? fullDescription;
  final bool isFailed;
  final bool isSyncing;
  final bool isRejected;
  final String? verifiedBy;
  final String? verificationNote;
  final FieldReportDraft? pendingDraft;

  static String _mapStatusLabel(String status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'processing':
        return 'Proses';
      case 'failed':
        return 'Gagal Kirim';
      default:
        return 'Diterima';
    }
  }

  /// Membaca satu laporan dari JSON backend. Kontrak lengkap di API_INTEGRATION.md.
  /// `status`: "received" (diterima), "processing" (proses), "completed"/"verified" (selesai).
  factory FieldReportItemModel.fromJson(Map<String, dynamic> json) {
    final habitat = (json['habitat'] as String? ?? '').toLowerCase();
    final status = (json['status'] as String? ?? 'received').toLowerCase();
    final completed = status == 'completed' || status == 'verified';
    final created = DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal();
    final lat = (json['latitude'] as num?)?.toDouble();
    final lng = (json['longitude'] as num?)?.toDouble();
    final description = json['description'] as String? ?? '';

    final String habitatLabel;
    final String icon;
    final Color accent;
    switch (habitat) {
      case 'hydrosphere':
        habitatLabel = 'Hidrosfer';
        icon = FigcraftAssets.weatherIconRain;
        accent = const Color(0xFF245E96);
      case 'lithosphere':
        habitatLabel = 'Litosfer';
        icon = FigcraftAssets.weatherIconPartly;
        accent = const Color(0xFF1F5E96);
      case 'atmosphere':
        habitatLabel = 'Atmosfer';
        icon = FigcraftAssets.weatherIconCloud;
        accent = const Color(0xFFDF9A42);
      default:
        habitatLabel = 'Lapangan';
        icon = FigcraftAssets.weatherIconRain;
        accent = const Color(0xFF245E96);
    }

    return FieldReportItemModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? 'Laporan Lapangan',
      timeAndHabitat: '${_formatReportTime(created)} • $habitatLabel',
      metricSummary: json['metric_summary'] as String? ??
          (description.isEmpty ? 'Dokumentasi visual terlampir' : _ellipsize(description)),
      statusLabel: _mapStatusLabel(status),
      isCompleted: completed,
      isRejected: status == 'rejected',
      verifiedBy: json['verified_by'] as String?,
      verificationNote: json['verification_note'] as String?,
      iconAsset: icon,
      accentBarColor: accent,
      categoryLabel: json['category'] as String?,
      gpsCoordinates: (lat != null && lng != null)
          ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
          : null,
      fullDescription: description.isNotEmpty ? description : null,
    );
  }

  /// Dipakai layanan contoh untuk membentuk laporan dari isian form.
  factory FieldReportItemModel.fromDraft(
    FieldReportDraft draft, {
    required String id,
  }) {
    return FieldReportItemModel(
      id: id,
      title: 'Laporan ${draft.category} • ${draft.locationName}',
      timeAndHabitat: '${_formatReportTime(draft.capturedAt)} • Lapangan',
      metricSummary: draft.description.trim().isEmpty
          ? 'Dokumentasi visual terlampir'
          : _ellipsize(draft.description.trim()),
      statusLabel: 'Diterima',
      isCompleted: false,
      iconAsset: FigcraftAssets.weatherIconRain,
      accentBarColor: const Color(0xFF245E96),
      capturedPhotoBytes: draft.photoBytes,
      categoryLabel: draft.category,
      gpsCoordinates:
          '${draft.latitude.toStringAsFixed(4)}, ${draft.longitude.toStringAsFixed(4)}',
      fullDescription: draft.description.trim(),
    );
  }

  FieldReportItemModel copyWith({
    String? id,
    String? timeAndHabitat,
    String? metricSummary,
    String? statusLabel,
    bool? isCompleted,
    Uint8List? capturedPhotoBytes,
    bool? isFailed,
    bool? isSyncing,
    FieldReportDraft? pendingDraft,
  }) {
    return FieldReportItemModel(
      id: id ?? this.id,
      title: title,
      timeAndHabitat: timeAndHabitat ?? this.timeAndHabitat,
      metricSummary: metricSummary ?? this.metricSummary,
      statusLabel: statusLabel ?? this.statusLabel,
      isCompleted: isCompleted ?? this.isCompleted,
      iconAsset: iconAsset,
      accentBarColor: accentBarColor,
      capturedPhotoBytes: capturedPhotoBytes ?? this.capturedPhotoBytes,
      categoryLabel: categoryLabel,
      gpsCoordinates: gpsCoordinates,
      fullDescription: fullDescription,
      isFailed: isFailed ?? this.isFailed,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingDraft: pendingDraft ?? this.pendingDraft,
    );
  }

  static String _ellipsize(String text) =>
      text.length > 38 ? '${text.substring(0, 38)}...' : text;

  /// "Hari Ini, 14:20", "Kemarin, 09:15" atau "10 Mei 2026".
  static String _formatReportTime(DateTime? time) {
    if (time == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final hhmm = '${_two(time.hour)}:${_two(time.minute)}';
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari Ini, $hhmm';
    if (diff == 1) return 'Kemarin, $hhmm';
    return '${time.day} ${_monthShortNames[time.month - 1]} ${time.year}';
  }

  /// Data contoh: tampil sebelum API menjawab dan dipakai MockThaliaApiService.
  static const List<FieldReportItemModel> samples = [
    FieldReportItemModel(
      id: 'RPT-1',
      title: 'Luapan Pintu Air Manggarai',
      timeAndHabitat: 'Hari Ini, 14:20 • Hidrosfer',
      metricSummary: 'Tinggi Air 110 cm • pH 6.8',
      statusLabel: 'Diterima',
      isCompleted: false,
      iconAsset: FigcraftAssets.weatherIconRain,
      accentBarColor: Color(0xFF245E96),
    ),
    FieldReportItemModel(
      id: 'RPT-2',
      title: 'Kelembapan Lereng Bukit Selatan',
      timeAndHabitat: 'Kemarin, 09:15 • Litosfer',
      metricSummary: 'Tanah 52% • Lereng Stabil',
      statusLabel: 'Selesai',
      isCompleted: true,
      iconAsset: FigcraftAssets.weatherIconPartly,
      accentBarColor: Color(0xFF1F5E96),
    ),
    FieldReportItemModel(
      id: 'RPT-3',
      title: 'Curah Hujan Lokal Cikarang',
      timeAndHabitat: '10 Mei 2026 • Atmosfer',
      metricSummary: 'Suhu 26°C • Hujan 2.0 mm/jam',
      statusLabel: 'Selesai',
      isCompleted: true,
      iconAsset: FigcraftAssets.weatherIconCloud,
      accentBarColor: Color(0xFFDF9A42),
    ),
  ];
}
