import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../models/auth_models.dart';
import '../services/mock_thalia_api_service.dart';
import '../services/thalia_api_service.dart';
import '../utils/validators.dart';

/// Hasil pencarian lokasi & Geocoding.
final class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
}

/// Controller OOP terpusat untuk seluruh fungsi interaktif pada flow Auth & Lokasi GPS.
final class AuthController extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();

  /// [hasSeenWelcome] true berarti halaman sambutan sudah pernah tampil di perangkat ini,
  /// sehingga aplikasi langsung dibuka di halaman Masuk.
  ///
  /// [authService] adalah pintu masuk ke server (atau data contoh); lihat ThaliaServices.
  AuthController({bool hasSeenWelcome = false, AuthService? authService})
      : _hasSeenWelcome = hasSeenWelcome,
        _authService = authService ?? MockAuthService(),
        _currentStep =
            hasSeenWelcome ? AuthScreenStep.login : AuthScreenStep.welcome;

  final AuthService _authService;

  static const String _welcomeSeenKey = 'has_seen_welcome';
  static const String _themeOptionKey = 'thalia_theme_option';
  static const String _followSystemThemeKey = 'thalia_follow_system_theme';
  static const String _savedSessionKey = 'thalia_saved_session';

  AuthSession? _activeSession;
  AuthSession? get activeSession => _activeSession;

  Uint8List? _profilePhotoBytes;
  Uint8List? get profilePhotoBytes => _profilePhotoBytes;

  int _reverseGeocodeSeq = 0;
  DateTime? _lastNominatimCall;
  String? _locationError;
  String? get locationError => _locationError;
  bool _locationPermissionDeniedForever = false;
  bool get locationPermissionDeniedForever => _locationPermissionDeniedForever;

  /// Memuat tema dan sesi tersimpan dari SharedPreferences (B21, B22).
  static Future<({bool hasSeenWelcome, ThemeOption theme, bool followSystem, AuthSession? session})>
      loadInitialPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_welcomeSeenKey) ?? false;
      final themeName = prefs.getString(_themeOptionKey);
      final theme = themeName == 'dark' ? ThemeOption.dark : ThemeOption.light;
      final follow = prefs.getBool(_followSystemThemeKey) ?? false;
      AuthSession? session;
      final rawSession = prefs.getString(_savedSessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        final decoded = jsonDecode(rawSession);
        if (decoded is Map<String, dynamic>) {
          session = AuthSession.fromJson(decoded);
        }
      }
      return (hasSeenWelcome: seen, theme: theme, followSystem: follow, session: session);
    } catch (_) {
      return (
        hasSeenWelcome: false,
        theme: ThemeOption.light,
        followSystem: false,
        session: null,
      );
    }
  }

  void applyInitialPrefs({
    required ThemeOption theme,
    required bool followSystem,
    AuthSession? session,
  }) {
    _themeOption = theme;
    _followSystemTheme = followSystem;
    if (session != null) {
      _activeSession = session;
      if ((session.locationName ?? '').isNotEmpty &&
          session.latitude != null &&
          session.longitude != null) {
        _gpsModel = _gpsModel.copyWith(
          resolvedAddress: session.locationName,
          latitude: session.latitude,
          longitude: session.longitude,
        );
      }
      _currentStep = AuthScreenStep.dashboard;
    }
    notifyListeners();
  }

  /// Dipanggil saat backend mengembalikan 401 Unauthorized (B35).
  void handleUnauthorized() {
    _activeSession = null;
    _clearSavedSession();
    _currentStep = AuthScreenStep.login;
    _feedbackBanner = 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    _feedbackIsError = true;
    notifyListeners();
  }

  /// Dibaca sekali di main() sebelum runApp.
  static Future<bool> loadHasSeenWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_welcomeSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  bool _hasSeenWelcome;

  AuthScreenStep _currentStep;
  AuthScreenStep get currentStep => _currentStep;

  /// Layar asal sebelum masuk ke Daftar Akun (Welcome atau Login), dipakai untuk tombol back.
  AuthScreenStep _registerOrigin = AuthScreenStep.login;

  LoginCredentialsModel _loginModel = const LoginCredentialsModel();
  LoginCredentialsModel get loginModel => _loginModel;

  RegisterFormModel _registerModel = const RegisterFormModel();
  RegisterFormModel get registerModel => _registerModel;

  GpsLocationModel _gpsModel = const GpsLocationModel();
  GpsLocationModel get gpsModel => _gpsModel;

  ThemeOption _themeOption = ThemeOption.light;
  ThemeOption get themeOption => _themeOption;

  bool _followSystemTheme = false;
  bool get followSystemTheme => _followSystemTheme;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _feedbackBanner;
  String? get feedbackBanner => _feedbackBanner;

  bool _feedbackIsError = false;
  bool get feedbackIsError => _feedbackIsError;


  bool get isDarkMode => _themeOption == ThemeOption.dark;

  static const List<PlaceSearchResult> defaultIndonesianPlaces = [
    PlaceSearchResult(
      name: 'Cikarang Utara, Bekasi',
      subtitle: 'Kabupaten Bekasi, Jawa Barat',
      latitude: -6.2845,
      longitude: 107.1705,
    ),
    PlaceSearchResult(
      name: 'Jababeka, Cikarang',
      subtitle: 'Kawasan Industri Jababeka, Bekasi',
      latitude: -6.2980,
      longitude: 107.1475,
    ),
    PlaceSearchResult(
      name: 'ASTRA Polytechnic (Astratech)',
      subtitle: 'Cikarang Selatan, Kabupaten Bekasi',
      latitude: -6.3408,
      longitude: 107.1402,
    ),
    PlaceSearchResult(
      name: 'Bantaran Ciliwung, Manggarai',
      subtitle: 'Tebet, Jakarta Selatan, DKI Jakarta',
      latitude: -6.2146,
      longitude: 106.8492,
    ),
    PlaceSearchResult(
      name: 'Cibinong, Bogor',
      subtitle: 'Kabupaten Bogor, Jawa Barat',
      latitude: -6.4816,
      longitude: 106.8542,
    ),
    PlaceSearchResult(
      name: 'Kelapa Gading, Jakarta Utara',
      subtitle: 'Jakarta Utara, DKI Jakarta',
      latitude: -6.1574,
      longitude: 106.9080,
    ),
    PlaceSearchResult(
      name: 'Dago, Bandung',
      subtitle: 'Coblong, Kota Bandung, Jawa Barat',
      latitude: -6.8850,
      longitude: 107.6135,
    ),
  ];

  // --- Navigasi Antar Layar ---
  void navigateTo(AuthScreenStep step) {
    if (step == AuthScreenStep.register &&
        (_currentStep == AuthScreenStep.welcome ||
            _currentStep == AuthScreenStep.login)) {
      _registerOrigin = _currentStep;
    }
    if (_currentStep == AuthScreenStep.welcome &&
        step != AuthScreenStep.welcome) {
      _markWelcomeSeen();
    }
    _currentStep = step;
    _feedbackBanner = null;
    _feedbackIsError = false;
    notifyListeners();
  }

  /// Tombol back di Daftar Akun: kembali ke layar asal (Sambutan untuk pengguna baru,
  /// Masuk untuk pengguna yang sudah pernah membuka aplikasi).
  void backFromRegister() => navigateTo(_registerOrigin);

  Future<void> _markWelcomeSeen() async {
    if (_hasSeenWelcome) return;
    _hasSeenWelcome = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_welcomeSeenKey, true);
    } catch (_) {}
  }

  // --- Fungsi Halaman Masuk Akun (Login) ---
  void _clearFeedback() {
    if (_feedbackBanner != null || _feedbackIsError) {
      _feedbackBanner = null;
      _feedbackIsError = false;
    }
  }

  void _setErrorFeedback(String message) {
    _feedbackBanner = message;
    _feedbackIsError = true;
    notifyListeners();
  }

  Future<void> _persistSession(AuthSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedSessionKey, jsonEncode(session.toJson()));
    } catch (_) {}
  }

  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedSessionKey);
    } catch (_) {}
  }

  void updateLoginEmail(String value) {
    _clearFeedback();
    _loginModel = _loginModel.copyWith(emailOrOfficerId: value);
    notifyListeners();
  }

  void updateLoginPassword(String value) {
    _clearFeedback();
    _loginModel = _loginModel.copyWith(password: value);
    notifyListeners();
  }

  void toggleLoginPasswordVisibility() {
    _loginModel = _loginModel.copyWith(
      obscurePassword: !_loginModel.obscurePassword,
    );
    notifyListeners();
  }

  void toggleRememberSession() {
    _loginModel = _loginModel.copyWith(
      rememberDeviceSession: !_loginModel.rememberDeviceSession,
    );
    notifyListeners();
  }

  Future<void> submitLogin() async {
    if (_isSubmitting) return;

    final idErr = ThaliaValidators.validateLoginIdentifier(_loginModel.emailOrOfficerId);
    if (idErr != null) {
      _setErrorFeedback(idErr);
      return;
    }

    final passErr = ThaliaValidators.validateLoginPassword(_loginModel.password);
    if (passErr != null) {
      _setErrorFeedback(passErr);
      return;
    }

    _isSubmitting = true;
    _clearFeedback();
    notifyListeners();

    try {
      final session = await _authService.login(
        username: _loginModel.emailOrOfficerId,
        password: _loginModel.password,
      );
      _activeSession = session;
      if ((session.locationName ?? '').isNotEmpty &&
          session.latitude != null &&
          session.longitude != null) {
        _gpsModel = _gpsModel.copyWith(
          resolvedAddress: session.locationName,
          latitude: session.latitude,
          longitude: session.longitude,
        );
      }
      if (_loginModel.rememberDeviceSession) {
        await _persistSession(session);
      } else {
        await _clearSavedSession();
      }
      _currentStep = AuthScreenStep.dashboard;
    } on ApiException catch (e) {
      _feedbackBanner = e.message;
      _feedbackIsError = true;
    } catch (_) {
      _feedbackBanner = 'Terjadi kesalahan saat masuk. Coba lagi.';
      _feedbackIsError = true;
    } finally {
      _isSubmitting = false;
    }
    notifyListeners();
  }

  /// Keluar akun: hapus sesi di layanan & perangkat, reset form & GPS (B08, B22).
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _clearSavedSession();
    _activeSession = null;
    _profilePhotoBytes = null;
    _loginModel = const LoginCredentialsModel();
    _registerModel = const RegisterFormModel();
    _gpsModel = const GpsLocationModel();
    navigateTo(AuthScreenStep.login);
  }

  /// Mengirim permintaan reset kata sandi melalui [AuthService] (B22).
  Future<String> requestPasswordReset(String email) async {
    final clean = email.trim();
    if (clean.isEmpty || !clean.contains('@')) {
      throw const ApiException('Masukkan alamat email yang valid.');
    }
    return _authService.forgotPassword(email: clean);
  }

  /// Memperbarui profil akun aktif melalui [AuthService] (B20).
  Future<void> updateActiveProfile({
    String? fullName,
    String? phone,
    String? handle,
    String? locationName,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    final updated = await _authService.updateProfile(
      fullName: fullName,
      phone: phone,
      handle: handle,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    _activeSession = updated;
    if (_loginModel.rememberDeviceSession) {
      await _persistSession(updated);
    }
    notifyListeners();
  }

  // --- Fungsi Halaman Daftar Akun Baru (Register) ---
  Future<bool> submitRegister() async {
    if (_isSubmitting) return false;

    final nameErr = ThaliaValidators.validateFullName(_registerModel.fullName);
    if (nameErr != null) {
      _setErrorFeedback(nameErr);
      return false;
    }

    final emailErr = ThaliaValidators.validateRegisterEmail(_registerModel.email);
    if (emailErr != null) {
      _setErrorFeedback(emailErr);
      return false;
    }

    final passErr = ThaliaValidators.validatePassword(_registerModel.password);
    if (passErr != null) {
      _setErrorFeedback(passErr);
      return false;
    }

    final confirmErr = ThaliaValidators.validateConfirmPassword(
      _registerModel.password,
      _registerModel.confirmPassword,
    );
    if (confirmErr != null) {
      _setErrorFeedback(confirmErr);
      return false;
    }

    if (!_registerModel.agreedToTerms) {
      _setErrorFeedback('Harap centang persetujuan Syarat & Ketentuan.');
      return false;
    }

    _isSubmitting = true;
    _clearFeedback();
    notifyListeners();

    try {
      await _authService.register(
        fullName: _registerModel.fullName.trim(),
        email: _registerModel.email.trim(),
        password: _registerModel.password,
        locationName: _registerModel.detectedLocation,
        latitude: _gpsModel.latitude,
        longitude: _gpsModel.longitude,
      );
      _profilePhotoBytes = _registerModel.profileImageBytes;
      _registerModel = const RegisterFormModel();
      _currentStep = AuthScreenStep.login;
      _feedbackBanner = 'Pendaftaran akun berhasil! Silakan masuk.';
      _feedbackIsError = false;
      return true;
    } on ApiException catch (e) {
      _feedbackBanner = e.message;
      _feedbackIsError = true;
      return false;
    } catch (_) {
      _feedbackBanner = 'Gagal mendaftar. Periksa koneksi Anda.';
      _feedbackIsError = true;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
  void updateRegisterName(String value) {
    _clearFeedback();
    _registerModel = _registerModel.copyWith(fullName: value);
    notifyListeners();
  }

  void updateRegisterEmail(String value) {
    _clearFeedback();
    _registerModel = _registerModel.copyWith(email: value);
    notifyListeners();
  }

  void updateRegisterPassword(String value) {
    _clearFeedback();
    _registerModel = _registerModel.copyWith(password: value);
    notifyListeners();
  }

  void updateRegisterConfirmPassword(String value) {
    _clearFeedback();
    _registerModel = _registerModel.copyWith(confirmPassword: value);
    notifyListeners();
  }

  void toggleRegisterPasswordVisibility() {
    _registerModel = _registerModel.copyWith(
      obscurePassword: !_registerModel.obscurePassword,
    );
    notifyListeners();
  }

  void toggleRegisterConfirmVisibility() {
    _registerModel = _registerModel.copyWith(
      obscureConfirmPassword: !_registerModel.obscureConfirmPassword,
    );
    notifyListeners();
  }

  /// Membuka Photo Picker / Galeri tanpa izin storage usang (B38) dan cek batas 2 MB (B24).
  Future<void> pickProfilePhotoFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      try {
        final temp = File(picked.path);
        if (await temp.exists()) await temp.delete();
      } catch (_) {}
      if (bytes.length > ThaliaValidators.maxProfilePhotoBytes) {
        _setErrorFeedback('Ukuran foto profil melebihi batas maksimal 2 MB.');
        return;
      }
      _profilePhotoBytes = bytes;
      _registerModel = _registerModel.copyWith(
        profileImageBytes: bytes,
        profileImageName: picked.name,
      );
      notifyListeners();
    } catch (_) {}
  }

  void toggleTermsAgreed() {
    _registerModel = _registerModel.copyWith(
      agreedToTerms: !_registerModel.agreedToTerms,
    );
    notifyListeners();
  }

  // --- Fungsi Halaman Izinkan Akses Lokasi & Pencarian Google Maps ---
  Future<void> toggleGpsAutomatic() async {
    if (_gpsModel.isGpsEnabled && !_gpsModel.isScanning) {
      _gpsModel = _gpsModel.copyWith(isGpsEnabled: false);
      notifyListeners();
      return;
    }
    await requestAndDetectGpsLocation();
  }

  /// Membuka pengaturan izin aplikasi saat izin lokasi ditolak permanen (B15).
  Future<void> openLocationAppSettings() => Geolocator.openAppSettings();

  /// Meminta izin lokasi native Android (satu jalur via Geolocator) & mendeteksi koordinat akurat (B14, B15).
  Future<void> requestAndDetectGpsLocation() async {
    if (_gpsModel.isScanning) return;
    _locationError = null;
    _locationPermissionDeniedForever = false;
    _gpsModel = _gpsModel.copyWith(
      isGpsEnabled: true,
      isScanning: true,
      accuracyLabel: 'Memindai...',
    );
    notifyListeners();

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationPermissionDeniedForever =
            permission == LocationPermission.deniedForever;
        _locationError = _locationPermissionDeniedForever
            ? 'Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkannya.'
            : 'Izin lokasi ditolak. Aktifkan izin lokasi untuk mendeteksi GPS.';
        _gpsModel = _gpsModel.copyWith(
          isGpsEnabled: false,
          isScanning: false,
          hasLocationPermission: false,
          accuracyLabel: 'Izin ditolak',
        );
        notifyListeners();
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError = 'Layanan GPS perangkat mati. Nyalakan GPS lalu coba lagi.';
        _gpsModel = _gpsModel.copyWith(
          isGpsEnabled: false,
          isScanning: false,
          hasLocationPermission: true,
          accuracyLabel: 'GPS mati',
        );
        notifyListeners();
        await Geolocator.openLocationSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      var lat = position.latitude;
      var lng = position.longitude;

      // Hack koordinat default Mountain View emulator hanya aktif saat kDebugMode (B14).
      if (kDebugMode) {
        final isEmulatorDefaultCalifornia =
            (lat - 37.422).abs() < 0.08 && (lng - (-122.084)).abs() < 0.08;
        if (isEmulatorDefaultCalifornia) {
          lat = -6.2845;
          lng = 107.1705;
        }
      }

      final address = await _reverseGeocode(lat, lng);
      _locationError = null;
      _gpsModel = _gpsModel.copyWith(
        latitude: lat,
        longitude: lng,
        resolvedAddress: address,
        accuracyLabel: 'Akurat',
        isScanning: false,
        isGpsEnabled: true,
        hasLocationPermission: true,
      );
      _registerModel = _registerModel.copyWith(detectedLocation: address);
      notifyListeners();
    } on TimeoutException {
      _locationError =
          'Gagal mengunci sinyal GPS dalam 6 detik. Coba di area terbuka atau pilih daerah secara manual.';
      _gpsModel = _gpsModel.copyWith(
        isScanning: false,
        isGpsEnabled: false,
        accuracyLabel: 'Timeout GPS',
      );
      notifyListeners();
    } catch (_) {
      _locationError =
          'Tidak dapat membaca GPS perangkat. Pilih lokasi secara manual.';
      _gpsModel = _gpsModel.copyWith(
        isScanning: false,
        isGpsEnabled: false,
        accuracyLabel: 'Gagal deteksi',
      );
      notifyListeners();
    }
  }

  /// Pencarian lokasi interaktif (Nominatim + database lokal Indonesia).
  /// Mengembalikan list kosong bila tidak ditemukan — tanpa fallback Cikarang palsu (B16, B32).
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.isEmpty) return defaultIndonesianPlaces;

    final localMatches = defaultIndonesianPlaces.where((place) {
      return place.name.toLowerCase().contains(q.toLowerCase()) ||
          place.subtitle.toLowerCase().contains(q.toLowerCase());
    }).toList();

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final encoded = Uri.encodeQueryComponent(q);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=$encoded&countrycodes=id&limit=6&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'THALIA-App/1.0 (contact@thalia.id)');
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        final remoteResults = <PlaceSearchResult>[];
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final displayName = (map['display_name'] as String?) ?? q;
          final parts = displayName.split(',').map((s) => s.trim()).toList();
          final title = parts.length >= 2
              ? '${parts[0]}, ${parts[1]}'
              : parts.first;
          final subtitle = parts.skip(1).take(3).join(', ');
          final lat = double.tryParse('${map['lat']}');
          final lon = double.tryParse('${map['lon']}');
          if (lat != null && lon != null) {
            remoteResults.add(
              PlaceSearchResult(
                name: title,
                subtitle: subtitle.isEmpty ? 'Indonesia' : subtitle,
                latitude: lat,
                longitude: lon,
              ),
            );
          }
        }
        if (remoteResults.isNotEmpty) {
          return [...remoteResults, ...localMatches];
        }
      }
    } catch (_) {
    } finally {
      client?.close(force: true);
    }

    return localMatches;
  }

  /// Nama wilayah untuk sebuah titik peta tanpa mengubah lokasi aktif aplikasi.
  /// Dipakai layar Cari Lokasi saat pengguna menggeser peta.
  Future<String> describePoint(double lat, double lng) =>
      _reverseGeocode(lat, lng, fallback: 'Titik pilihan di peta');

  /// Keterangan kapan sandi terakhir diganti. Nilai awal hanyalah contoh dari desain
  /// sampai backend mengirim tanggal sungguhan.
  String _passwordChangedLabel = 'Sandi terakhir diperbarui 14 hari lalu';
  String get passwordChangedLabel => _passwordChangedLabel;

  /// Mengganti kata sandi lewat [AuthService]. Melempar [ApiException] bila ditolak server.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    _passwordChangedLabel = 'Sandi terakhir diperbarui baru saja';
    notifyListeners();
  }

  void selectPlaceResult(PlaceSearchResult place) {
    _gpsModel = _gpsModel.copyWith(
      latitude: place.latitude,
      longitude: place.longitude,
      resolvedAddress: place.name,
      isGpsEnabled: true,
      accuracyLabel: 'Akurat',
    );
    _registerModel = _registerModel.copyWith(detectedLocation: place.name);
    notifyListeners();
  }

  Future<void> updatePickedMapPoint(double lat, double lng) async {
    final seq = ++_reverseGeocodeSeq;
    _gpsModel = _gpsModel.copyWith(
      latitude: lat,
      longitude: lng,
      isGpsEnabled: true,
      accuracyLabel: 'Akurat',
    );
    notifyListeners();

    final address = await _reverseGeocode(
      lat,
      lng,
      fallback: 'Titik pilihan di peta',
    );
    if (seq != _reverseGeocodeSeq) return; // Abaikan balasan usang (B17).
    _gpsModel = _gpsModel.copyWith(resolvedAddress: address);
    _registerModel = _registerModel.copyWith(detectedLocation: address);
    notifyListeners();
  }

  Future<String> _reverseGeocode(
    double lat,
    double lng, {
    String? fallback,
  }) async {
    // Pembatas laju Nominatim maksimal 1 permintaan per detik (B17).
    final last = _lastNominatimCall;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
      }
    }
    _lastNominatimCall = DateTime.now();

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'THALIA-App/1.0 (contact@thalia.id)');
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final subdistrict = (addr['suburb'] ??
              addr['village'] ??
              addr['municipality'] ??
              addr['town']) as String?;
          final city = (addr['city'] ??
              addr['county'] ??
              addr['state_district'] ??
              addr['state']) as String?;
          if (subdistrict != null && city != null) {
            return '$subdistrict, $city';
          }
          if (subdistrict != null) return subdistrict;
          if (city != null) return city;
        }
      }
    } catch (_) {
    } finally {
      client?.close(force: true);
    }
    return fallback ?? 'Titik pilihan di peta';
  }

  bool saveDetectedLocation() {
    final addr = _gpsModel.resolvedAddress.trim();
    if (addr.isEmpty || (!_gpsModel.isGpsEnabled && _registerModel.detectedLocation.isEmpty)) {
      _locationError = 'Aktifkan GPS atau pilih daerah secara manual terlebih dahulu.';
      notifyListeners();
      return false;
    }
    _locationError = null;
    _registerModel = _registerModel.copyWith(detectedLocation: addr);
    navigateTo(AuthScreenStep.register);
    return true;
  }

  // --- Fungsi Halaman Pengaturan Tema (disimpan permanen, B21) ---
  void selectThemeOption(ThemeOption option) {
    _themeOption = option;
    _saveThemePrefs();
    notifyListeners();
  }

  void toggleFollowSystemTheme(bool value) {
    _followSystemTheme = value;
    _saveThemePrefs();
    notifyListeners();
  }

  Future<void> _saveThemePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeOptionKey,
        _themeOption == ThemeOption.dark ? 'dark' : 'light',
      );
      await prefs.setBool(_followSystemThemeKey, _followSystemTheme);
    } catch (_) {}
  }
}
