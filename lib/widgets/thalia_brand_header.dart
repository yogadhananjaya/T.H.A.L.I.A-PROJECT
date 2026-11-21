import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Komponen Brand Badge [•] T.H.A.L.I.A + Judul "Masuk Akun" sesuai LOGIN.figcraft.
class ThaliaBrandHeader extends StatefulWidget {
  const ThaliaBrandHeader({
    super.key,
    required this.palette,
    this.title = 'Masuk Akun',
    this.subtitle = 'Portal Petugas Mitigasi & Relawan Lapangan',
  });

  final ThaliaPalette palette;
  final String title;
  final String subtitle;

  @override
  State<ThaliaBrandHeader> createState() => _ThaliaBrandHeaderState();
}

class _ThaliaBrandHeaderState extends State<ThaliaBrandHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final scale = 0.92 + (_pulseController.value * 0.16);
                return Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.5),
                    border: Border.all(
                      color: ThaliaColors.tealAccent,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThaliaColors.terracotta,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'T . H . A . L . I . A',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tri-Habitat Climate Intelligence',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ThaliaColors.tealAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: palette.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
