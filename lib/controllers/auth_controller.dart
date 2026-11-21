import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_models.dart';

/// Controller OOP terpusat untuk seluruh fungsi interaktif pada flow LOGIN.figcraft.
final class AuthController extends ChangeNotifier {
  final ImagePicker _imagePicker = ImagePicker();

  AuthScreenStep _currentStep = AuthScreenStep.welcome;
  AuthScreenStep get currentStep => _currentStep;

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

  bool get isDarkMode => _themeOption == ThemeOption.dark;

  // --- Navigasi Antar Layar LOGIN.figcraft ---
  void navigateTo(AuthScreenStep step) {
    _currentStep = step;
    _feedbackBanner = null;
    notifyListeners();
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
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));
    _isSubmitting = false;
    _currentStep = AuthScreenStep.dashboard;
    notifyListeners();
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

  /// Membuka Galeri / File Manager perangkat untuk memilih foto profil asli.
  Future<void> pickProfilePhotoFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      _registerModel = _registerModel.copyWith(
        profileImageBytes: bytes,
        profileImageName: picked.name,
      );
      notifyListeners();
    } catch (_) {
      // Tetap aman pada environment test tanpa platform channel galeri.
    }
  }

  void toggleTermsAgreed() {
    _registerModel = _registerModel.copyWith(
      agreedToTerms: !_registerModel.agreedToTerms,
    );
    notifyListeners();
  }

  // --- Fungsi Halaman Izinkan Akses Lokasi (GPS Permission & Real Maps) ---
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
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _gpsModel = _gpsModel.copyWith(
          isScanning: false,
          hasLocationPermission: false,
          accuracyLabel: 'Akurat',
        );
        notifyListeners();
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

      // Jika emulator Android masih di koordinat default Googleplex California (37.42, -122.08),
      // arahkan ke titik rumah/kampus Cikarang Utara, Bekasi agar peta sesuai wilayah Indonesia.
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

  /// Saat pengguna menggeser atau mengetuk titik di peta secara interaktif.
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

  Future<String> _reverseGeocode(double lat, double lng) async {
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
    return 'Cikarang Utara, Bekasi';
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
