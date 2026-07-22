import 'package:flutter/material.dart';

/// The brand "signature" edge fade: a soft gradient that melts scrolling page
/// content into the background colour at the very top and bottom of the screen.
///
/// These are decorative, childless overlays designed to be dropped directly into
/// a [Stack] *beneath* the chrome (floating headers, search bars, bottom nav
/// bars) so the content fades out behind them while the chrome stays crisp.
/// Each returns a [Positioned] and ignores pointer events.
class TopEdgeFade extends StatelessWidget {
  const TopEdgeFade({super.key, this.height, this.color});

  /// Height of the fade band. Defaults to the status-bar inset plus a
  /// comfortable band so it reads on notched devices.
  final double? height;

  /// Colour the content fades into. Defaults to the scaffold background so it
  /// blends seamlessly in light and dark themes.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.scaffoldBackgroundColor;
    final h = height ?? (MediaQuery.of(context).padding.top + 64);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: h,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c,
                c.withValues(alpha: 0.92),
                c.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomEdgeFade extends StatelessWidget {
  const BottomEdgeFade({super.key, this.height, this.color});

  /// Height of the fade band. Defaults to the system-nav inset plus a band
  /// large enough to sit behind a floating bottom bar.
  final double? height;

  /// Colour the content fades into. Defaults to the scaffold background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.scaffoldBackgroundColor;
    final h = height ?? (MediaQuery.of(context).padding.bottom + 96);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: h,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.withValues(alpha: 0.0),
                c.withValues(alpha: 0.88),
                c,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
