import '../config/api_config.dart';
import 'api_client.dart';
import 'http_thalia_api_service.dart';
import 'mock_thalia_api_service.dart';
import 'thalia_api_service.dart';

/// Wadah dependensi: memilih implementasi layanan (contoh atau server sungguhan)
/// berdasarkan [ApiConfig.useMockData], lalu dibagikan ke controller.
final class ThaliaServices {
  const ThaliaServices({
    required this.auth,
    required this.api,
    this.apiClient,
  });

  final AuthService auth;
  final ThaliaApiService api;
  final ApiClient? apiClient;

  /// Memakai data contoh bawaan (tanpa server).
  factory ThaliaServices.mock() {
    return ThaliaServices(auth: MockAuthService(), api: MockThaliaApiService());
  }

  /// Memakai backend FastAPI di [ApiConfig.baseUrl].
  factory ThaliaServices.http() {
    final client = ApiClient();
    return ThaliaServices(
      auth: HttpAuthService(client),
      api: HttpThaliaApiService(client),
      apiClient: client,
    );
  }

  /// Pilihan otomatis sesuai konfigurasi build.
  factory ThaliaServices.fromConfig() {
    return ApiConfig.useMockData ? ThaliaServices.mock() : ThaliaServices.http();
  }
}
