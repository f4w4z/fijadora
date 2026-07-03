import 'package:flutter/material.dart';

class FloatingHeaderLayout extends StatelessWidget {
  const FloatingHeaderLayout({
    super.key,
    required this.header,
    required this.bodyBuilder,
    this.headerHeight = 140.0,
  });

  final Widget header;
  final Widget Function(BuildContext context, double topPadding) bodyBuilder;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        bodyBuilder(context, headerHeight),
        Positioned(
          left: 0, right: 0, top: 0,
          height: headerHeight + 32.0,
          child: _TopScrim(color: theme.scaffoldBackgroundColor),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: headerHeight / 2,
          child: _BottomScrim(color: theme.scaffoldBackgroundColor),
        ),
        Positioned(
          left: 0, right: 0, top: 0,
          child: header,
        ),
      ],
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color,
              color.withValues(alpha: 0.90),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BottomScrim extends StatelessWidget {
  const _BottomScrim({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.85),
              color,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
