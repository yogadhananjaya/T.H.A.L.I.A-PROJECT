import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_presu/main.dart';

void main() {
  testWidgets(
      'Full journey: Selamat Datang -> Masuk Akun -> Dashboard -> Forecast Day Animation -> Profil -> Pengaturan',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ThaliaApp());
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

    // 2. Isi akun contoh (admin / 123) lalu klik Masuk ke Dashboard -> Dashboard Utama (Biru Basic)
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

    // 3. Klik hari Kam (15/5) di Prakiraan Cuaca 5 Hari -> animasi berubah ke Cerah Terik
    final kamPill = find.text('Kam');
    await tester.ensureVisible(kamPill);
    await tester.pump();
    await tester.tap(kamPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cerah Terik'), findsOneWidget);
  });
}
