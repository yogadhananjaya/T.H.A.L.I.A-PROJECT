import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tactile_interaction.dart';

/// Tombol utama gelap (#1D2F2B) di LOGIN.figcraft dengan animasi tekan & loading.
class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    super.key,
    required this.label,
    required this.palette,
    required this.onTap,
    this.showArrow = false,
    this.isLoading = false,
  });

  final String label;
  final ThaliaPalette palette;
  final VoidCallback onTap;
  final bool showArrow;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: palette.primaryButtonBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: palette.primaryButtonBg.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: palette.primaryButtonFg,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.primaryButtonFg,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                      color: palette.primaryButtonFg,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Tombol sekunder mint (#E3ECE8) dengan border teal (#3B7A72) sesuai LOGIN.figcraft.
class SecondaryAuthButton extends StatelessWidget {
  const SecondaryAuthButton({
    super.key,
    required this.label,
    required this.palette,
    required this.onTap,
    this.leadingDot = false,
  });

  final String label;
  final ThaliaPalette palette;
  final VoidCallback onTap;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: palette.secondaryButtonBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: ThaliaColors.tealAccent,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingDot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThaliaColors.emeraldPrimary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: palette.secondaryButtonFg,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
