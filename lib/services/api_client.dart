import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_models.dart';

/// Klien HTTP tunggal lintas platform (Android, iOS, & Chrome Web) untuk semua panggilan ke backend FastAPI.
/// Menggunakan ulang satu [http.Client] (B35), retry dengan exponential backoff,
/// menangani 401 otomatis, dan mendukung unggah foto multipart (B31).
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

  http.Client? _client;
  http.Client get _http => _client ??= http.Client();

  void close() {
    _client?.close();
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
        final isTransientStatus = e.statusCode == null ||
            e.statusCode == 502 ||
            e.statusCode == 503 ||
            e.statusCode == 504;
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
    final token = accessToken;

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['X-Request-ID'] =
          'thalia-${DateTime.now().microsecondsSinceEpoch}';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: fileName,
          ),
        );
      }

      final streamed = await _http.send(request).timeout(uploadTimeout);
      final response =
          await http.Response.fromStream(streamed).timeout(uploadTimeout);
      return _handleResponse(
        response.statusCode,
        response.body,
        hadToken: token != null,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Unggahan memakan waktu terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
    } on FormatException {
      throw const ApiException('Jawaban server tidak berformat JSON yang valid.');
    } catch (_) {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
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

    final token = accessToken;
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Request-ID': 'thalia-${DateTime.now().microsecondsSinceEpoch}',
      if (path.contains('/auth/')) 'Cache-Control': 'no-store',
      if (token != null) 'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      final http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          response = await _http
              .post(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        case 'PUT':
          response = await _http
              .put(uri, headers: headers, body: encodedBody)
              .timeout(timeout);
        default:
          throw ApiException('Metode HTTP tidak didukung: $method');
      }

      return _handleResponse(
        response.statusCode,
        response.body,
        hadToken: token != null,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi sebentar.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
    } on FormatException {
      throw const ApiException('Jawaban server tidak berformat JSON yang valid.');
    } catch (_) {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Periksa alamat API dan koneksi.',
      );
    }
  }

  dynamic _handleResponse(
    int statusCode,
    String text, {
    required bool hadToken,
  }) {
    if (statusCode == 401 && hadToken) {
      accessToken = null;
      onUnauthorized?.call();
      throw const ApiException(
        'Sesi Anda telah berakhir. Silakan masuk kembali.',
        statusCode: 401,
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
