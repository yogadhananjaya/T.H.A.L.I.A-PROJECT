import '../config/api_config.dart';
import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import 'api_client.dart';
import 'thalia_api_service.dart';

/// Layanan autentikasi terhadap backend FastAPI.
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
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    String locationName = '',
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.post(
      ApiConfig.registerPath,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'location_name': locationName.trim(),
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Jawaban pendaftaran dari server tidak dikenali.');
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

  @override
  Future<String> forgotPassword({required String email}) async {
    final data = await _client.post(
      ApiConfig.forgotPasswordPath,
      body: {'email': email.trim()},
    );
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Permintaan reset kata sandi telah dikirim.';
  }

  @override
  Future<AuthSession> updateProfile({
    String? fullName,
    String? phone,
    String? handle,
    String? locationName,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) async {
    final data = await _client.put(
      ApiConfig.profilePath,
      body: {
        'full_name': ?fullName,
        'phone': ?phone,
        'handle': ?handle,
        'location_name': ?locationName,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'radius_km': ?radiusKm,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Jawaban pembaruan profil tidak dikenali.');
    }
    return AuthSession(
      accessToken: _client.accessToken ?? '',
      userName: data['user_name'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      handle: data['handle'] as String?,
      locationName: data['location_name'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      radiusKm: (data['radius_km'] as num?)?.toInt(),
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
    int radiusKm = 5,
  }) async {
    final data = await _client.get(
      ApiConfig.forecastPath,
      query: {
        'lat': latitude.toStringAsFixed(6),
        'lng': longitude.toStringAsFixed(6),
        'radius_km': '$radiusKm',
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
    final dynamic data;
    if (draft.photoBytes != null && draft.photoBytes!.isNotEmpty) {
      data = await _client.postMultipart(
        ApiConfig.reportsPath,
        fields: {
          'category': draft.category,
          'description': draft.description,
          'latitude': draft.latitude.toString(),
          'longitude': draft.longitude.toString(),
          'location_name': draft.locationName,
          'captured_at': draft.capturedAt.toUtc().toIso8601String(),
        },
        fileBytes: draft.photoBytes,
      );
    } else {
      data = await _client.post(ApiConfig.reportsPath, body: draft.toJson());
    }
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
