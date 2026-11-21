import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../config/api_config.dart';
import '../models/api_models.dart';

/// Klien HTTP tunggal untuk semua panggilan ke backend FastAPI.
/// Menggunakan ulang satu [HttpClient] (B35), menangani 401 otomatis,
/// dan mendukung unggah foto multipart (B31).
final class ApiClient {
  ApiClient({String? baseUrl, Duration? timeout})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        timeout = timeout ?? ApiConfig.requestTimeout;

  final String baseUrl;
  final Duration timeout;

  /// Diisi setelah login berhasil, dikirim sebagai `Authorization: Bearer <token>`.
  String? accessToken;

  /// Dipanggil otomatis saat server mengembalikan HTTP 401 (sesi habis / tidak sah, B35).
  void Function()? onUnauthorized;

  HttpClient? _client;
  HttpClient get _http => _client ??= (HttpClient()..connectionTimeout = timeout);

  void close() {
    _client?.close(force: true);
    _client = null;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _sendWithRetry('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  /// Menjalankan request GET idempoten dengan retry + exponential backoff (300ms, 700ms)
  /// untuk ketahanan terhadap gangguan jaringan sementara (Reliability & Availability).
  Future<dynamic> _sendWithRetry(
    String method,
    String path, {
    Map<String, String>? query,
    int maxRetries = 2,
  }) async {
    const delaysMs = <int>[300, 700];
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _send(method, path, query: query);
      } on ApiException catch (e) {
        final isTransientStatus =
            e.statusCode == null || e.statusCode == 502 || e.statusCode == 503 || e.statusCode == 504;
        if (!isTransientStatus || attempt == maxRetries) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: delaysMs[attempt]));
      }
    }
  }

  /// Mengirim form multipart dengan lampiran foto biner (B31).
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    Uint8List? fileBytes,
    String fileField = 'photo',
    String fileName = 'report.jpg',
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final uploadTimeout = ApiConfig.uploadTimeout;
    final boundary = '----ThaliaBoundary${DateTime.now().microsecondsSinceEpoch}';

    try {
      final request = await _http.openUrl('POST', uri).timeout(uploadTimeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      final token = accessToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      for (final entry in fields.entries) {
        request.add(utf8.encode('--$boundary\r\n'));
        request.add(
          utf8.encode('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n'),
        );
        request.add(utf8.encode('${entry.value}\r\n'));
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.add(utf8.encode('--$boundary\r\n'));
        request.add(
          utf8.encode(
            'Content-Disposition: form-data; name="$fileField"; filename="$fileName"\r\n'
            'Content-Type: image/jpeg\r\n\r\n',
          ),
        );
        request.add(fileBytes);
        request.add(utf8.encode('\r\n'));
      }

      request.add(utf8.encode('--$boundary--\r\n'));

      final response = await request.close().timeout(uploadTimeout);
      final text =
          await response.transform(utf8.decoder).join().timeout(uploadTimeout);

      return _handleResponse(response.statusCode, text, hadToken: token != null);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Unggahan memakan waktu terlalu lama. Coba lagi.');
    } on SocketException {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
    } on FormatException {
      throw const ApiException('Jawaban server tidak berformat JSON yang valid.');
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    try {
      final request = await _http.openUrl(method, uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        'X-Request-ID',
        'thalia-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (path.contains('/auth/')) {
        request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      }
      final token = accessToken;
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close().timeout(timeout);
      final text =
          await response.transform(utf8.decoder).join().timeout(timeout);

      return _handleResponse(response.statusCode, text, hadToken: token != null);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi sebentar.');
    } on SocketException {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
    } on FormatException {
      throw const ApiException('Jawaban server tidak berformat JSON yang valid.');
    }
  }

  dynamic _handleResponse(
    int statusCode,
    String text, {
    required bool hadToken,
  }) {
    if (statusCode == HttpStatus.unauthorized && hadToken) {
      accessToken = null;
      onUnauthorized?.call();
      throw const ApiException(
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
        statusCode: HttpStatus.unauthorized,
      );
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(
        _errorMessage(text) ?? 'Server menjawab dengan kode $statusCode.',
        statusCode: statusCode,
      );
    }
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  /// FastAPI membungkus pesan galat dalam `{"detail": "..."}`.
  String? _errorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final detail = data['detail'] ?? data['message'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {}
    return null;
  }
}
