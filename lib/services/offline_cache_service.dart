import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_models.dart';

/// Layanan cache offline-first untuk menyimpan prakiraan cuaca terakhir secara lokal.
/// Memungkinkan aplikasi tetap menampilkan data terakhir yang valid saat berada
/// di area bencana tanpa jaringan (Availability & Reliability).
abstract final class OfflineCacheService {
  static const String _forecastCacheKey = 'thalia_cached_forecast_v1';
  static const String _forecastCachedAtKey = 'thalia_cached_forecast_at_v1';

  /// Menyimpan daftar prakiraan cuaca terakhir yang berhasil diambil dari server.
  static Future<void> saveForecast(List<ForecastDayModel> days) async {
    if (days.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(days.map((d) => d.toCacheJson()).toList());
      await prefs.setString(_forecastCacheKey, encoded);
      await prefs.setString(
        _forecastCachedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      // Abaikan kegagalan cache lokal agar tidak mengganggu alur utama.
    }
  }

  /// Memuat prakiraan cuaca tersimpan beserta waktu penyimpanan (jika ada).
  static Future<({List<ForecastDayModel> days, DateTime? cachedAt})>
      loadForecast() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_forecastCacheKey);
      if (raw == null || raw.isEmpty) {
        return (days: const <ForecastDayModel>[], cachedAt: null);
      }
      final list = jsonDecode(raw) as List<dynamic>;
      final days = list
          .whereType<Map<String, dynamic>>()
          .map(ForecastDayModel.fromCacheJson)
          .toList();
      final tsRaw = prefs.getString(_forecastCachedAtKey);
      final cachedAt = tsRaw == null ? null : DateTime.tryParse(tsRaw);
      return (days: days, cachedAt: cachedAt);
    } catch (_) {
      return (days: const <ForecastDayModel>[], cachedAt: null);
    }
  }

  /// Menghapus cache saat logout agar data sesi pengguna sebelumnya tidak tertinggal (Privacy).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_forecastCacheKey);
      await prefs.remove(_forecastCachedAtKey);
    } catch (_) {}
  }
}
