import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/dashboard_models.dart';
import '../widgets/figcraft_assets.dart';

/// Controller OOP untuk seluruh fitur Dashboard, Maps, Kamera + Form Lens, Riwayat, Kalender, & Profil.
final class DashboardController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  DashboardTab _activeTab = DashboardTab.home;
  DashboardTab get activeTab => _activeTab;

  // Default basic: Musim Hujan (Biru) sesuai instruksi user
  SeasonMode _seasonMode = SeasonMode.rainyBlue;
  SeasonMode get seasonMode => _seasonMode;

  bool _showingProfile = false;
  bool get showingProfile => _showingProfile;

  int _selectedForecastIndex = 0;
  int get selectedForecastIndex => _selectedForecastIndex;

  int _monitoringRadiusKm = 5;
  int get monitoringRadiusKm => _monitoringRadiusKm;

  // State Kamera & Pop-up Form Laporan Foto (Google Lens style)
  String _flashMode = 'Auto';
  String get flashMode => _flashMode;

  Uint8List? _capturedPhotoBytes;
  Uint8List? get capturedPhotoBytes => _capturedPhotoBytes;

  bool _showLensReportSheet = false;
  bool get showLensReportSheet => _showLensReportSheet;

  String _selectedIncidentCategory = 'Banjir';
  String get selectedIncidentCategory => _selectedIncidentCategory;

  String _reportDescription =
      'Air sungai mulai meluap ke jalan utama RT 04 setinggi sekitar 35 cm setelah hujan deras. Arus cukup deras di area dekat jembatan.';
  String get reportDescription => _reportDescription;

  static const List<String> incidentCategories = [
    'Banjir',
    'Gempa',
    'Kebakaran Hutan',
    'Tanah Longsor',
    'Lainnya',
  ];

  // State Riwayat Laporan
  ReportFilterTab _reportFilter = ReportFilterTab.all;
  ReportFilterTab get reportFilter => _reportFilter;

  // State Kalender Mei 2026
  int _selectedCalendarDay = 12;
  int get selectedCalendarDay => _selectedCalendarDay;

  static const Set<int> rainyCalendarDays = {8, 12, 15, 20, 23};

  final List<ForecastDayModel> forecastDays = const [
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

  ForecastDayModel get currentForecast => forecastDays[_selectedForecastIndex];

  final List<FieldReportItemModel> _reports = [
    const FieldReportItemModel(
      id: 'RPT-1',
      title: 'Luapan Pintu Air Manggarai',
      timeAndHabitat: 'Hari Ini, 14:20 • Hidrosfer',
      metricSummary: 'Tinggi Air 110 cm • pH 6.8',
      statusLabel: 'Diterima',
      isCompleted: false,
      iconAsset: FigcraftAssets.weatherIconRain,
      accentBarColor: Color(0xFF245E96),
    ),
    const FieldReportItemModel(
      id: 'RPT-2',
      title: 'Kelembapan Lereng Bukit Selatan',
      timeAndHabitat: 'Kemarin, 09:15 • Litosfer',
      metricSummary: 'Tanah 52% • Lereng Stabil',
      statusLabel: 'Selesai',
      isCompleted: true,
      iconAsset: FigcraftAssets.weatherIconPartly,
      accentBarColor: Color(0xFF1F5E96),
    ),
    const FieldReportItemModel(
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

  List<FieldReportItemModel> get filteredReports {
    switch (_reportFilter) {
      case ReportFilterTab.all:
        return List.unmodifiable(_reports);
      case ReportFilterTab.completed:
        return _reports.where((r) => r.isCompleted).toList();
      case ReportFilterTab.inProgress:
        return _reports.where((r) => !r.isCompleted).toList();
    }
  }

  int get totalReportsCount => _reports.length + 9;
  int get completedReportsCount =>
      _reports.where((r) => r.isCompleted).length + 8;
  int get inProgressReportsCount =>
      _reports.where((r) => !r.isCompleted).length + 1;

  // --- Navigasi Tab & Profil ---
  void selectTab(DashboardTab tab) {
    _activeTab = tab;
    _showingProfile = false;
    notifyListeners();
  }

  void openProfile() {
    _showingProfile = true;
    notifyListeners();
  }

  void closeProfile() {
    _showingProfile = false;
    notifyListeners();
  }

  // --- Pilih Hari Prakiraan & Tema Musim ---
  void selectForecastDay(int index) {
    if (index < 0 || index >= forecastDays.length) return;
    _selectedForecastIndex = index;
    notifyListeners();
  }

  void setSeasonMode(SeasonMode mode) {
    _seasonMode = mode;
    notifyListeners();
  }

  void toggleSeasonMode() {
    _seasonMode = _seasonMode == SeasonMode.rainyBlue
        ? SeasonMode.dryOrange
        : SeasonMode.rainyBlue;
    notifyListeners();
  }

  void cycleMonitoringRadius() {
    _monitoringRadiusKm = _monitoringRadiusKm == 5
        ? 10
        : (_monitoringRadiusKm == 10 ? 2 : 5);
    notifyListeners();
  }

  // --- Fungsi Kamera Lapangan & Form Pop-Up Google Lens ---
  void cycleFlashMode() {
    _flashMode = _flashMode == 'Auto'
        ? 'On'
        : (_flashMode == 'On' ? 'Off' : 'Auto');
    notifyListeners();
  }

  /// Meminta izin akses Kamera / Galeri lalu memunculkan pop-up form dari bawah ke atas.
  Future<void> captureOrPickFieldPhoto({required ImageSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        _capturedPhotoBytes = await picked.readAsBytes();
      }
    } catch (_) {
      // Fallback di emulator jika webcam virtual belum dikonfigurasi
    }
    _showLensReportSheet = true;
    notifyListeners();
  }

  void retakePhoto() {
    _showLensReportSheet = false;
    _capturedPhotoBytes = null;
    notifyListeners();
  }

  void selectIncidentCategory(String category) {
    _selectedIncidentCategory = category;
    notifyListeners();
  }

  void updateReportDescription(String value) {
    _reportDescription = value;
    notifyListeners();
  }

  void submitFieldPhotoReport({required String locationName}) {
    final trimmed = _reportDescription.trim();
    _reports.insert(
      0,
      FieldReportItemModel(
        id: 'RPT-${_reports.length + 1}',
        title: 'Laporan $_selectedIncidentCategory • $locationName',
        timeAndHabitat: 'Baru saja, 09:41 • Lapangan',
        metricSummary: trimmed.isEmpty
            ? 'Dokumentasi visual terlampir'
            : (trimmed.length > 38 ? '${trimmed.substring(0, 38)}...' : trimmed),
        statusLabel: 'Diterima',
        isCompleted: false,
        iconAsset: FigcraftAssets.weatherIconRain,
        accentBarColor: const Color(0xFF245E96),
        capturedPhotoBytes: _capturedPhotoBytes,
        categoryLabel: _selectedIncidentCategory,
      ),
    );
    _showLensReportSheet = false;
    _activeTab = DashboardTab.history;
    notifyListeners();
  }

  // --- Filter Riwayat & Kalender ---
  void setReportFilter(ReportFilterTab filter) {
    _reportFilter = filter;
    notifyListeners();
  }

  void selectCalendarDay(int day) {
    _selectedCalendarDay = day;
    notifyListeners();
  }
}
