import 'package:flutter/material.dart';

/// Pembantu tata letak responsif & adaptif lintas ukuran layar (ponsel kecil, reguler, tablet, web).
abstract final class ThaliaResponsive {
  static const double compactBreakpoint = 360;
  static const double tabletBreakpoint = 600;
  static const double maxPhoneShellWidth = 480;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isTabletOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) return 16;
    if (width >= tabletBreakpoint) return 28;
    return 24;
  }

  /// Membungkus konten agar tetap proporsional dan terpusat di tablet maupun browser desktop.
  static Widget constrainShell({
    required Widget child,
    double maxWidth = maxPhoneShellWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
