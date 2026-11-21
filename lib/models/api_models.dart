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

/// Hasil login dari server.
final class AuthSession {
  const AuthSession({required this.accessToken, this.userName});

  final String accessToken;
  final String? userName;

  /// Bentuk JSON yang diharapkan:
  /// `{"access_token": "...", "token_type": "bearer", "user": {"name": "..."}}`
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Jawaban login dari server tidak memuat access_token.');
    }
    final user = json['user'];
    return AuthSession(
      accessToken: token,
      userName: user is Map<String, dynamic> ? user['name'] as String? : null,
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
