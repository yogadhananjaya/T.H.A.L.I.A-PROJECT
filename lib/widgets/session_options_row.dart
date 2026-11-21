import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_interaction.dart';

/// Baris opsi "Simpan sesi perangkat" (checkbox oranye terracotta) & "Reset Sandi?".
class SessionOptionsRow extends StatelessWidget {
  const SessionOptionsRow({
    super.key,
    required this.palette,
    required this.rememberSession,
    required this.onToggleRemember,
    required this.onTapResetPassword,
  });

  final ThaliaPalette palette;
  final bool rememberSession;
  final VoidCallback onToggleRemember;
  final VoidCallback onTapResetPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: TactilePressable(
            onTap: onToggleRemember,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: ThaliaColors.terracotta,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: rememberSession ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 10.5,
                      height: 10.5,
                      decoration: BoxDecoration(
                        color: ThaliaColors.terracotta,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Simpan sesi perangkat',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        TactilePressable(
          onTap: onTapResetPassword,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Reset Sandi?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ThaliaColors.tealAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
