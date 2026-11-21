import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../models/api_models.dart';

/// Klien HTTP tunggal untuk semua panggilan ke backend FastAPI.
/// Memakai dart:io bawaan Flutter, jadi tidak menambah ukuran aplikasi.
final class ApiClient {
  ApiClient({String? baseUrl, Duration? timeout})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        timeout = timeout ?? ApiConfig.requestTimeout;

  final String baseUrl;
  final Duration timeout;

  /// Diisi setelah login berhasil, dikirim sebagai `Authorization: Bearer <token>`.
  String? accessToken;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
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

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.openUrl(method, uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(text) ?? 'Server menjawab dengan kode ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      if (text.isEmpty) return null;
      return jsonDecode(text);
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
    } finally {
      client.close(force: true);
    }
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
