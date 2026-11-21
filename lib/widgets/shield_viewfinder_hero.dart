import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'figcraft_assets.dart';

/// Hero Logo THALIA dengan bingkai viewfinder [ ] (tanpa animasi idle, hanya animasi masuk).
class ShieldViewfinderHero extends StatelessWidget {
  const ShieldViewfinderHero({
    super.key,
    required this.palette,
  });

  final ThaliaPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      height: 310,
      child: CustomPaint(
        painter: _ViewfinderCornerPainter(color: palette.border),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              FigcraftAssets.shieldLogo,
              width: 112,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 22),
            Text(
              'THALIA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.5,
                color: palette.isDark
                    ? palette.textPrimary
                    : ThaliaColors.navyDeep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tri-Habitat Analysis',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderCornerPainter extends CustomPainter {
  const _ViewfinderCornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const len = 18.0;
    const pad = 6.0;

    // Top-left
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad, pad + len), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad - len, pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(size.width - pad, pad + len),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad + len, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(pad, size.height - pad - len),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad - len, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, size.height - pad),
      Offset(size.width - pad, size.height - pad - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
