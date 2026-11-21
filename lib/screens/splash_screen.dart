import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/figcraft_assets.dart';

/// Layar Splash Screen pembuka aplikasi mobile T.H.A.L.I.A.
///
/// Posisi logo dan tulisan diselaraskan dengan `ShieldViewfinderHero` di WelcomeScreen
/// agar transisi ke layar Selamat Datang terasa mulus:
/// 1. Tulisan "THALIA" muncul dengan transisi slide-down & fade-in.
/// 2. Logo perisai T.H.A.L.I.A muncul di atas tulisan dengan transisi slide-up & fade-in.
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

  late final Animation<Offset> _textSlideDown;
  late final Animation<double> _textFade;
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
    _textSlideDown = Tween<Offset>(
      begin: const Offset(0, -0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
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

    // Fase 1: Tulisan THALIA muncul dengan slide down
    _textController.forward();

    // Fase 2: Logo muncul di atas tulisan dengan slide up
    _logoDelayTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _logoController.forward();
    });

    // Fase 3: Transisi mulus ke Welcome / Dashboard
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo Perisai di posisi atas (selaras WelcomeScreen) dengan Slide Up
                SlideTransition(
                  position: _logoSlideUp,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Image.asset(
                      FigcraftAssets.shieldLogo,
                      width: 112,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // 2. Tulisan THALIA di posisi bawah (selaras WelcomeScreen) dengan Slide Down
                SlideTransition(
                  position: _textSlideDown,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'THALIA',
                          textAlign: TextAlign.center,
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
                          'TRI-HABITAT INTELLIGENCE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
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
