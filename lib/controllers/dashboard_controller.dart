import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import '../services/thalia_api_service.dart';

/// Controller OOP untuk seluruh fitur Dashboard, Maps, Kamera + Form Lens, Riwayat, Kalender, & Profil.
///
/// Data prakiraan dan laporan diambil lewat [ThaliaApiService] (disuntikkan lewat konstruktor),
/// sehingga controller ini tidak tahu apakah datanya dari server sungguhan atau data contoh.
final class DashboardController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  DashboardController({required ThaliaApiService api}) : _api = api;

  final ThaliaApiService _api;
  final ImagePicker _picker = ImagePicker();

  DashboardTab _activeTab = DashboardTab.home;
  DashboardTab get activeTab => _activeTab;

  // Default basic: Musim Hujan (Biru)
  SeasonMode _seasonMode = SeasonMode.rainyBlue;
  SeasonMode get seasonMode => _seasonMode;

  bool _showingProfile = false;
  bool get showingProfile => _showingProfile;

  int _selectedForecastIndex = 0;
  int get selectedForecastIndex => _selectedForecastIndex;

  int _monitoringRadiusKm = 5;
  int get monitoringRadiusKm => _monitoringRadiusKm;

  // --- State pemuatan data dari API ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadError;

  /// Pesan galat terakhir dari server, null bila pemuatan terakhir berhasil.
  String? get loadError => _loadError;

  bool _isSampleData = true;

  /// true selama belum ada jawaban sukses dari layanan data; yang tampil masih data contoh.
  bool get isSampleData => _isSampleData;

  double _latitude = -6.2845;
  double _longitude = 107.1705;

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

  List<ForecastDayModel> _forecastDays = ForecastDayModel.samples;
  List<ForecastDayModel> get forecastDays => _forecastDays;

  ForecastDayModel get currentForecast => _forecastDays[_selectedForecastIndex];

  List<FieldReportItemModel> _reports =
      List<FieldReportItemModel>.of(FieldReportItemModel.samples);

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

  int get totalReportsCount => _reports.length;
  int get completedReportsCount => _reports.where((r) => r.isCompleted).length;
  int get inProgressReportsCount =>
      _reports.where((r) => !r.isCompleted).length;

  // --- Pemuatan data dari API ---

  /// Mengambil prakiraan dan riwayat laporan untuk koordinat tertentu.
  /// Bila gagal, data yang sedang tampil dipertahankan dan [loadError] terisi.
  Future<void> loadDashboardData({
    required double latitude,
    required double longitude,
  }) async {
    if (_isLoading) return;
    _latitude = latitude;
    _longitude = longitude;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final forecast =
          await _api.fetchForecast(latitude: latitude, longitude: longitude);
      final reports = await _api.fetchReports();

      if (forecast.isNotEmpty) {
        _forecastDays = forecast;
        if (_selectedForecastIndex >= forecast.length) _selectedForecastIndex = 0;
        _seasonMode = currentForecast.triggersDryOrangePreview
            ? SeasonMode.dryOrange
            : SeasonMode.rainyBlue;
      }
      _reports = List<FieldReportItemModel>.of(reports);
      _isSampleData = false;
    } on ApiException catch (e) {
      _loadError = e.message;
    } catch (_) {
      _loadError = 'Gagal memuat data. Coba lagi.';
    } finally {
      _isLoading = false;
    }
    notifyListeners();
  }

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
    if (index < 0 || index >= _forecastDays.length) return;
    _selectedForecastIndex = index;
    _seasonMode = _forecastDays[index].triggersDryOrangePreview
        ? SeasonMode.dryOrange
        : SeasonMode.rainyBlue;
    notifyListeners();
  }

  void setSeasonMode(SeasonMode mode) {
    _seasonMode = mode;
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

  /// Menyimpan byte foto hasil jepretan live CameraController lalu menampilkan Google Lens sheet.
  void setCapturedPhotoFromCamera(Uint8List bytes) {
    _capturedPhotoBytes = bytes;
    _showLensReportSheet = true;
    notifyListeners();
  }

  /// Meminta izin akses Kamera / Galeri native Android lalu membuka kamera/galeri & Google Lens sheet.
  Future<void> captureOrPickFieldPhoto({required ImageSource source}) async {
    try {
      if (source == ImageSource.camera) {
        await Permission.camera.request();
      } else {
        await Permission.photos.request();
        await Permission.storage.request();
      }

      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        _capturedPhotoBytes = await picked.readAsBytes();
        await _deleteTempFile(picked.path);
        _showLensReportSheet = true;
        notifyListeners();
        return;
      }
      // Jika memilih dari galeri tapi user batal memilih, jangan buka form
      if (source == ImageSource.gallery) return;
    } catch (_) {}

    _showLensReportSheet = true;
    notifyListeners();
  }

  /// File foto sementara (hasil kamera/galeri) tidak dibutuhkan lagi setelah dibaca ke memori.
  Future<void> _deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
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

  /// Laporan langsung muncul di Riwayat dengan status "Mengirim", lalu diperbarui
  /// sesuai jawaban server (atau "Gagal Kirim" bila server tidak terjangkau).
  Future<void> submitFieldPhotoReport({required String locationName}) async {
    final draft = FieldReportDraft(
      category: _selectedIncidentCategory,
      description: _reportDescription.trim(),
      latitude: _latitude,
      longitude: _longitude,
      locationName: locationName,
      capturedAt: DateTime.now(),
      photoBytes: _capturedPhotoBytes,
    );

    final localId = 'LOCAL-${DateTime.now().microsecondsSinceEpoch}';
    _reports.insert(
      0,
      FieldReportItemModel.fromDraft(draft, id: localId)
          .copyWith(statusLabel: 'Mengirim'),
    );
    _showLensReportSheet = false;
    _activeTab = DashboardTab.history;
    notifyListeners();

    try {
      final saved = await _api.submitReport(draft);
      _replaceReport(
        localId,
        (local) => saved.copyWith(capturedPhotoBytes: local.capturedPhotoBytes),
      );
    } catch (_) {
      _replaceReport(localId, (local) => local.copyWith(statusLabel: 'Gagal Kirim'));
    }
    notifyListeners();
  }

  void _replaceReport(
    String id,
    FieldReportItemModel Function(FieldReportItemModel local) build,
  ) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reports[index] = build(_reports[index]);
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
