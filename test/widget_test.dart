import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_presu/controllers/auth_controller.dart';
import 'package:ui_presu/controllers/dashboard_controller.dart';
import 'package:ui_presu/main.dart';
import 'package:ui_presu/models/auth_models.dart';
import 'package:ui_presu/models/dashboard_models.dart';
import 'package:ui_presu/screens/splash_screen.dart';
import 'package:ui_presu/services/mock_thalia_api_service.dart';
import 'package:ui_presu/utils/validators.dart';

void main() {
  testWidgets(
      'SplashScreen displays T.H.A.L.I.A text then slides up logo and transitions to app',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ThaliaApp());

    // Fase 1: Teks T.H.A.L.I.A muncul di awal
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('T.H.A.L.I.A'), findsOneWidget);

    // Fase 2: Logo muncul dengan transisi slide up
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(SlideTransition),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    // Fase 3: Setelah 2.2s + transition, masuk ke Selamat Datang
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Selamat Datang'), findsOneWidget);
  });

  testWidgets(
      'Full journey: Selamat Datang -> Masuk Akun (admin/123) -> Dashboard -> Forecast Day Animation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ThaliaApp(showSplash: false));
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Mulai di Selamat Datang -> Klik Masuk ke Masuk Akun
    expect(find.text('Selamat Datang'), findsOneWidget);
    final masukLink = find.text('Masuk');
    await tester.ensureVisible(masukLink);
    await tester.pump();
    await tester.tap(masukLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Masuk Akun'), findsOneWidget);

    // 2. Isi akun contoh (admin / 123) lalu klik Masuk ke Dashboard (B01)
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.pump();
    final loginBtn = find.text('Masuk ke Dashboard');
    await tester.ensureVisible(loginBtn);
    await tester.pump();
    await tester.tap(loginBtn);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hujan Ringan'), findsOneWidget);
    expect(find.text('Prakiraan Cuaca 5 Hari'), findsOneWidget);

    // 3. Ketuk kapsul hari ke-4 (31° -> Cerah Terik) secara dinamis sesuai DateTime.now() (B26)
    final fourthDayTemp = find.text('31°');
    await tester.ensureVisible(fourthDayTemp);
    await tester.pump();
    await tester.tap(fourthDayTemp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cerah Terik'), findsOneWidget);
  });

  group('ThaliaValidators unit tests (B01, B24, B25)', () {
    test('allows valid names including dot, apostrophe, and hyphen', () {
      expect(ThaliaValidators.validateFullName('M. Rafie'), isNull);
      expect(ThaliaValidators.validateFullName("D'Angelo"), isNull);
      expect(ThaliaValidators.validateFullName('Siti Nur-Aini'), isNull);
      expect(ThaliaValidators.validateFullName('Rafie123'), isNotNull);
    });

    test('validates @gmail.com email and 5-char unified password', () {
      expect(ThaliaValidators.validateRegisterEmail('rafie@gmail.com'), isNull);
      expect(ThaliaValidators.validateRegisterEmail('rafie@yahoo.com'), isNotNull);
      expect(ThaliaValidators.validatePassword('12345'), isNull);
      expect(ThaliaValidators.validatePassword('1234'), isNotNull);
    });

    test('login accepts short mock password without client length block (B01)', () {
      expect(ThaliaValidators.validateLoginIdentifier('admin'), isNull);
      expect(ThaliaValidators.validateLoginPassword('123'), isNull);
    });
  });

  group('AuthController & MockAuthService integration (B03, B07, B08)', () {
    test('registers user and allows login with registered account', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthController(authService: MockAuthService(latency: Duration.zero));

      // Default terms must be false (B24)
      expect(auth.registerModel.agreedToTerms, isFalse);

      auth.updateRegisterName('Siti Nur-Aini');
      auth.updateRegisterEmail('siti.nur@gmail.com');
      auth.updateRegisterPassword('rahasia');
      auth.updateRegisterConfirmPassword('rahasia');
      auth.toggleTermsAgreed();

      final ok = await auth.submitRegister();
      expect(ok, isTrue);
      expect(auth.currentStep, AuthScreenStep.login);
      expect(auth.feedbackIsError, isFalse);

      // Login using newly registered email
      auth.updateLoginEmail('siti.nur@gmail.com');
      auth.updateLoginPassword('rahasia');
      await auth.submitLogin();
      expect(auth.currentStep, AuthScreenStep.dashboard);
      expect(auth.activeSession?.userName, 'Siti Nur-Aini');
    });

    test('sets feedbackIsError true on validation failure (B07)', () async {
      final auth = AuthController(authService: MockAuthService(latency: Duration.zero));
      auth.updateLoginEmail('');
      await auth.submitLogin();
      expect(auth.feedbackIsError, isTrue);
      expect(auth.feedbackBanner, isNotNull);
    });
  });

  group('DashboardController & JSON Model parsing (B09, B23, B26)', () {
    test('validates report form requires photo and min 10 chars description (B09)', () async {
      final dash = DashboardController(api: MockThaliaApiService());
      expect(dash.reportDescription, isEmpty);

      final emptyResult = await dash.submitFieldPhotoReport(locationName: 'Cikarang');
      expect(emptyResult, isFalse);
      expect(dash.reportFormError, isNotNull);

      dash.setCapturedPhotoFromCamera(Uint8List.fromList([1, 2, 3, 4]));
      dash.updateReportDescription('Air sungai meluap ke jalan utama setinggi 35 cm.');
      final okResult = await dash.submitFieldPhotoReport(locationName: 'Cikarang');
      expect(okResult, isTrue);
      expect(dash.reportDescription, isEmpty);
      expect(dash.capturedPhotoBytes, isNull);
    });

    test('parses ForecastDayModel & FieldReportItemModel from backend JSON (B23)', () {
      final day = ForecastDayModel.fromJson({
        'date': '2026-11-21',
        'condition_code': 'light_rain',
        'temperature_c': 26,
        'rainfall_mm_per_hour': 2.0,
        'humidity_pct': 78,
        'water_level_cm': 110,
        'soil_moisture_pct': 52,
        'status': 'aman',
      });
      expect(day.temperatureC, 26);
      expect(day.conditionTitle, 'Hujan Ringan');

      final processing = FieldReportItemModel.fromJson({
        'id': '10',
        'title': 'Luapan Kali',
        'habitat': 'hydrosphere',
        'status': 'processing',
        'created_at': '2026-11-21T10:00:00Z',
        'description': 'Air mulai naik di pintu air.',
      });
      expect(processing.statusLabel, 'Proses');
      expect(processing.isCompleted, isFalse);
    });
  });
}
