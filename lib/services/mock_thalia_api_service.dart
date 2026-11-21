import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import 'thalia_api_service.dart';

final class _MockUserRecord {
  _MockUserRecord({
    required this.fullName,
    required this.email,
    required this.username,
    required this.password,
    this.phone = '+62 812-0000-2026',
    this.handle = '@petugas_thalia',
    this.locationName = '',
    this.latitude,
    this.longitude,
  });

  String fullName;
  String email;
  String username;
  String password;
  String phone;
  String handle;
  String locationName;
  double? latitude;
  double? longitude;
  int radiusKm = 5;

  AuthSession toSession() => AuthSession(
        accessToken: 'mock-token-$username',
        userName: fullName,
        email: email,
        phone: phone,
        handle: handle,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
}

/// Layanan auth contoh untuk pengembangan UI tanpa server:
/// mendukung login akun `admin` / `123` maupun akun yang baru didaftarkan (B01, B03).
final class MockAuthService implements AuthService {
  MockAuthService({this.latency = const Duration(milliseconds: 320)}) {
    final admin = _MockUserRecord(
      fullName: 'Petugas Siaga T.H.A.L.I.A',
      email: 'admin@gmail.com',
      username: 'admin',
      password: '123',
      handle: '@admin_thalia',
    );
    _usersByIdentifier['admin'] = admin;
    _usersByIdentifier['admin@gmail.com'] = admin;
  }

  /// Jeda buatan supaya animasi loading terlihat seperti memanggil server.
  final Duration latency;

  final Map<String, _MockUserRecord> _usersByIdentifier = {};
  _MockUserRecord? _activeUser;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final key = username.trim().toLowerCase();
    final record = _usersByIdentifier[key];
    if (record == null || record.password != password) {
      throw const ApiException('Username/email atau kata sandi salah.');
    }
    _activeUser = record;
    return record.toSession();
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
    await Future<void>.delayed(latency);
    final cleanEmail = email.trim().toLowerCase();
    if (_usersByIdentifier.containsKey(cleanEmail)) {
      throw const ApiException('Email sudah terdaftar. Silakan masuk.');
    }
    final username = cleanEmail.split('@').first;
    final record = _MockUserRecord(
      fullName: fullName.trim(),
      email: cleanEmail,
      username: username,
      password: password,
      phone: '-',
      handle: '@$username',
      locationName: locationName.trim(),
      latitude: latitude,
      longitude: longitude,
    );
    _usersByIdentifier[cleanEmail] = record;
    _usersByIdentifier[username] = record;
    _activeUser = record;
    return record.toSession();
  }

  @override
  Future<void> logout() async {
    _activeUser = null;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(latency);
    final user = _activeUser ?? _usersByIdentifier['admin'];
    if (user == null || currentPassword != user.password) {
      throw const ApiException('Kata sandi saat ini salah.');
    }
    if (currentPassword == newPassword) {
      throw const ApiException('Kata sandi baru harus berbeda dari yang lama.');
    }
    user.password = newPassword;
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    await Future<void>.delayed(latency);
    return 'Tautan reset kata sandi telah dikirim ke ${email.trim()}.';
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
    await Future<void>.delayed(latency);
    final user = _activeUser ?? _usersByIdentifier['admin']!;
    if (fullName != null && fullName.trim().isNotEmpty) {
      user.fullName = fullName.trim();
    }
    if (phone != null) user.phone = phone.trim();
    if (handle != null) user.handle = handle.trim();
    if (locationName != null) user.locationName = locationName.trim();
    if (latitude != null) user.latitude = latitude;
    if (longitude != null) user.longitude = longitude;
    if (radiusKm != null) user.radiusKm = radiusKm;
    return user.toSession();
  }
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
    int radiusKm = 5,
  }) async {
    return ForecastDayModel.samplesForToday();
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
