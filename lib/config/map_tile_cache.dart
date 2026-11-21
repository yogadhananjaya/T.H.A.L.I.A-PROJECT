import 'package:flutter_map/flutter_map.dart';

/// Pengaturan cache tile peta. flutter_map 8.x menyimpan tile ke folder cache
/// dengan batas bawaan 1 GB; di sini dibatasi supaya ukuran aplikasi tetap kecil.
final class MapTileCache {
  const MapTileCache._();

  /// Batas lunak cache tile di penyimpanan HP.
  static const int maxCacheBytes = 50 * 1024 * 1024;

  /// Setiap peta memegang satu provider sendiri (TileLayer yang melepasnya saat dispose),
  /// sedangkan cache di disk dipakai bersama oleh semua provider.
  static NetworkTileProvider createTileProvider() {
    return NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: maxCacheBytes,
      ),
    );
  }
}
