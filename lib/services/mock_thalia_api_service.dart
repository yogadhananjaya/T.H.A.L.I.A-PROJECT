import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import 'thalia_api_service.dart';

/// Login contoh untuk pengembangan UI tanpa server: username `admin`, sandi `123`.
final class MockAuthService implements AuthService {
  MockAuthService({this.latency = const Duration(milliseconds: 320)});

  /// Jeda buatan supaya animasi loading terlihat seperti memanggil server.
  final Duration latency;

  static const String _username = 'admin';
  static const String _password = '123';

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final ok = username.trim().toLowerCase() == _username && password == _password;
    if (!ok) {
      throw const ApiException('Username atau kata sandi salah.');
    }
    return const AuthSession(accessToken: 'mock-token', userName: 'Admin');
  }

  @override
  Future<void> logout() async {}
}

/// Data contoh bawaan aplikasi (sama dengan tampilan sebelum API tersambung).
/// Laporan yang dikirim disimpan di memori selama aplikasi hidup.
final class MockThaliaApiService implements ThaliaApiService {
  final List<FieldReportItemModel> _reports =
      List<FieldReportItemModel>.of(FieldReportItemModel.samples);

  @override
  Future<List<ForecastDayModel>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    return List<ForecastDayModel>.of(ForecastDayModel.samples);
  }

  @override
  Future<List<FieldReportItemModel>> fetchReports() async {
    return List<FieldReportItemModel>.of(_reports);
  }

  @override
  Future<FieldReportItemModel> submitReport(FieldReportDraft draft) async {
    final saved = FieldReportItemModel.fromDraft(
      draft,
      id: 'RPT-${_reports.length + 1}',
    );
    _reports.insert(0, saved);
    return saved;
  }
}
