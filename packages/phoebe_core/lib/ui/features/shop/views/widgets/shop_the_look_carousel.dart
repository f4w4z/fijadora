import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../domain/models/collection.dart';
import '../../../collections/views/collection_detail_view.dart';
import '../../../../core/utilities/responsive_helpers.dart';

class ShopTheLookCarousel extends ConsumerStatefulWidget {
  final List<Collection> collections;
  const ShopTheLookCarousel({super.key, required this.collections});

  @override
  ConsumerState<ShopTheLookCarousel> createState() => _ShopTheLookCarouselState();
}

class _ShopTheLookCarouselState extends ConsumerState<ShopTheLookCarousel> {
  late Map<int, int> _positions;
  late int _cardCount;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cardCount = widget.collections.length;
    _positions = {for (int i = 0; i < _cardCount; i++) i: i};
    _startAutoFlip();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShopTheLookCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collections.length != oldWidget.collections.length) {
      setState(() {
        _cardCount = widget.collections.length;
        _positions = {for (int i = 0; i < _cardCount; i++) i: i};
      });
      _timer?.cancel();
      _startAutoFlip();
    }
  }

  void _startAutoFlip() {
    if (_cardCount < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final frontIdx = _positions.entries.firstWhere((e) => e.value == 0).key;
      _bringToFront(frontIdx);
    });
  }

  void _bringToFront(int index) {
    _timer?.cancel();
    _startAutoFlip();

    final currentPos = _positions[index]!;
    if (currentPos == 0) {
      setState(() {
        for (int i = 0; i < _cardCount; i++) {
          final p = _positions[i]!;
          _positions[i] = (p - 1 + _cardCount) % _cardCount;
        }
      });
      return;
    }

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

    final sortedIndices = List<int>.generate(_cardCount, (i) => i)
      ..sort((a, b) {
        final posA = _positions[a]!;
        final posB = _positions[b]!;
        return posB.compareTo(posA);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final cardWidth = (parentWidth * 0.75).clamp(240.0, 310.0);
        final cardHeight = cardWidth;
        final containerHeight = cardHeight + 60;
        final stepOffset = cardWidth * 0.12;

        return Container(
          height: containerHeight,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Stack(
            alignment: Alignment.center,
            children: sortedIndices.map((idx) {
              final collection = widget.collections[idx];
              final position = _positions[idx]!;

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
                  leftOffset = stepOffset * 0.6;
                  topOffset = 0.0;
                  scale = 1.0;
                  rotation = 0.0;
                  opacity = 1.0;
                  isInteractive = true;
                } else {
                  leftOffset = -stepOffset * 0.6;
                  topOffset = 12.0;
                  scale = 0.92;
                  rotation = -0.08;
                  opacity = 1.0;
                  isInteractive = true;
                }
              } else {
                if (position == 0) {
                  leftOffset = stepOffset;
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
                  leftOffset = -stepOffset;
                  topOffset = 24.0;
                  scale = 0.88;
                  rotation = -0.12;
                  opacity = 1.0;
                  isInteractive = true;
                } else {
                  leftOffset = -stepOffset;
                  topOffset = 24.0;
                  scale = 0.0;
                  rotation = -0.12;
                  opacity = 0.0;
                  isInteractive = false;
                }
              }

              return AnimatedPositioned(
                key: ValueKey(collection.id),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: (parentWidth - cardWidth) / 2 + leftOffset,
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
                          child: RepaintBoundary(
                            child: _buildCard(collection, cardWidth, cardHeight),
                          ),
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

  Widget _buildCard(Collection collection, double width, double height) {
    return Container(
      width: width,
      height: height,
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
            CachedNetworkImage(
              imageUrl: collection.coverImageUrl ?? '',
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
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xxl, context.pagePad, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    collection.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${collection.itemCount} items',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CollectionDetailView(collection: collection),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                      child: const Text(
                        'Explore',
                        style: TextStyle(color: Colors.white,
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
