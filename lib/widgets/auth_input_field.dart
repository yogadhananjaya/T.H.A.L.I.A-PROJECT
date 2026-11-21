import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_interaction.dart';

/// Komponen OOP Input Field yang konsisten di seluruh tab (Masuk Akun & Daftar Akun Baru).
class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.palette,
    this.hintText = '',
    this.initialValue = '',
    this.onChanged,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.showStatusDot = false,
    this.useCardSurface = true,
    this.keyboardType,
  });

  final String label;
  final ThaliaPalette palette;
  final String hintText;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final bool showStatusDot;
  final bool useCardSurface;
  final TextInputType? keyboardType;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final fillColor =
        widget.useCardSurface ? palette.card : palette.loginInputFill;
    final borderColor = _isFocused
        ? ThaliaColors.tealAccent
        : (widget.useCardSurface ? palette.cardBorder : palette.border);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: ThaliaColors.tealAccent.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  obscureText: widget.isPassword && widget.obscureText,
                  obscuringCharacter: '•',
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    letterSpacing:
                        (widget.isPassword && widget.obscureText) ? 2.0 : 0.0,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: palette.textSecondary.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              if (widget.showStatusDot)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _isFocused ? 10 : 8.5,
                  height: _isFocused ? 10 : 8.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ThaliaColors.tealAccent,
                    boxShadow: _isFocused
                        ? [
                            BoxShadow(
                              color: ThaliaColors.tealAccent.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ]
                        : const [],
                  ),
                ),
              if (widget.isPassword)
                TactilePressable(
                  onTap: widget.onToggleVisibility,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        widget.obscureText ? 'Lihat' : 'Tutup',
                        key: ValueKey<bool>(widget.obscureText),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ThaliaColors.tealAccent,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
