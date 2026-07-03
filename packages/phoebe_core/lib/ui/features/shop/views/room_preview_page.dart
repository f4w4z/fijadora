import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/product.dart';
import '../../../../data/services/room_preview_service.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../core/theme.dart';

enum _PageState { initial, loading, results }

class RoomPreviewPage extends ConsumerStatefulWidget {
  const RoomPreviewPage({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<RoomPreviewPage> createState() => _RoomPreviewPageState();
}

class _RoomPreviewPageState extends ConsumerState<RoomPreviewPage> {
  _PageState _state = _PageState.initial;
  final ImagePicker _picker = ImagePicker();
  List<Uint8List>? _generatedImages;

  Future<void> _pickRoomPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      setState(() => _state = _PageState.loading);

      final service = ref.read(roomPreviewServiceProvider);
      final results = await service.generatePreviews(
        productImageUrl: widget.product.imageUrl,
        roomPhotoBytes: bytes,
      );

      if (mounted) {
        setState(() {
          _generatedImages = results;
          _state = _PageState.results;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Could not generate preview. Try again.', type: SnackBarType.error);
        setState(() => _state = _PageState.initial);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Room Preview',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (_state) {
          _PageState.initial => _buildInitial(theme),
          _PageState.loading => _buildLoading(theme),
          _PageState.results => _buildResults(theme),
        },
      ),
    );
  }

  Widget _buildInitial(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.camera_viewfinder, size: 40, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'See how ${widget.product.name} fits in your space',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Take a photo of your room and we\'ll show you how this piece looks from 4 different angles.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _pickRoomPhoto(ImageSource.camera),
              icon: const Icon(CupertinoIcons.camera_fill, size: 18),
              label: const Text('Take Room Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _pickRoomPhoto(ImageSource.gallery),
            child: Text(
              'Choose from gallery instead',
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating your preview...',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Placing ${widget.product.name} in your room from 4 angles',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final images = _generatedImages!;
    final labels = ['Front-left view', 'Front-right view', 'Center focus', 'Corner view'];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your room with ${widget.product.name}',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s how it looks from different angles',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _openFullscreen(context, images, index, labels),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.memory(images[index], fit: BoxFit.cover),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          color: theme.colorScheme.surface,
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context, List<Uint8List> images, int startIndex, List<String> labels) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenGallery(images: images, initialIndex: startIndex, labels: labels),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<Uint8List> images;
  final int initialIndex;
  final List<String> labels;

  const _FullscreenGallery({required this.images, required this.initialIndex, required this.labels});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.labels[_currentIndex], style: const TextStyle(fontSize: 14)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.0,
            child: Center(
              child: Image.memory(widget.images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.black,
        child: Center(
          child: Text(
            '${_currentIndex + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
