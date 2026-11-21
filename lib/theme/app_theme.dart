import 'package:flutter/material.dart';

/// Token warna resmi hasil ekstraksi langsung dari LOGIN.figcraft.
abstract final class ThaliaColors {
  // Light Mode (Kanvas Utama LOGIN.figcraft)
  static const Color canvasLight = Color(0xFFF6F5EF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color inputFillLogin = Color(0xFFEAE6DC);
  static const Color borderLight = Color(0xFFDFDCD2);
  static const Color borderCard = Color(0xFFDDD9CE);

  // Dark Mode (Saat pengguna memilih "Gelap" di layar Pengaturan)
  static const Color canvasDark = Color(0xFF101918);
  static const Color cardDark = Color(0xFF172422);
  static const Color inputFillDark = Color(0xFF1D2D2A);
  static const Color borderDark = Color(0xFF2B3F3B);

  // Tipografi & Tombol Utama
  static const Color forestDark = Color(0xFF1D2F2B);
  static const Color forestDarkAlt = Color(0xFF1B2D2A);
  static const Color textMuted = Color(0xFF5A6B66);
  static const Color textMutedAlt = Color(0xFF5E6E6A);

  // Aksen Tri-Habitat (LOGIN.figcraft)
  static const Color tealAccent = Color(0xFF3B7A72);
  static const Color emeraldPrimary = Color(0xFF4EB26D);
  static const Color emeraldBright = Color(0xFF5DBA79);
  static const Color mintSoftFill = Color(0xFFE3ECE8);
  static const Color mintBannerFill = Color(0xFFE8F5EC);

  static const Color skyWave = Color(0xFF6EC3E8);
  static const Color skySoft = Color(0xFFA7D8EE);
  static const Color navyDeep = Color(0xFF1C3549);

  // Aksen Terracotta / Oranye (Titik Brand & Checkbox Simpan Sesi)
  static const Color terracotta = Color(0xFFC86446);
}

/// Kelas palet adaptif berbasis OOP untuk mendukung tema Terang & Gelap.
final class ThaliaPalette {
  const ThaliaPalette({required this.isDark});

  final bool isDark;

  Color get canvas =>
      isDark ? ThaliaColors.canvasDark : ThaliaColors.canvasLight;
  Color get card => isDark ? ThaliaColors.cardDark : ThaliaColors.cardLight;
  Color get loginInputFill =>
      isDark ? ThaliaColors.inputFillDark : ThaliaColors.inputFillLogin;
  Color get border =>
      isDark ? ThaliaColors.borderDark : ThaliaColors.borderLight;
  Color get cardBorder =>
      isDark ? ThaliaColors.borderDark : ThaliaColors.borderCard;
  Color get textPrimary =>
      isDark ? const Color(0xFFF3F6F4) : ThaliaColors.forestDark;
  Color get textSecondary =>
      isDark ? const Color(0xFF9AB0A9) : ThaliaColors.textMuted;
  Color get primaryButtonBg =>
      isDark ? ThaliaColors.emeraldPrimary : ThaliaColors.forestDark;
  Color get primaryButtonFg =>
      isDark ? ThaliaColors.canvasDark : Colors.white;
  Color get secondaryButtonBg =>
      isDark ? const Color(0xFF1B2E2A) : ThaliaColors.mintSoftFill;
  Color get secondaryButtonFg =>
      isDark ? const Color(0xFFD9EBE5) : ThaliaColors.forestDark;
}

abstract final class AppTheme {
  static final ThemeData _lightTheme = _create(isDark: false);
  static final ThemeData _darkTheme = _create(isDark: true);

  /// Mengembalikan instance [ThemeData] yang di-cache agar tidak memicu alokasi ulang tiap ketikan (B30).
  static ThemeData build({required bool isDark}) =>
      isDark ? _darkTheme : _lightTheme;

  static ThemeData _create({required bool isDark}) {
    final palette = ThaliaPalette(isDark: isDark);
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ThaliaColors.tealAccent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: palette.card,
      ),
      fontFamily: 'sans-serif',
    );
  }
}
