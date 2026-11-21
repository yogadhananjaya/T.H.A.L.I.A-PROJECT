import 'package:flutter/foundation.dart';
import '../models/api_models.dart';
import 'auth_controller.dart';

/// Penilaian kekuatan kata sandi untuk indikator 4 segmen di layar Keamanan & Kata Sandi.
final class PasswordStrength {
  const PasswordStrength._(this.filledSegments, this.label);

  /// Jumlah segmen yang menyala, 0 sampai 4.
  final int filledSegments;

  /// Kosong bila belum ada yang diketik.
  final String label;

  static const PasswordStrength empty = PasswordStrength._(0, '');

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return empty;

    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    var score = 0;
    if (password.length >= 8) score++;
    if (hasLower && hasUpper) score++;
    if (hasDigit && (hasLower || hasUpper)) score++;
    if (hasSymbol || password.length >= 12) score++;
    // Di bawah 8 karakter tidak pernah lebih dari "Lemah".
    if (password.length < 8) score = 1;

    switch (score.clamp(1, 4)) {
      case 1:
        return const PasswordStrength._(1, 'Lemah');
      case 2:
        return const PasswordStrength._(2, 'Cukup');
      case 3:
        return const PasswordStrength._(3, 'Baik');
      default:
        return const PasswordStrength._(4, 'Kuat');
    }
  }
}

/// Controller layar Keamanan & Kata Sandi: isi form, validasi, dan pemanggilan ganti sandi
/// lewat [AuthController] (yang meneruskannya ke AuthService, data contoh atau server).
final class SecurityController extends ChangeNotifier {
  SecurityController({required AuthController auth}) : _auth = auth;

  final AuthController _auth;

  /// Samakan dengan validasi di backend.
  static const int minPasswordLength = 8;

  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  bool _obscureCurrent = true;
  bool get obscureCurrent => _obscureCurrent;

  bool _obscureNew = true;
  bool get obscureNew => _obscureNew;

  bool _obscureConfirm = true;
  bool get obscureConfirm => _obscureConfirm;

  /// Hanya tampilan: belum ada endpoint 2FA di backend.
  bool _twoFactorEnabled = true;
  bool get twoFactorEnabled => _twoFactorEnabled;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _message;
  String? get message => _message;

  bool _messageIsError = false;
  bool get messageIsError => _messageIsError;

  PasswordStrength get strength => PasswordStrength.evaluate(_newPassword);

  bool get confirmMatches =>
      _confirmPassword.isNotEmpty && _confirmPassword == _newPassword;

  void updateCurrent(String value) {
    _currentPassword = value;
    _clearMessage();
  }

  void updateNew(String value) {
    _newPassword = value;
    _clearMessage();
  }

  void updateConfirm(String value) {
    _confirmPassword = value;
    _clearMessage();
  }

  void toggleObscureCurrent() {
    _obscureCurrent = !_obscureCurrent;
    notifyListeners();
  }

  void toggleObscureNew() {
    _obscureNew = !_obscureNew;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  void toggleTwoFactor() {
    _twoFactorEnabled = !_twoFactorEnabled;
    notifyListeners();
  }

  void _clearMessage() {
    if (_message == null) {
      notifyListeners();
      return;
    }
    _message = null;
    notifyListeners();
  }

  void _setMessage(String text, {required bool isError}) {
    _message = text;
    _messageIsError = isError;
  }

  /// Pesan galat pertama yang ditemukan, atau null bila form sudah benar.
  String? _validate() {
    if (_currentPassword.isEmpty) {
      return 'Isi kata sandi saat ini.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(_newPassword);
    final hasDigit = RegExp(r'\d').hasMatch(_newPassword);
    if (_newPassword.length < minPasswordLength || !hasLetter || !hasDigit) {
      return 'Kata sandi baru minimal $minPasswordLength karakter, kombinasi huruf dan angka.';
    }
    if (_newPassword == _currentPassword) {
      return 'Kata sandi baru harus berbeda dari yang lama.';
    }
    if (_confirmPassword != _newPassword) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  /// Mengembalikan true bila sandi berhasil diganti (layar lalu mengosongkan kolom isian).
  Future<bool> save() async {
    if (_isSaving) return false;

    final error = _validate();
    if (error != null) {
      _setMessage(error, isError: true);
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    var success = false;
    try {
      await _auth.changePassword(
        currentPassword: _currentPassword,
        newPassword: _newPassword,
      );
      _currentPassword = '';
      _newPassword = '';
      _confirmPassword = '';
      _setMessage('Kata sandi berhasil diperbarui.', isError: false);
      success = true;
    } on ApiException catch (e) {
      _setMessage(e.message, isError: true);
    } catch (_) {
      _setMessage('Gagal menyimpan kata sandi. Coba lagi.', isError: true);
    } finally {
      _isSaving = false;
    }
    notifyListeners();
    return success;
  }
}
