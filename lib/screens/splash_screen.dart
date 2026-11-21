import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/figcraft_assets.dart';

/// Layar Splash Screen pembuka aplikasi mobile T.H.A.L.I.A.
///
/// Urutan animasi:
/// 1. Menampilkan teks "T.H.A.L.I.A" dengan fade-in halus.
/// 2. Memunculkan logo perisai T.H.A.L.I.A dengan transisi slide-up & fade-in.
/// 3. Berpindah otomatis ke alur utama aplikasi setelah animasi selesai.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _textController;
  late final AnimationController _logoController;

  late final Animation<double> _textFade;
  late final Animation<double> _textScale;
  late final Animation<Offset> _logoSlideUp;
  late final Animation<double> _logoFade;

  Timer? _logoDelayTimer;
  Timer? _finishTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoSlideUp = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Jalankan fase 1: tampilkan tulisan T.H.A.L.I.A
    _textController.forward();

    // Fase 2: setelah tulisan tampil, munculkan logo dengan transisi slide up
    _logoDelayTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _logoController.forward();
    });

    // Fase 3: lanjut ke halaman utama setelah animasi selesai
    _finishTimer = Timer(const Duration(milliseconds: 2200), _completeSplash);
  }

  void _completeSplash() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    _logoDelayTimer?.cancel();
    _finishTimer?.cancel();
    _textController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = ThaliaPalette(isDark: isDark);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Tulisan T.H.A.L.I.A muncul terlebih dahulu
                FadeTransition(
                  opacity: _textFade,
                  child: ScaleTransition(
                    scale: _textScale,
                    child: Column(
                      children: [
                        Text(
                          'T.H.A.L.I.A',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5.0,
                            color: palette.isDark
                                ? palette.textPrimary
                                : ThaliaColors.navyDeep,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tri-Habitat Climate Intelligence',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // 2. Logo T.H.A.L.I.A muncul dengan transisi slide up
                SlideTransition(
                  position: _logoSlideUp,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Image.asset(
                      FigcraftAssets.shieldLogo,
                      width: 118,
                      height: 158,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
