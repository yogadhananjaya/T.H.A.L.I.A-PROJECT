import '../config/api_config.dart';
import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import 'api_client.dart';
import 'thalia_api_service.dart';

/// Login ke backend FastAPI. Kontrak JSON ada di API_INTEGRATION.md.
final class HttpAuthService implements AuthService {
  HttpAuthService(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final data = await _client.post(
      ApiConfig.loginPath,
      body: {'username': username.trim(), 'password': password},
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Jawaban login dari server tidak dikenali.');
    }
    final session = AuthSession.fromJson(data);
    _client.accessToken = session.accessToken;
    return session;
  }

  @override
  Future<void> logout() async {
    _client.accessToken = null;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post(
      ApiConfig.changePasswordPath,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}

/// Data dashboard dari backend FastAPI (yang menerima data ESP32, membandingkan
/// dengan BMKG, dan mencatat kejadian kritis ke blockchain).
final class HttpThaliaApiService implements ThaliaApiService {
  HttpThaliaApiService(this._client);

  final ApiClient _client;

  @override
  Future<List<ForecastDayModel>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _client.get(
      ApiConfig.forecastPath,
      query: {
        'lat': latitude.toStringAsFixed(6),
        'lng': longitude.toStringAsFixed(6),
        'days': '5',
      },
    );
    return _asObjectList(data, key: 'days')
        .map(ForecastDayModel.fromJson)
        .toList();
  }

  @override
  Future<List<FieldReportItemModel>> fetchReports() async {
    final data = await _client.get(ApiConfig.reportsPath);
    return _asObjectList(data, key: 'reports')
        .map(FieldReportItemModel.fromJson)
        .toList();
  }

  @override
  Future<FieldReportItemModel> submitReport(FieldReportDraft draft) async {
    final data = await _client.post(ApiConfig.reportsPath, body: draft.toJson());
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Jawaban kirim laporan dari server tidak dikenali.');
    }
    return FieldReportItemModel.fromJson(data);
  }

  /// Menerima array JSON langsung, atau objek pembungkus seperti `{"days": [...]}`.
  List<Map<String, dynamic>> _asObjectList(dynamic data, {required String key}) {
    final list = data is Map<String, dynamic> ? data[key] : data;
    if (list is! List) {
      throw ApiException('Jawaban server tidak memuat daftar "$key".');
    }
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
