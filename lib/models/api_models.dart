import 'dart:convert';
import 'dart:typed_data';

/// Kesalahan yang dilempar lapisan API. [message] aman ditampilkan ke pengguna.
final class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Hasil login/register dari server beserta profil pengguna aktif (B20, B22).
final class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.userName,
    this.email,
    this.phone,
    this.handle,
    this.role = 'warga',
    this.locationName,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final String accessToken;
  final String? userName;
  final String? email;
  final String? phone;
  final String? handle;
  final String role;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? radiusKm;

  /// True bila akun memiliki wewenang pegawai/petugas verifikator laporan lapangan.
  bool get isStaffVerifier {
    final normalized = role.toLowerCase();
    return normalized == 'staff' ||
        normalized == 'admin' ||
        normalized == 'petugas';
  }

  AuthSession copyWith({
    String? accessToken,
    String? userName,
    String? email,
    String? phone,
    String? handle,
    String? role,
    String? locationName,
    double? latitude,
    double? longitude,
    int? radiusKm,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      handle: handle ?? this.handle,
      role: role ?? this.role,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'user_name': userName,
        'email': email,
        'phone': phone,
        'handle': handle,
        'role': role,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      };

  /// Membaca payload login/register baik dari format nested `user` maupun flat.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Jawaban login dari server tidak memuat access_token.');
    }
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AuthSession(
      accessToken: token,
      userName: (user['name'] as String?) ?? (json['user_name'] as String?),
      email: (user['email'] as String?) ?? (json['email'] as String?),
      phone: (user['phone'] as String?) ?? (json['phone'] as String?),
      handle: (user['handle'] as String?) ?? (json['handle'] as String?),
      role: (user['role'] as String?) ?? (json['role'] as String?) ?? 'warga',
      locationName: (user['location_name'] as String?) ?? (json['location_name'] as String?),
      latitude: ((user['latitude'] ?? json['latitude']) as num?)?.toDouble(),
      longitude: ((user['longitude'] ?? json['longitude']) as num?)?.toDouble(),
      radiusKm: ((user['radius_km'] ?? json['radius_km']) as num?)?.toInt(),
    );
  }
}

/// Isi form laporan warga yang dikirim ke server.
final class FieldReportDraft {
  const FieldReportDraft({
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.capturedAt,
    this.photoBytes,
  });

  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime capturedAt;
  final Uint8List? photoBytes;

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'captured_at': capturedAt.toUtc().toIso8601String(),
        if (photoBytes != null) 'photo_base64': base64Encode(photoBytes!),
      };
}
