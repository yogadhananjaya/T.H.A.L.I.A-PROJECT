import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper OOP untuk efek tekan taktil (scale 0.97x + spring return + haptic).
class TactilePressable extends StatefulWidget {
  const TactilePressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<TactilePressable> createState() => _TactilePressableState();
}

class _TactilePressableState extends State<TactilePressable> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (_pressed) setState(() => _pressed = false);
  }

  void _onTapCancel() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _pressed ? 100 : 320),
        curve: _pressed ? Curves.easeOutCubic : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Wrapper OOP untuk animasi masuk bertahap (staggered slide-up + fade-in).
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 18.0,
  });

  final Widget child;
  final int delayMs;
  final double offsetY;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final int _totalMs = 520 + widget.delayMs;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.delayMs <= 0 ? 0.0 : (widget.delayMs / _totalMs);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1.0 - v)),
            child: child,
          ),
        );
      },
    );
  }
}
