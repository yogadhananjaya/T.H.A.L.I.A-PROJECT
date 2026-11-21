/// Kumpulan aturan validasi terpusat untuk form Auth & Keamanan T.H.A.L.I.A.
///
/// Menjaga konsistensi kebijakan antar layar (Login, Daftar, Ganti Sandi).
final class ThaliaValidators {
  const ThaliaValidators._();

  /// Panjang minimal kata sandi seragam untuk pendaftaran & ganti sandi (B25).
  static const int minPasswordLength = 5;

  /// Batas maksimal ukuran foto profil (2 MB) sesuai label di layar profil (B24).
  static const int maxProfilePhotoBytes = 2 * 1024 * 1024;

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s.'-]+$");
  static final RegExp _gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');

  static String? validateFullName(String? raw) {
    final name = (raw ?? '').trim();
    if (name.isEmpty) {
      return 'Nama lengkap tidak boleh kosong.';
    }
    if (!_nameRegex.hasMatch(name)) {
      return 'Nama hanya boleh berisi huruf, spasi, titik, apostrof, atau tanda hubung.';
    }
    return null;
  }

  static String? validateRegisterEmail(String? raw) {
    final email = (raw ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      return 'Alamat email tidak boleh kosong.';
    }
    if (!_gmailRegex.hasMatch(email)) {
      return 'Email harus menggunakan domain @gmail.com (contoh: user@gmail.com).';
    }
    return null;
  }

  static String? validatePassword(String? raw, {String label = 'Kata sandi'}) {
    final password = raw ?? '';
    if (password.isEmpty) {
      return '$label tidak boleh kosong.';
    }
    if (password.length < minPasswordLength) {
      return '$label minimal harus $minPasswordLength karakter.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    final c = confirm ?? '';
    if (c.isEmpty) {
      return 'Konfirmasi kata sandi tidak boleh kosong.';
    }
    if ((password ?? '') != c) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }

  /// Validasi Login hanya memastikan tidak kosong; penilaian format diserahkan ke server (B01).
  static String? validateLoginIdentifier(String? raw) {
    if ((raw ?? '').trim().isEmpty) {
      return 'Email atau ID Petugas tidak boleh kosong.';
    }
    return null;
  }

  static String? validateLoginPassword(String? raw) {
    if ((raw ?? '').isEmpty) {
      return 'Kata sandi tidak boleh kosong.';
    }
    return null;
  }
}
