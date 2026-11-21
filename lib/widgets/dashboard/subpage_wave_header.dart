import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../tactile_interaction.dart';

/// Header Gelombang Sub-Halaman (Maps, Kamera, Riwayat, Profil, Kalender)
/// dengan tombol Profil di pojok kanan atas & opsi tombol Back di kiri atas.
class SubpageWaveHeader extends StatelessWidget {
  const SubpageWaveHeader({
    super.key,
    required this.climate,
    required this.eyebrowText,
    required this.titleText,
    required this.onTapProfile,
    this.onTapBack,
  });

  final ClimatePalette climate;
  final String eyebrowText;
  final String titleText;
  final VoidCallback onTapProfile;
  final VoidCallback? onTapBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 140,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  climate.subpageWaveAsset,
                  fit: BoxFit.fill,
                ),
              ),
              if (onTapBack != null)
                Positioned(
                  top: 44,
                  left: 20,
                  child: TactilePressable(
                    onTap: onTapBack,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: climate.primaryDark.withValues(alpha: 0.36),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 44,
                right: 20,
                child: TactilePressable(
                  onTap: onTapProfile,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: climate.primaryDark.withValues(alpha: 0.36),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 6, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.5),
                      border: Border.all(
                        color: climate.primaryBrand,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: climate.primaryBrand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eyebrowText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: climate.primaryBrand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                titleText,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: climate.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
