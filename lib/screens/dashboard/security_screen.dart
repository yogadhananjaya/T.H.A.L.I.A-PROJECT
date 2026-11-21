import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/security_controller.dart';
import '../../models/dashboard_models.dart';
import '../../widgets/dashboard/subpage_wave_header.dart';
import '../../widgets/tactile_interaction.dart';

/// Layar 24 (Hujan) dan 25 (Panas) pada login_ui.figcraft: "Keamanan & Kata Sandi".
/// Warna mengikuti [ClimatePalette] sehingga satu kelas ini melayani kedua versi.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({
    super.key,
    required this.dashboardController,
    required this.authController,
  });

  final DashboardController dashboardController;
  final AuthController authController;

  /// Membuka layar ini di atas dashboard (tanpa navbar bawah, sesuai desain).
  static Future<void> open(
    BuildContext context, {
    required DashboardController dashboardController,
    required AuthController authController,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SecurityScreen(
          dashboardController: dashboardController,
          authController: authController,
        ),
      ),
    );
  }

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  late final SecurityController _security =
      SecurityController(auth: widget.authController);

  final TextEditingController _currentField = TextEditingController();
  final TextEditingController _newField = TextEditingController();
  final TextEditingController _confirmField = TextEditingController();

  @override
  void dispose() {
    _currentField.dispose();
    _newField.dispose();
    _confirmField.dispose();
    _security.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    final ok = await _security.save();
    if (ok && mounted) {
      _currentField.clear();
      _newField.clear();
      _confirmField.clear();
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Atur ulang sandi lewat email belum tersedia di versi ini.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.dashboardController,
        widget.authController,
        _security,
      ]),
      builder: (context, _) {
        final climate = ClimatePalette(
          season: widget.dashboardController.seasonMode,
          isDark: widget.authController.isDarkMode,
        );
        final reg = widget.authController.registerModel;
        final email =
            reg.email.trim().isNotEmpty ? reg.email : 'raka.pratama@thalia.id';
        final strength = _security.strength;

        return Scaffold(
          backgroundColor: climate.canvas,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubpageWaveHeader(
                  climate: climate,
                  eyebrowText: 'Perlindungan Akun THALIA',
                  titleText: 'Keamanan & Sandi',
                  onTapBack: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountStrip(
                        climate: climate,
                        email: email,
                        changedLabel: widget.authController.passwordChangedLabel,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          'UBAH KATA SANDI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: climate.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        decoration: BoxDecoration(
                          color: climate.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: climate.border, width: 1.3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(
                              text: 'Kata Sandi Saat Ini',
                              climate: climate,
                            ),
                            const SizedBox(height: 7),
                            _PasswordField(
                              controller: _currentField,
                              climate: climate,
                              obscure: _security.obscureCurrent,
                              onChanged: _security.updateCurrent,
                              onToggleObscure: _security.toggleObscureCurrent,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _FieldLabel(
                              text: 'Kata Sandi Baru',
                              climate: climate,
                            ),
                            const SizedBox(height: 7),
                            _PasswordField(
                              controller: _newField,
                              climate: climate,
                              obscure: _security.obscureNew,
                              onChanged: _security.updateNew,
                              onToggleObscure: _security.toggleObscureNew,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            _StrengthMeter(climate: climate, strength: strength),
                            const SizedBox(height: 6),
                            Text(
                              'Min. ${SecurityController.minPasswordLength} karakter, kombinasi huruf & angka',
                              style: TextStyle(
                                fontSize: 12,
                                color: climate.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _FieldLabel(
                              text: 'Konfirmasi Kata Sandi Baru',
                              climate: climate,
                            ),
                            const SizedBox(height: 7),
                            _PasswordField(
                              controller: _confirmField,
                              climate: climate,
                              obscure: _security.obscureConfirm,
                              onChanged: _security.updateConfirm,
                              onToggleObscure: _security.toggleObscureConfirm,
                              showMatchCheck: _security.confirmMatches,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onSave(),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TactilePressable(
                                onTap: _onForgotPassword,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'Lupa kata sandi saat ini?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: climate.primaryBrand,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TwoFactorRow(
                        climate: climate,
                        enabled: _security.twoFactorEnabled,
                        onToggle: _security.toggleTwoFactor,
                      ),
                      if (_security.message != null) ...[
                        const SizedBox(height: 14),
                        _MessageBanner(
                          text: _security.message!,
                          isError: _security.messageIsError,
                        ),
                      ],
                      const SizedBox(height: 14),
                      TactilePressable(
                        onTap: _security.isSaving ? null : _onSave,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: climate.primaryBrand,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: _security.isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan Kata Sandi',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({
    required this.climate,
    required this.email,
    required this.changedLabel,
  });

  final ClimatePalette climate;
  final String email;
  final String changedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: climate.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: climate.border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: climate.surfaceWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: climate.primaryBrand,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: climate.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  changedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: climate.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.climate});

  final String text;
  final ClimatePalette climate;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: climate.primaryDark,
      ),
    );
  }
}

/// Kolom sandi: ikon gembok, tombol mata, dan (opsional) centang bila konfirmasi cocok.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.climate,
    required this.obscure,
    required this.onChanged,
    required this.onToggleObscure,
    this.showMatchCheck = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final ClimatePalette climate;
  final bool obscure;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleObscure;
  final bool showMatchCheck;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    final focused = _focus.hasFocus;
    final accent = focused ? climate.primaryBrand : climate.textSecondary;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: focused ? climate.surfaceWhite : climate.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? climate.primaryBrand : climate.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              enableSuggestions: false,
              autocorrect: false,
              cursorColor: climate.primaryBrand,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: climate.primaryDark,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (widget.showMatchCheck)
            Icon(Icons.check_rounded, size: 20, color: climate.primaryBrand)
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggleObscure,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  widget.obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.climate, required this.strength});

  final ClimatePalette climate;
  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              decoration: BoxDecoration(
                color: i < strength.filledSegments
                    ? climate.primaryBrand
                    : climate.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          width: 48,
          child: Text(
            strength.label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: climate.primaryBrand,
            ),
          ),
        ),
      ],
    );
  }
}

class _TwoFactorRow extends StatelessWidget {
  const _TwoFactorRow({
    required this.climate,
    required this.enabled,
    required this.onToggle,
  });

  final ClimatePalette climate;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: climate.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: climate.border, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi 2 Langkah (2FA)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: climate.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kode OTP ke +62 812-****-7890',
                  style: TextStyle(
                    fontSize: 12,
                    color: climate.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: enabled ? climate.primaryBrand : climate.border,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final base = isError ? const Color(0xFFD93025) : const Color(0xFF1E8E3E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: base,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: base,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
