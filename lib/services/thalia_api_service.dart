import '../models/api_models.dart';
import '../models/dashboard_models.dart';

/// Kontrak autentikasi. Controller hanya bergantung pada kelas abstrak ini,
/// jadi implementasinya (data contoh atau server sungguhan) bisa ditukar
/// tanpa menyentuh UI.
abstract interface class AuthService {
  /// Melempar [ApiException] bila kredensial salah atau server tidak terjangkau.
  Future<AuthSession> login({required String username, required String password});

  /// Mendaftarkan akun baru dan mengembalikan sesi (B03).
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    String locationName = '',
    double? latitude,
    double? longitude,
  });

  Future<void> logout();

  /// Mengganti kata sandi akun yang sedang login.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Mengirim permintaan reset kata sandi ke server (B22).
  Future<String> forgotPassword({required String email});

  /// Memperbarui profil atau lokasi pantauan pengguna (B20).
  Future<AuthSession> updateProfile({
    String? fullName,
    String? phone,
    String? handle,
    String? locationName,
    double? latitude,
    double? longitude,
    int? radiusKm,
  });
}

/// Kontrak data dashboard (prakiraan, sensor, laporan warga).
/// Implementasi: [MockThaliaApiService] dan [HttpThaliaApiService].
abstract interface class ThaliaApiService {
  /// Prakiraan multi-hari untuk koordinat & radius tertentu (B18).
  Future<List<ForecastDayModel>> fetchForecast({
    required double latitude,
    required double longitude,
    int radiusKm = 5,
  });

  /// Riwayat laporan warga milik pengguna yang sedang login (mendukung pagination).
  Future<List<FieldReportItemModel>> fetchReports({int limit = 50, int offset = 0});

  /// Mengirim laporan baru dan mengembalikan laporan yang tersimpan di server.
  Future<FieldReportItemModel> submitReport(FieldReportDraft draft);

  /// Memverifikasi keaslian laporan warga (khusus akun pegawai/staff/admin).
  Future<FieldReportItemModel> verifyReport({
    required String reportId,
    required bool approve,
    String note = '',
  });
}
