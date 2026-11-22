/// Satu-satunya tempat untuk mengatur alamat dan jalur API T.H.A.L.I.A.
///
/// Nilai bisa diganti tanpa mengubah kode lewat `--dart-define`, misalnya:
///
///   flutter run --dart-define=THALIA_USE_MOCK=false \
///               --dart-define=THALIA_API_URL=http://192.168.1.10:8000
///
/// Panduan lengkap untuk tim backend ada di API_INTEGRATION.md (root project).
final class ApiConfig {
  const ApiConfig._();

  /// true  = pakai data contoh bawaan aplikasi (tanpa server).
  /// false = pakai API sungguhan di [baseUrl] (default).
  static const bool useMockData =
      bool.fromEnvironment('THALIA_USE_MOCK', defaultValue: false);

  static const String _envApiUrl =
      String.fromEnvironment('THALIA_API_URL', defaultValue: '');

  /// Alamat server FastAPI, tanpa garis miring di akhir.
  /// Default memakai URL Ngrok permanen agar Android, Emulator, Web, & ESP32
  /// bisa konek dari jaringan berbeda tanpa gonta-ganti IP.
  static String get baseUrl => _envApiUrl.isNotEmpty
      ? _envApiUrl
      : 'https://zoom-prior-conducive.ngrok-free.dev';

  /// Batas waktu tunggu satu permintaan standar ke server.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Batas waktu tunggu unggah foto laporan di jaringan lambat (B31).
  static const Duration uploadTimeout = Duration(seconds: 25);

  // --- Jalur endpoint (selaras dengan backend FastAPI, B06) ---
  static const String loginPath = '/api/v1/auth/login';
  static const String registerPath = '/api/v1/auth/register';
  static const String changePasswordPath = '/api/v1/auth/change-password';
  static const String forgotPasswordPath = '/api/v1/auth/forgot-password';
  static const String profilePath = '/api/v1/auth/me';
  static const String forecastPath = '/api/v1/forecast';
  static const String reportsPath = '/api/v1/reports';
  static const String alertsPath = '/api/v1/alerts';
}
