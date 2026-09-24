import 'package:flutter/material.dart';

import '../../core/theme/blue_theme.dart';


/// Premium page background shared by all screens: a soft blue vertical
/// gradient with two faint radial glows. Works in light and dark mode.
///
/// Usage is unchanged: `AppPageShell(child: ...)`.
/// Set [showGlow] to false for a plain gradient (e.g. on very low-end devices).
class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.child,
    this.showGlow = false,
  });

  final Widget child;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.scaffoldBackgroundColor;

    // Passthrough keeps the parent's constraints intact, so the child lays out
    // exactly as it did inside the old DecoratedBox.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: _ShellBackground(
                base: base,
                isDark: isDark,
                showGlow: showGlow,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ShellBackground extends StatelessWidget {
  const _ShellBackground({
    required this.base,
    required this.isDark,
    required this.showGlow,
  });

  final Color base;
  final bool isDark;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    // Scale glows with the screen but cap them so desktop stays elegant.
    final glow = (shortest * 0.9).clamp(240.0, 520.0);

    final top = isDark ? const Color(0xFF12234A) : const Color(0xFFE6F0FF);
    final mid = isDark ? const Color(0xFF0E1A33) : const Color(0xFFF3F8FF);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base vertical gradient that melts into the scaffold color.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.32, 1],
              colors: [top, mid, base],
            ),
          ),
        ),
        if (showGlow) ...[
          // Sky glow, top right.
          Positioned(
            top: -glow * 0.45,
            right: -glow * 0.35,
            child: _GlowBlob(
              diameter: glow,
              color: BlueColors.sky,
              alpha: isDark ? 0.16 : 0.30,
            ),
          ),
          // Light-blue glow, upper left.
          Positioned(
            top: glow * 0.25,
            left: -glow * 0.55,
            child: _GlowBlob(
              diameter: glow * 0.8,
              color: BlueColors.light,
              alpha: isDark ? 0.14 : 0.20,
            ),
          ),
        ],
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.diameter,
    required this.color,
    required this.alpha,
  });

  final double diameter;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}