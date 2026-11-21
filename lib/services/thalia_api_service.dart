import '../models/api_models.dart';
import '../models/dashboard_models.dart';

/// Kontrak autentikasi. Controller hanya bergantung pada kelas abstrak ini,
/// jadi implementasinya (data contoh atau server sungguhan) bisa ditukar
/// tanpa menyentuh UI.
abstract interface class AuthService {
  /// Melempar [ApiException] bila kredensial salah atau server tidak terjangkau.
  Future<AuthSession> login({required String username, required String password});

  Future<void> logout();

  /// Mengganti kata sandi akun yang sedang login.
  /// Melempar [ApiException] bila sandi saat ini salah atau server tidak terjangkau.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Kontrak data dashboard (prakiraan, sensor, laporan warga).
/// Implementasi: [MockThaliaApiService] dan [HttpThaliaApiService].
abstract interface class ThaliaApiService {
  /// Prakiraan 5 hari untuk koordinat tertentu. Hari pertama biasanya berisi
  /// pembacaan sensor lokal terbaru, hari berikutnya prakiraan BMKG.
  Future<List<ForecastDayModel>> fetchForecast({
    required double latitude,
    required double longitude,
  });

  /// Riwayat laporan warga milik pengguna yang sedang login.
  Future<List<FieldReportItemModel>> fetchReports();

  /// Mengirim laporan baru dan mengembalikan laporan yang tersimpan di server.
  Future<FieldReportItemModel> submitReport(FieldReportDraft draft);
}
