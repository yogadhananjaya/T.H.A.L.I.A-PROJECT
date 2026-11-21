import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import '../services/offline_cache_service.dart';
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

  int _loadGeneration = 0; // Token permintaan agar lokasi terbaru tidak terbuang (B11).

  String? _loadError;

  /// Pesan galat terakhir dari server, null bila pemuatan terakhir berhasil.
  String? get loadError => _loadError;

  bool _isSampleData = true;

  /// true selama belum ada jawaban sukses dari layanan data; yang tampil masih data contoh.
  bool get isSampleData => _isSampleData;

  bool _isOfflineCached = false;

  /// true bila data prakiraan saat ini berasal dari cache lokal saat server tidak terjangkau.
  bool get isOfflineCached => _isOfflineCached;

  double _latitude = -6.2845;
  double get latitude => _latitude;
  double _longitude = 107.1705;
  double get longitude => _longitude;

  Future<void> refresh() =>
      loadDashboardData(latitude: _latitude, longitude: _longitude);

  // State Kamera & Pop-up Form Laporan Foto (Google Lens style)
  String _flashMode = 'Auto';
  String get flashMode => _flashMode;

  Uint8List? _capturedPhotoBytes;
  Uint8List? get capturedPhotoBytes => _capturedPhotoBytes;

  DateTime? _photoCapturedAt;
  DateTime? get photoCapturedAt => _photoCapturedAt;

  String get formattedCaptureTime {
    final t = (_photoCapturedAt ?? DateTime.now()).toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }

  bool _showLensReportSheet = false;
  bool get showLensReportSheet => _showLensReportSheet;

  String _selectedIncidentCategory = 'Banjir';
  String get selectedIncidentCategory => _selectedIncidentCategory;

  /// Deskripsi awal wajib kosong; pengguna harus mengetik sendiri (B09).
  String _reportDescription = '';
  String get reportDescription => _reportDescription;

  String? _reportFormError;
  String? get reportFormError => _reportFormError;

  String? _cameraError;
  String? get cameraError => _cameraError;

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

  // State Kalender dinamis berbasis DateTime.now() (B26)
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get calendarMonth => _calendarMonth;

  int _selectedCalendarDay = DateTime.now().day;
  int get selectedCalendarDay => _selectedCalendarDay;

  Set<int> get rainyCalendarDays {
    final now = DateTime.now();
    if (_calendarMonth.year == now.year && _calendarMonth.month == now.month) {
      return {
        for (int i = 0; i < _forecastDays.length; i++)
          if (_forecastDays[i].conditionTitle.toLowerCase().contains('hujan'))
            now.add(Duration(days: i)).day,
      };
    }
    return const {};
  }

  List<ForecastDayModel> _forecastDays = ForecastDayModel.samplesForToday();
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
        return _reports.where((r) => !r.isCompleted && !r.isFailed).toList();
    }
  }

  int get totalReportsCount => _reports.length;
  int get completedReportsCount => _reports.where((r) => r.isCompleted).length;
  int get inProgressReportsCount =>
      _reports.where((r) => !r.isCompleted && !r.isFailed).length;

  /// Reset seluruh state dashboard saat pengguna logout (B08).
  void reset() {
    _loadGeneration++;
    _activeTab = DashboardTab.home;
    _seasonMode = SeasonMode.rainyBlue;
    _showingProfile = false;
    _selectedForecastIndex = 0;
    _monitoringRadiusKm = 5;
    _isLoading = false;
    _loadError = null;
    _isSampleData = true;
    _capturedPhotoBytes = null;
    _photoCapturedAt = null;
    _showLensReportSheet = false;
    _selectedIncidentCategory = 'Banjir';
    _reportDescription = '';
    _reportFormError = null;
    _cameraError = null;
    _reportFilter = ReportFilterTab.all;
    _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedCalendarDay = DateTime.now().day;
    _forecastDays = ForecastDayModel.samplesForToday();
    _reports = List<FieldReportItemModel>.of(FieldReportItemModel.samples);
    _isOfflineCached = false;
    OfflineCacheService.clear();
    notifyListeners();
  }

  // --- Pemuatan data dari API ---

  /// Mengambil prakiraan dan riwayat laporan untuk koordinat & radius tertentu.
  /// Menggunakan token generasi agar pemanggilan berurutan tidak membuang permintaan baru (B11, B13, B29).
  Future<void> loadDashboardData({
    required double latitude,
    required double longitude,
  }) async {
    final gen = ++_loadGeneration;
    _latitude = latitude;
    _longitude = longitude;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final forecast = await _api.fetchForecast(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _monitoringRadiusKm,
      );
      final serverReports = await _api.fetchReports();

      if (gen != _loadGeneration) return;

      if (forecast.isNotEmpty) {
        _forecastDays = forecast;
        if (_selectedForecastIndex >= forecast.length) _selectedForecastIndex = 0;
        _isSampleData = false;
        _isOfflineCached = false;
        await OfflineCacheService.saveForecast(forecast);
      }

      // Gabungkan laporan lokal yang masih Mengirim / Gagal Kirim agar tidak hilang (B13).
      final pendingLocals =
          _reports.where((r) => r.id.startsWith('LOCAL-') && (r.isSyncing || r.isFailed)).toList();
      _reports = [...pendingLocals, ...serverReports];
    } on ApiException catch (e) {
      if (gen != _loadGeneration) return;
      await _applyOfflineFallback();
      _loadError = _isOfflineCached
          ? '${e.message} (Menampilkan data tersimpan terakhir)'
          : e.message;
    } catch (_) {
      if (gen != _loadGeneration) return;
      await _applyOfflineFallback();
      _loadError = _isOfflineCached
          ? 'Mode offline · Menampilkan data prakiraan tersimpan terakhir.'
          : 'Gagal memuat data. Coba lagi.';
    } finally {
      if (gen == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _applyOfflineFallback() async {
    final cached = await OfflineCacheService.loadForecast();
    if (cached.days.isNotEmpty) {
      _forecastDays = cached.days;
      if (_selectedForecastIndex >= _forecastDays.length) {
        _selectedForecastIndex = 0;
      }
      _isSampleData = false;
      _isOfflineCached = true;
    }
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
    loadDashboardData(latitude: _latitude, longitude: _longitude);
  }

  // --- Fungsi Kamera Lapangan & Form Pop-Up Google Lens ---
  void cycleFlashMode() {
    _flashMode = _flashMode == 'Auto'
        ? 'On'
        : (_flashMode == 'On' ? 'Off' : 'Auto');
    notifyListeners();
  }

  /// Menyimpan byte foto hasil jepretan live CameraController lalu menampilkan Google Lens sheet (B27).
  void setCapturedPhotoFromCamera(Uint8List bytes) {
    _capturedPhotoBytes = bytes;
    _photoCapturedAt = DateTime.now();
    _reportFormError = null;
    _showLensReportSheet = true;
    notifyListeners();
  }

  /// Meminta izin Kamera (hanya bila source == camera, B38) lalu membuka kamera/galeri.
  /// Batal memilih atau izin ditolak tidak akan membuka form laporan (B10).
  Future<void> captureOrPickFieldPhoto({required ImageSource source}) async {
    _cameraError = null;
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _cameraError = status.isPermanentlyDenied
              ? 'Izin kamera ditolak permanen. Aktifkan lewat Pengaturan perangkat.'
              : 'Izin kamera diperlukan untuk mengambil foto lapangan.';
          notifyListeners();
          return;
        }
      }

      // Kompres maxWidth 1280 sebelum disimpan ke memori (B31).
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked == null) {
        return; // Batal memilih: jangan buka form (B10).
      }

      _capturedPhotoBytes = await picked.readAsBytes();
      _photoCapturedAt = DateTime.now();
      _reportFormError = null;
      await _deleteTempFile(picked.path);
      _showLensReportSheet = true;
      notifyListeners();
    } catch (_) {
      _cameraError = 'Tidak dapat membuka kamera atau galeri.';
      notifyListeners();
    }
  }

  /// File foto sementara tidak dibutuhkan lagi setelah dibaca ke memori.
  Future<void> _deleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void retakePhoto() {
    _showLensReportSheet = false;
    _capturedPhotoBytes = null;
    _photoCapturedAt = null;
    _reportFormError = null;
    notifyListeners();
  }

  void selectIncidentCategory(String category) {
    _selectedIncidentCategory = category;
    notifyListeners();
  }

  void updateReportDescription(String value) {
    _reportDescription = value;
    if (_reportFormError != null) _reportFormError = null;
    notifyListeners();
  }

  /// Validasi & kirim laporan warga, lalu reset form setelah pengiriman dimulai (B09, B13).
  Future<bool> submitFieldPhotoReport({required String locationName}) async {
    if (_capturedPhotoBytes == null || _capturedPhotoBytes!.isEmpty) {
      _reportFormError = 'Foto kondisi lapangan wajib dilampirkan.';
      notifyListeners();
      return false;
    }
    final desc = _reportDescription.trim();
    if (desc.length < 10) {
      _reportFormError = 'Deskripsi laporan minimal 10 karakter.';
      notifyListeners();
      return false;
    }

    final draft = FieldReportDraft(
      category: _selectedIncidentCategory,
      description: desc,
      latitude: _latitude,
      longitude: _longitude,
      locationName: locationName.isEmpty ? 'Lokasi Terpantau' : locationName,
      capturedAt: _photoCapturedAt ?? DateTime.now(),
      photoBytes: _capturedPhotoBytes,
    );

    final localId = 'LOCAL-${DateTime.now().microsecondsSinceEpoch}';
    _reports.insert(
      0,
      FieldReportItemModel.fromDraft(draft, id: localId).copyWith(
        statusLabel: 'Mengirim',
        isSyncing: true,
        pendingDraft: draft,
      ),
    );

    // Bersihkan form setelah kirim agar laporan berikutnya mulai bersih (B09).
    _showLensReportSheet = false;
    _capturedPhotoBytes = null;
    _photoCapturedAt = null;
    _reportDescription = '';
    _reportFormError = null;
    _activeTab = DashboardTab.history;
    notifyListeners();

    await _dispatchReportDraft(localId, draft);
    return true;
  }

  /// Mengirim ulang laporan lokal yang berstatus Gagal Kirim (B13).
  Future<void> retryFailedReport(String localId) async {
    final idx = _reports.indexWhere((r) => r.id == localId);
    if (idx == -1) return;
    final item = _reports[idx];
    final draft = item.pendingDraft;
    if (draft == null) return;

    _replaceReport(
      localId,
      (local) => local.copyWith(
        statusLabel: 'Mengirim',
        isFailed: false,
        isSyncing: true,
      ),
    );
    notifyListeners();
    await _dispatchReportDraft(localId, draft);
  }

  Future<void> _dispatchReportDraft(String localId, FieldReportDraft draft) async {
    try {
      final saved = await _api.submitReport(draft);
      _replaceReport(
        localId,
        (local) => saved.copyWith(
          capturedPhotoBytes: local.capturedPhotoBytes,
          isFailed: false,
          isSyncing: false,
        ),
      );
    } catch (_) {
      _replaceReport(
        localId,
        (local) => local.copyWith(
          statusLabel: 'Gagal Kirim',
          isFailed: true,
          isSyncing: false,
        ),
      );
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
