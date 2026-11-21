import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header Gelombang Tri-Habitat di halaman Masuk Akun (menempel langsung di puncak layar y = 0)
/// menggunakan koordinat vektor presisi dari node 1032 LOGIN.figcraft.
class LoginWaveBanner extends StatefulWidget {
  const LoginWaveBanner({super.key});

  @override
  State<LoginWaveBanner> createState() => _LoginWaveBannerState();
}

class _LoginWaveBannerState extends State<LoginWaveBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AspectRatio(
          aspectRatio: 390 / 168,
          child: CustomPaint(
            size: Size.infinite,
            painter: _FigcraftWaveHeaderPainter(
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _FigcraftWaveHeaderPainter extends CustomPainter {
  const _FigcraftWaveHeaderPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390.0;
    final sy = size.height / 168.0;
    final gentleShift = math.sin(progress * math.pi) * 2.5 * sy;

    // 1. Lapisan Gelombang Hidrosfer (#A7D8EE) - Path node 1036 dari LOGIN.figcraft
    final skyPath = Path()
      ..moveTo(0, 0)
      ..lineTo(390 * sx, 0)
      ..lineTo(390 * sx, 144 * sy + gentleShift)
      ..cubicTo(
        296 * sx,
        178 * sy + gentleShift,
        196 * sx,
        112 * sy - gentleShift,
        104 * sx,
        148 * sy + gentleShift,
      )
      ..cubicTo(
        54 * sx,
        166 * sy + gentleShift,
        20 * sx,
        150 * sy,
        0,
        138 * sy,
      )
      ..close();
    canvas.drawPath(
      skyPath,
      Paint()
        ..color = ThaliaColors.skySoft
        ..style = PaintingStyle.fill,
    );

    // 2. Lapisan Gelombang Litosfer (#4EB26D) - Path node 1040 dari LOGIN.figcraft
    final greenPath = Path()
      ..moveTo(0, 0)
      ..lineTo(390 * sx, 0)
      ..lineTo(390 * sx, 116 * sy - gentleShift * 0.6)
      ..cubicTo(
        296 * sx,
        150 * sy + gentleShift * 0.6,
        202 * sx,
        88 * sy - gentleShift * 0.6,
        112 * sx,
        124 * sy + gentleShift * 0.6,
      )
      ..cubicTo(
        60 * sx,
        144 * sy + gentleShift * 0.6,
        22 * sx,
        126 * sy,
        0,
        116 * sy,
      )
      ..close();
    canvas.drawPath(
      greenPath,
      Paint()
        ..color = ThaliaColors.emeraldPrimary
        ..style = PaintingStyle.fill,
    );

    // 3. Lapisan Gelombang Atmosfer Navy (#1C3549) - Path node 1044 dari LOGIN.figcraft
    final navyPath = Path()
      ..moveTo(0, 0)
      ..lineTo(228 * sx, 0)
      ..cubicTo(
        186 * sx,
        88 * sy,
        92 * sx,
        122 * sy,
        0,
        102 * sy,
      )
      ..close();
    canvas.drawPath(
      navyPath,
      Paint()
        ..color = ThaliaColors.navyDeep
        ..style = PaintingStyle.fill,
    );

    // 4. Garis Putus-Putus Lintasan (#4EB26D) - Path node 1049 dari LOGIN.figcraft
    final dashedCurve = Path()
      ..moveTo(16 * sx, 154 * sy)
      ..cubicTo(
        104 * sx,
        126 * sy,
        192 * sx,
        166 * sy,
        290 * sx,
        150 * sy,
      )
      ..cubicTo(
        330 * sx,
        143 * sy,
        360 * sx,
        132 * sy,
        380 * sx,
        122 * sy,
      );

    final dashPaint = Paint()
      ..color = ThaliaColors.emeraldPrimary
      ..strokeWidth = 1.6 * sx
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in dashedCurve.computeMetrics()) {
      var distance = 0.0;
      final dashLen = 5.0 * sx;
      final gapLen = 4.0 * sx;
      while (distance < metric.length) {
        final next = math.min(distance + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), dashPaint);
        distance += dashLen + gapLen;
      }
    }

    // 5. Titik Biru Orbit (#6AC0E6) - Node 1054 pada (327, 159)
    final dotCenter = Offset(327 * sx, 159 * sy + gentleShift * 0.5);
    canvas.drawCircle(
      dotCenter,
      (7.0 + progress * 2.5) * sx,
      Paint()
        ..color = const Color(0xFF6AC0E6).withValues(
          alpha: 0.22 * (1.0 - progress),
        ),
    );
    canvas.drawCircle(
      dotCenter,
      7.0 * sx,
      Paint()..color = const Color(0xFF6AC0E6),
    );
  }

  @override
  bool shouldRepaint(covariant _FigcraftWaveHeaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
