import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../models/auth_models.dart';
import '../services/mock_thalia_api_service.dart';
import '../services/thalia_api_service.dart';

/// Hasil pencarian lokasi Google Maps / Geocoding.
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
  void updateLoginEmail(String value) {
    _loginModel = _loginModel.copyWith(emailOrOfficerId: value);
    notifyListeners();
  }

  void updateLoginPassword(String value) {
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
    _isSubmitting = true;
    _feedbackBanner = null;
    _feedbackIsError = false;
    notifyListeners();

    try {
      await _authService.login(
        username: _loginModel.emailOrOfficerId,
        password: _loginModel.password,
      );
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

  /// Keluar akun: hapus sesi di layanan, kosongkan form login, kembali ke halaman Masuk.
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    _loginModel = const LoginCredentialsModel();
    navigateTo(AuthScreenStep.login);
  }

  // --- Fungsi Halaman Daftar Akun Baru (Register) ---
  void updateRegisterName(String value) {
    _registerModel = _registerModel.copyWith(fullName: value);
    notifyListeners();
  }

  void updateRegisterEmail(String value) {
    _registerModel = _registerModel.copyWith(email: value);
    notifyListeners();
  }

  void updateRegisterPassword(String value) {
    _registerModel = _registerModel.copyWith(password: value);
    notifyListeners();
  }

  void updateRegisterConfirmPassword(String value) {
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

  /// Meminta izin Galeri/Media Android terlebih dahulu lalu membuka Galeri / File Manager.
  Future<void> pickProfilePhotoFromGallery() async {
    try {
      await Permission.photos.request();
      await Permission.storage.request();
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

  /// Meminta izin lokasi native Android (Popup OS) & mendeteksi koordinat akurat.
  Future<void> requestAndDetectGpsLocation() async {
    if (_gpsModel.isScanning) return;
    _gpsModel = _gpsModel.copyWith(
      isGpsEnabled: true,
      isScanning: true,
      accuracyLabel: 'Memindai...',
    );
    notifyListeners();

    try {
      await Permission.locationWhenInUse.request();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _gpsModel = _gpsModel.copyWith(
          isGpsEnabled: false,
          isScanning: false,
          hasLocationPermission: false,
          accuracyLabel: 'Akurat',
        );
        notifyListeners();
        return;
      }

      // Izin sudah ada tapi layanan lokasi HP mati: minta pengguna menyalakannya,
      // toggle tetap mati sampai pengguna menyalakannya lagi setelah kembali.
      if (!await Geolocator.isLocationServiceEnabled()) {
        _gpsModel = _gpsModel.copyWith(
          isGpsEnabled: false,
          isScanning: false,
          accuracyLabel: 'Akurat',
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

      final isEmulatorDefaultCalifornia =
          (lat - 37.422).abs() < 0.08 && (lng - (-122.084)).abs() < 0.08;
      if (isEmulatorDefaultCalifornia) {
        lat = -6.2845;
        lng = 107.1705;
      }

      final address = await _reverseGeocode(lat, lng);
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
    } catch (_) {
      _gpsModel = _gpsModel.copyWith(
        isScanning: false,
        isGpsEnabled: true,
        accuracyLabel: 'Akurat',
        resolvedAddress: 'Cikarang Utara, Bekasi',
      );
      _registerModel = _registerModel.copyWith(
        detectedLocation: _gpsModel.resolvedAddress,
      );
      notifyListeners();
    }
  }

  /// Pencarian lokasi interaktif (API Geocoding + database lokal Indonesia).
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.isEmpty) return defaultIndonesianPlaces;

    final localMatches = defaultIndonesianPlaces.where((place) {
      return place.name.toLowerCase().contains(q.toLowerCase()) ||
          place.subtitle.toLowerCase().contains(q.toLowerCase());
    }).toList();

    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final encoded = Uri.encodeQueryComponent(q);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=$encoded&countrycodes=id&limit=6&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'ThaliaClimateApp/1.0');
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
    } catch (_) {}

    if (localMatches.isNotEmpty) return localMatches;

    // Jika mengetik nama daerah kustom saat emulator offline, tetap izinkan dipilih langsung
    return [
      PlaceSearchResult(
        name: q,
        subtitle: 'Titik Koordinat Wilayah Pantauan',
        latitude: -6.2845,
        longitude: 107.1705,
      ),
      ...defaultIndonesianPlaces,
    ];
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
    _gpsModel = _gpsModel.copyWith(
      latitude: lat,
      longitude: lng,
      isGpsEnabled: true,
      accuracyLabel: 'Akurat',
    );
    notifyListeners();

    final address = await _reverseGeocode(lat, lng);
    _gpsModel = _gpsModel.copyWith(resolvedAddress: address);
    _registerModel = _registerModel.copyWith(detectedLocation: address);
    notifyListeners();
  }

  Future<String> _reverseGeocode(
    double lat,
    double lng, {
    String? fallback,
  }) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=id',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'ThaliaClimateApp/1.0');
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
    } catch (_) {}
    return fallback ?? _gpsModel.resolvedAddress;
  }

  void saveDetectedLocation() {
    _registerModel = _registerModel.copyWith(
      detectedLocation: _gpsModel.resolvedAddress,
    );
    navigateTo(AuthScreenStep.register);
  }

  // --- Fungsi Halaman Pengaturan Tema ---
  void selectThemeOption(ThemeOption option) {
    _themeOption = option;
    notifyListeners();
  }

  void toggleFollowSystemTheme(bool value) {
    _followSystemTheme = value;
    notifyListeners();
  }
}
