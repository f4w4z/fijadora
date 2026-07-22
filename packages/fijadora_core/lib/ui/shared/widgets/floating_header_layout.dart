import 'package:flutter/material.dart';
import 'signature_edge_fade.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        bodyBuilder(context, headerHeight),
        const TopEdgeFade(),
        Positioned(
          left: 0, right: 0, top: 0,
          child: header,
        ),
      ],
    );
  }
}
