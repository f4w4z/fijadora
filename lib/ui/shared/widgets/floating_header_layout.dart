import 'package:flutter/material.dart';

class FloatingHeaderLayout extends StatelessWidget {
  const FloatingHeaderLayout({
    super.key,
    required this.header,
    required this.bodyBuilder,
  });

  final Widget header;
  final Widget Function(BuildContext context, double topPadding) bodyBuilder;

  // Estimated header height (SafeArea + padding + title row + optional bottom child)
  static const double headerHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scrollable content
        bodyBuilder(context, headerHeight),

        // 2. Top scrim (gradient background)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: headerHeight + 32.0,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.90),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Bottom scrim (gradient fade)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: headerHeight / 2,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 4. Floating header
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: header,
        ),
      ],
    );
  }
}
