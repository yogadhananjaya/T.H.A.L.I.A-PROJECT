/// Utilitas privasi & keamanan untuk mencegah kebocoran data sensitif (PII/Token)
/// pada log maupun pesan galat antarmuka pengguna.
abstract final class PrivacyGuard {
  static final RegExp _tokenPattern = RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*');
  static final RegExp _emailPattern =
      RegExp(r'\b([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*(@[A-Za-z0-9.-]+\.[A-Za-z]{2,})\b');

  /// Menyamarkan alamat email agar tidak terekspos utuh di log atau UI.
  static String redactEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 1) return '***';
    final prefix = trimmed.substring(0, atIndex > 2 ? 2 : 1);
    final domain = trimmed.substring(atIndex);
    return '$prefix***$domain';
  }

  /// Menyamarkan token autentikasi dengan hanya menampilkan 4 karakter terakhir.
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '<empty>';
    if (token.length <= 6) return '***';
    return '***${token.substring(token.length - 4)}';
  }

  /// Membulatkan koordinat GPS untuk log diagnostik agar lokasi presisi pengguna tetap terjaga.
  static double roundCoordinateForLog(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  /// Membersihkan pesan error dari token Bearer atau email sebelum ditampilkan/dicatat.
  static String sanitizeErrorMessage(Object error) {
    var msg = error.toString();
    msg = msg.replaceAll(_tokenPattern, 'Bearer ***');
    msg = msg.replaceAllMapped(_emailPattern, (m) => '${m.group(1)}***${m.group(2)}');
    if (msg.length > 220) {
      msg = '${msg.substring(0, 217)}...';
    }
    return msg;
  }
}
