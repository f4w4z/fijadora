import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../domain/models/product.dart';
import '../product_detail_view.dart';

class ShopTheLookCarousel extends ConsumerStatefulWidget {
  final List<Product> bundles;
  const ShopTheLookCarousel({super.key, required this.bundles});

  @override
  ConsumerState<ShopTheLookCarousel> createState() => _ShopTheLookCarouselState();
}

class _ShopTheLookCarouselState extends ConsumerState<ShopTheLookCarousel> {
  late Map<int, int> _positions;
  late int _cardCount;

  @override
  void initState() {
    super.initState();
    _cardCount = widget.bundles.length;
    _positions = {for (int i = 0; i < _cardCount; i++) i: i};
  }

  @override
  void didUpdateWidget(ShopTheLookCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bundles.length != oldWidget.bundles.length) {
      setState(() {
        _cardCount = widget.bundles.length;
        _positions = {for (int i = 0; i < _cardCount; i++) i: i};
      });
    }
  }

  void _bringToFront(int index) {
    final currentPos = _positions[index]!;
    if (currentPos == 0) return; // Already front

    setState(() {
      final shift = currentPos;
      for (int i = 0; i < _cardCount; i++) {
        final p = _positions[i]!;
        _positions[i] = (p - shift + _cardCount) % _cardCount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cardCount == 0) return const SizedBox.shrink();

    // Sort bundle card indices so that back-most card is built first, front-most is built last.
    final sortedIndices = List<int>.generate(_cardCount, (i) => i)
      ..sort((a, b) {
        final posA = _positions[a]!;
        final posB = _positions[b]!;
        return posB.compareTo(posA); // Descending order
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;

        return Container(
          height: 370,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: sortedIndices.map((idx) {
              final bundle = widget.bundles[idx];
              final position = _positions[idx]!;

              // Calculate card properties based on position
              double leftOffset = 0;
              double topOffset = 0;
              double scale = 1.0;
              double rotation = 0.0;
              double opacity = 1.0;
              bool isInteractive = true;

              if (_cardCount == 1) {
                leftOffset = 0.0;
                topOffset = 0.0;
                scale = 1.0;
                rotation = 0.0;
                opacity = 1.0;
                isInteractive = true;
              } else if (_cardCount == 2) {
                if (position == 0) {
                  leftOffset = 25.0;
                  topOffset = 0.0;
                  scale = 1.0;
                  rotation = 0.0;
                  opacity = 1.0;
                  isInteractive = true;
                } else {
                  leftOffset = -25.0;
                  topOffset = 12.0;
                  scale = 0.92;
                  rotation = -0.08;
                  opacity = 1.0;
                  isInteractive = true;
                }
              } else {
                // 3 or more cards
                if (position == 0) {
                  leftOffset = 40.0;
                  topOffset = 0.0;
                  scale = 1.0;
                  rotation = 0.0;
                  opacity = 1.0;
                  isInteractive = true;
                } else if (position == 1) {
                  leftOffset = 0.0;
                  topOffset = 12.0;
                  scale = 0.94;
                  rotation = -0.06;
                  opacity = 1.0;
                  isInteractive = true;
                } else if (position == 2) {
                  leftOffset = -40.0;
                  topOffset = 24.0;
                  scale = 0.88;
                  rotation = -0.12;
                  opacity = 1.0;
                  isInteractive = true;
                } else {
                  // Hidden card
                  leftOffset = -40.0;
                  topOffset = 24.0;
                  scale = 0.0;
                  rotation = -0.12;
                  opacity = 0.0;
                  isInteractive = false;
                }
              }

              return AnimatedPositioned(
                key: ValueKey(bundle.id),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: (parentWidth - 310) / 2 + leftOffset,
                top: topOffset,
                child: IgnorePointer(
                  ignoring: !isInteractive,
                  child: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedScale(
                      scale: scale,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      child: AnimatedRotation(
                        turns: rotation / (2 * 3.14159),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        child: GestureDetector(
                          onTap: () => _bringToFront(idx),
                          behavior: HitTestBehavior.opaque,
                          child: _buildCard(bundle),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(Product bundle) {
    return Container(
      width: 310,
      height: 310,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: bundle.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade900,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade900,
                child: const Icon(CupertinoIcons.photo, size: 48, color: Colors.white24),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    bundle.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.instrumentSerif(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    "\$${bundle.price.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailView(
                            product: bundle,
                            heroTag: 'bundle-img-${bundle.id}',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: Text(
                        'Explore',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
