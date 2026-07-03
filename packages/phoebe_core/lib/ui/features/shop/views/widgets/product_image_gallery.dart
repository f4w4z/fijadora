import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../domain/models/product.dart';

class ProductNetworkImage extends StatelessWidget {
  const ProductNetworkImage({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: theme.colorScheme.surfaceContainerHighest),
      errorWidget: (context, url, error) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(CupertinoIcons.photo, size: 64, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({
    super.key,
    required this.product,
    this.heroTag,
  });
  final Product product;
  final String? heroTag;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<String> get _images {
    final urls = widget.product.imageUrls;
    if (urls.isNotEmpty) return urls;
    if (widget.product.imageUrl.isNotEmpty) return [widget.product.imageUrl];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = _images;
    final hasMultiple = images.length > 1;
    final galleryHeight = MediaQuery.of(context).size.height * 0.52;

    return SizedBox(
      height: galleryHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          images.isEmpty
              ? Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(CupertinoIcons.photo, size: 64, color: theme.colorScheme.onSurfaceVariant),
                )
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullscreen(context, images, index),
                      child: index == 0
                          ? Hero(
                              tag: widget.heroTag ?? 'product-img-${widget.product.id}',
                              child: ProductNetworkImage(url: images[index]),
                            )
                          : ProductNetworkImage(url: images[index]),
                    );
                  },
                ),
          if (hasMultiple)
            Positioned(
              right: 16,
              bottom: 56,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          if (hasMultiple)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final isActive = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isActive ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, List<String> images, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => ProductFullscreenGallery(
          images: images,
          initialIndex: startIndex,
          productId: widget.product.id,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }
}

class ProductFullscreenGallery extends StatefulWidget {
  const ProductFullscreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.productId,
    this.heroTag,
  });
  final List<String> images;
  final int initialIndex;
  final String productId;
  final String? heroTag;

  @override
  State<ProductFullscreenGallery> createState() => _ProductFullscreenGalleryState();
}

class _ProductFullscreenGalleryState extends State<ProductFullscreenGallery> {
  late int _currentIndex;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: index == widget.initialIndex
                      ? Hero(
                          tag: widget.heroTag ?? 'product-img-${widget.productId}',
                          child: CachedNetworkImage(
                            imageUrl: widget.images[index],
                            fit: BoxFit.contain,
                            errorWidget: (c, u, e) => const Icon(CupertinoIcons.photo, color: Colors.white54, size: 64),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.images[index],
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(CupertinoIcons.photo, color: Colors.white54, size: 64),
                        ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.images.length,
                  itemBuilder: (context, i) {
                    final isActive = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => _ctrl.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: CachedNetworkImage(
                            imageUrl: widget.images[i],
                            memCacheWidth: 120,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(
                              color: Colors.white12,
                              child: const Icon(CupertinoIcons.photo, color: Colors.white54, size: 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
