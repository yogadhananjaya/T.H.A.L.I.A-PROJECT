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
  /// false = pakai API sungguhan di [baseUrl].
  static const bool useMockData =
      bool.fromEnvironment('THALIA_USE_MOCK', defaultValue: true);

  /// Alamat server FastAPI, tanpa garis miring di akhir.
  /// Emulator Android: `10.0.2.2` berarti localhost laptop.
  /// HP fisik: pakai IP laptop di jaringan yang sama, mis. `http://192.168.1.10:8000`.
  static const String baseUrl =
      String.fromEnvironment('THALIA_API_URL', defaultValue: 'http://10.0.2.2:8000');

  /// Batas waktu tunggu satu permintaan ke server.
  static const Duration requestTimeout = Duration(seconds: 8);

  // --- Jalur endpoint (ubah di sini bila backend memakai nama lain) ---
  static const String loginPath = '/api/v1/auth/login';
  static const String forecastPath = '/api/v1/forecast';
  static const String reportsPath = '/api/v1/reports';
}
