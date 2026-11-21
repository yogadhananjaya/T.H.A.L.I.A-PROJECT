import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'figcraft_assets.dart';

/// Hero Logo THALIA dengan bingkai viewfinder [ ] & animasi melayang halus
/// sesuai layar pertama "Selamat Datang" pada LOGIN.figcraft.
class ShieldViewfinderHero extends StatefulWidget {
  const ShieldViewfinderHero({
    super.key,
    required this.palette,
  });

  final ThaliaPalette palette;

  @override
  State<ShieldViewfinderHero> createState() => _ShieldViewfinderHeroState();
}

class _ShieldViewfinderHeroState extends State<ShieldViewfinderHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final t = _floatController.value;
        final dy = math.sin(t * math.pi) * 5.0;
        return SizedBox(
          width: 248,
          height: 310,
          child: CustomPaint(
            painter: _ViewfinderCornerPainter(
              color: palette.border,
              expansion: t * 3.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -dy),
                  child: Image.asset(
                    FigcraftAssets.shieldLogo,
                    width: 112,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
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
      },
    );
  }
}

class _ViewfinderCornerPainter extends CustomPainter {
  const _ViewfinderCornerPainter({
    required this.color,
    required this.expansion,
  });

  final Color color;
  final double expansion;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const len = 18.0;
    final pad = 6.0 - expansion;

    // Top-left
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + len), paint);

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
      oldDelegate.expansion != expansion || oldDelegate.color != color;
}
