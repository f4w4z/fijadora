import 'package:flutter/material.dart';

class FloatingHeaderLayout extends StatefulWidget {
  const FloatingHeaderLayout({
    super.key,
    required this.header,
    required this.bodyBuilder,
  });

  final Widget header;
  final Widget Function(BuildContext context, double topPadding) bodyBuilder;

  @override
  State<FloatingHeaderLayout> createState() => _FloatingHeaderLayoutState();
}

class _FloatingHeaderLayoutState extends State<FloatingHeaderLayout> {
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 130.0; // Sensible default estimate

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  void _measureHeader() {
    if (!mounted) return;
    final context = _headerKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final height = renderBox.size.height;
        if (height != _headerHeight && height > 0) {
          setState(() {
            _headerHeight = height;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Remeasure if state changes or builds trigger updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Scrollable content
        widget.bodyBuilder(context, _headerHeight),

        // 2. Top scrim (gradient background)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _headerHeight + 32.0, // bleed fade below header
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

        // 3. Floating header
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: KeyedSubtree(
            key: _headerKey,
            child: widget.header,
          ),
        ),
      ],
    );
  }
}
