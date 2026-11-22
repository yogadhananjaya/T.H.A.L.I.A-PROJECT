import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../tactile_interaction.dart';

/// Header Gelombang Sub-Halaman (Maps, Kamera, Riwayat, Profil, Kalender)
/// dilengkapi animasi idle gelombang & titik orbit biru khusus pada bagian header atas (Screenshot 3).
class SubpageWaveHeader extends StatefulWidget {
  const SubpageWaveHeader({
    super.key,
    required this.climate,
    required this.eyebrowText,
    required this.titleText,
    this.onTapProfile,
    this.onTapBack,
  });

  final ClimatePalette climate;
  final String eyebrowText;
  final String titleText;
  /// Null menyembunyikan tombol profil di kanan atas (dipakai layar Keamanan & Cari Lokasi).
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapBack;

  @override
  State<SubpageWaveHeader> createState() => _SubpageWaveHeaderState();
}

class _SubpageWaveHeaderState extends State<SubpageWaveHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleWaveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _idleWaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final climate = widget.climate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 140,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _idleWaveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AnimatedSubpageWavePainter(
                        climate: climate,
                        progress: _idleWaveController.value,
                      ),
                    );
                  },
                ),
              ),
              if (widget.onTapBack != null)
                Positioned(
                  top: 44,
                  left: 20,
                  child: TactilePressable(
                    onTap: widget.onTapBack,
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
              if (widget.onTapProfile != null)
              Positioned(
                top: 44,
                right: 20,
                child: TactilePressable(
                  onTap: widget.onTapProfile,
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
                      widget.eyebrowText,
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
                widget.titleText,
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

/// Painter vektor presisi node 1260 dari login_ui.figcraft dengan animasi idle gelombang halus.
class _AnimatedSubpageWavePainter extends CustomPainter {
  const _AnimatedSubpageWavePainter({
    required this.climate,
    required this.progress,
  });

  final ClimatePalette climate;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390.0;
    final sy = size.height / 140.0;
    final waveShift = math.sin(progress * math.pi) * 4.5 * sy;

    final t = climate.orangeBlend.clamp(0.0, 1.0);
    final baseMistColor = Color.lerp(
      const Color(0xFFA9D2EE),
      const Color(0xFFFBE3C8),
      t,
    )!;
    final midRibbonColor = Color.lerp(
      const Color(0xFF245E96),
      const Color(0xFFDF4E26),
      t,
    )!;
    final topDeepColor = Color.lerp(
      const Color(0xFF142D4B),
      const Color(0xFF8F2216),
      t,
    )!;
    final orbColor = Color.lerp(
      const Color(0xFF64AEE0),
      const Color(0xFFF4A938),
      t,
    )!;

    // 1. Wave Base Mist (#A9D2EE)
    final mistPath = Path()
      ..moveTo(0, 0)
      ..lineTo(390 * sx, 0)
      ..lineTo(390 * sx, 104 * sy + waveShift * 0.6)
      ..cubicTo(
        304 * sx,
        134 * sy + waveShift,
        202 * sx,
        78 * sy - waveShift,
        114 * sx,
        110 * sy + waveShift * 0.8,
      )
      ..cubicTo(
        60 * sx,
        128 * sy + waveShift * 0.5,
        22 * sx,
        114 * sy,
        0,
        104 * sy,
      )
      ..close();
    canvas.drawPath(mistPath, Paint()..color = baseMistColor);

    // 2. Wave Mid Ribbon (#245E96)
    final midPath = Path()
      ..moveTo(0, 0)
      ..lineTo(390 * sx, 0)
      ..lineTo(390 * sx, 80 * sy - waveShift * 0.5)
      ..cubicTo(
        304 * sx,
        110 * sy - waveShift * 0.8,
        210 * sx,
        62 * sy + waveShift * 0.8,
        124 * sx,
        94 * sy - waveShift * 0.6,
      )
      ..cubicTo(
        68 * sx,
        114 * sy - waveShift * 0.4,
        26 * sx,
        98 * sy,
        0,
        88 * sy,
      )
      ..close();
    canvas.drawPath(midPath, Paint()..color = midRibbonColor);

    // 3. Wave Top Deep (#142D4B)
    final deepPath = Path()
      ..moveTo(0, 0)
      ..lineTo(214 * sx, 0)
      ..cubicTo(
        178 * sx,
        68 * sy + waveShift * 0.4,
        88 * sx,
        94 * sy - waveShift * 0.3,
        0,
        80 * sy,
      )
      ..close();
    canvas.drawPath(deepPath, Paint()..color = topDeepColor);

    // 4. Wave Hairline Dashed Contour (#245E96)
    final dashedCurve = Path()
      ..moveTo(16 * sx, 116 * sy)
      ..cubicTo(
        104 * sx,
        90 * sy - waveShift * 0.7,
        192 * sx,
        124 * sy + waveShift * 0.7,
        290 * sx,
        112 * sy - waveShift * 0.4,
      )
      ..cubicTo(
        330 * sx,
        107 * sy,
        360 * sx,
        98 * sy,
        380 * sx,
        90 * sy,
      );

    final dashPaint = Paint()
      ..color = midRibbonColor
      ..strokeWidth = 1.4 * sx
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in dashedCurve.computeMetrics()) {
      var d = 0.0;
      final dashLen = 5.1 * sx;
      final gapLen = 4.1 * sx;
      while (d < metric.length) {
        final next = math.min(d + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(d, next), dashPaint);
        d += dashLen + gapLen;
      }
    }

    // 5. Wave Accent Orb (#64AEE0) dengan animasi denyut halus
    final orbCenter = Offset(332 * sx, 118 * sy + waveShift * 0.45);
    canvas.drawCircle(
      orbCenter,
      (6.0 + progress * 3.0) * sx,
      Paint()..color = orbColor.withValues(alpha: 0.24 * (1.0 - progress)),
    );
    canvas.drawCircle(
      orbCenter,
      6.0 * sx,
      Paint()..color = orbColor,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedSubpageWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.climate != climate;
}
