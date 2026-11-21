import 'dart:typed_data';

/// Layar-layar di dalam dokumen LOGIN.figcraft & login_ui.figcraft.
enum AuthScreenStep {
  welcome('Selamat Datang'),
  login('Masuk Akun'),
  register('Daftar Akun Baru'),
  locationAccess('Izinkan Akses Lokasi'),
  dashboard('Dashboard'),
  settings('Pengaturan');

  const AuthScreenStep(this.title);
  final String title;
}

enum ThemeOption {
  light('Terang', 'Dipilih'),
  dark('Gelap', 'Mode malam');

  const ThemeOption(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// Base class OOP untuk state form autentikasi (Encapsulation & Polymorphism).
sealed class AuthFormModel {
  const AuthFormModel();

  bool get isValid;
}

/// Model OOP untuk halaman Masuk Akun (Login).
final class LoginCredentialsModel extends AuthFormModel {
  const LoginCredentialsModel({
    this.emailOrOfficerId = '',
    this.password = '',
    this.rememberDeviceSession = true,
    this.obscurePassword = true,
  });

  final String emailOrOfficerId;
  final String password;
  final bool rememberDeviceSession;
  final bool obscurePassword;

  @override
  bool get isValid =>
      emailOrOfficerId.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginCredentialsModel copyWith({
    String? emailOrOfficerId,
    String? password,
    bool? rememberDeviceSession,
    bool? obscurePassword,
  }) {
    return LoginCredentialsModel(
      emailOrOfficerId: emailOrOfficerId ?? this.emailOrOfficerId,
      password: password ?? this.password,
      rememberDeviceSession:
          rememberDeviceSession ?? this.rememberDeviceSession,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

/// Model OOP untuk halaman Daftar Akun Baru (Register).
final class RegisterFormModel extends AuthFormModel {
  const RegisterFormModel({
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.detectedLocation = 'Cikarang Utara, Bekasi',
    this.profileImageBytes,
    this.profileImageName,
    this.agreedToTerms = true,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String detectedLocation;
  final Uint8List? profileImageBytes;
  final String? profileImageName;
  final bool agreedToTerms;
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  bool get hasProfilePhoto => profileImageBytes != null;

  @override
  bool get isValid => agreedToTerms;

  RegisterFormModel copyWith({
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    String? detectedLocation,
    Uint8List? profileImageBytes,
    String? profileImageName,
    bool? agreedToTerms,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return RegisterFormModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      detectedLocation: detectedLocation ?? this.detectedLocation,
      profileImageBytes: profileImageBytes ?? this.profileImageBytes,
      profileImageName: profileImageName ?? this.profileImageName,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

/// Model OOP untuk halaman Izinkan Akses Lokasi (GPS & Maps).
final class GpsLocationModel {
  const GpsLocationModel({
    this.latitude = -6.2845,
    this.longitude = 107.1705,
    this.resolvedAddress = 'Cikarang Utara, Bekasi',
    this.accuracyLabel = 'Akurat',
    this.isGpsEnabled = false,
    this.isScanning = false,
    this.hasLocationPermission = false,
  });

  final double latitude;
  final double longitude;
  final String resolvedAddress;
  final String accuracyLabel;
  final bool isGpsEnabled;
  final bool isScanning;
  final bool hasLocationPermission;

  GpsLocationModel copyWith({
    double? latitude,
    double? longitude,
    String? resolvedAddress,
    String? accuracyLabel,
    bool? isGpsEnabled,
    bool? isScanning,
    bool? hasLocationPermission,
  }) {
    return GpsLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      resolvedAddress: resolvedAddress ?? this.resolvedAddress,
      accuracyLabel: accuracyLabel ?? this.accuracyLabel,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isScanning: isScanning ?? this.isScanning,
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
    );
  }
}
