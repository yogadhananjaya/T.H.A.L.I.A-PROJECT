import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/api_config.dart';
import 'api_client.dart';

/// Data ringkas peringatan bencana yang diterima dari FCM maupun polling cadangan `/api/v1/alerts`.
final class EmergencyAlertBannerData {
  const EmergencyAlertBannerData({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.source,
  });

  final int id;
  final String title;
  final String body;
  final String severity;
  final String source; // 'fcm' atau 'polling_backup'

  bool get isDanger => severity.toLowerCase() == 'danger';
}

/// Layanan notifikasi hybrid (Opsi 1: Firebase Cloud Messaging + Opsi 2: Local Notification & Polling Backup).
///
/// - Jika `google-services.json` tersedia & koneksi internet stabil, FCM aktif sebagai jalur utama.
/// - Jika FCM tidak tersedia / gagal saat demo, polling berkala `GET /api/v1/alerts` + notifikasi lokal
///   Android otomatis menjadi cadangan sehingga peringatan darurat tetap muncul real-time.
final class AlertNotificationService {
  AlertNotificationService({this.apiClient});

  final ApiClient? apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _localReady = false;
  bool _fcmActive = false;
  bool get isFcmActive => _fcmActive;

  int? _lastSeenAlertId;
  Timer? _pollingTimer;
  StreamSubscription<RemoteMessage>? _fcmSub;

  void Function(EmergencyAlertBannerData alert)? onAlertReceived;

  static const String _channelId = 'thalia_disaster_alerts';
  static const String _channelName = 'Peringatan Bencana T.H.A.L.I.A';

  /// Menginisialisasi notifikasi lokal dan mencoba mengaktifkan FCM secara aman.
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _initFcmSafely();
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _localReady = true;
    } catch (_) {
      _localReady = false;
    }
  }

  Future<void> _initFcmSafely() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (!kIsWeb) {
        await messaging.subscribeToTopic('disaster_alerts');
      }
      _fcmSub?.cancel();
      _fcmSub = FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
        final title = msg.notification?.title ??
            (msg.data['title'] as String?) ??
            '⚠️ Peringatan Bencana T.H.A.L.I.A';
        final body = msg.notification?.body ??
            (msg.data['reason'] as String?) ??
            'Terdeteksi anomali cuaca/sensor di sekitar lokasi Anda.';
        final severity = (msg.data['severity'] as String?) ?? 'Alert';
        final alert = EmergencyAlertBannerData(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          body: body,
          severity: severity,
          source: 'fcm',
        );
        _dispatchAlert(alert);
      });
      _fcmActive = true;
    } catch (_) {
      // Fallback mulus: jika Firebase belum dikonfigurasi atau offline, jalankan mode backup.
      _fcmActive = false;
    }
  }

  /// Memulai polling cadangan ke `/api/v1/alerts` agar peringatan tetap masuk meski FCM tidak aktif.
  void startBackupPolling({
    Duration interval = const Duration(seconds: 12),
  }) {
    if (apiClient == null) return;
    _pollingTimer?.cancel();
    // Cek awal untuk mencatat baseline ID agar tidak membanjiri notifikasi lama.
    checkLatestAlerts(emitInitial: false);
    _pollingTimer = Timer.periodic(interval, (_) {
      checkLatestAlerts(emitInitial: true);
    });
  }

  void stopBackupPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Mengecek daftar insiden terbaru dari backend dan memicu notifikasi bila ada insiden baru.
  Future<EmergencyAlertBannerData?> checkLatestAlerts({
    bool emitInitial = true,
  }) async {
    final client = apiClient;
    if (client == null) return null;
    try {
      final data = await client.get(ApiConfig.alertsPath);
      if (data is! List || data.isEmpty) return null;

      final first = data.first;
      if (first is! Map<String, dynamic>) return null;

      final id = (first['id'] as num?)?.toInt();
      if (id == null) return null;

      if (_lastSeenAlertId == null) {
        _lastSeenAlertId = id;
        if (!emitInitial) return null;
      } else if (id <= _lastSeenAlertId!) {
        return null;
      }

      _lastSeenAlertId = id;
      final severity = (first['severity'] as String?) ?? 'Alert';
      final location = (first['location_name'] as String?) ?? 'Lokasi Sensor';
      final cause =
          (first['cause_summary'] as String?) ?? 'Anomali sensor terdeteksi.';
      final title = severity.toLowerCase() == 'danger'
          ? '⚠️ PERINGATAN BAHAYA ($location)'
          : '⚡ WASPADA BENCANA ($location)';

      final alert = EmergencyAlertBannerData(
        id: id,
        title: title,
        body: cause,
        severity: severity,
        source: 'polling_backup',
      );
      await _dispatchAlert(alert);
      return alert;
    } catch (_) {
      return null;
    }
  }

  Future<void> _dispatchAlert(EmergencyAlertBannerData alert) async {
    onAlertReceived?.call(alert);
    if (!_localReady || kIsWeb) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.max,
        priority: Priority.high,
      );
      await _localNotifications.show(
        alert.id.remainder(100000),
        alert.title,
        alert.body,
        const NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  void dispose() {
    stopBackupPolling();
    _fcmSub?.cancel();
    _fcmSub = null;
  }
}
