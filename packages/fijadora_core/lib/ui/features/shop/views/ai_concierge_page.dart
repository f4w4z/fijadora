import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../../domain/models/product.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import 'product_detail_view.dart';

class AiConciergePage extends ConsumerWidget {
  const AiConciergePage({super.key, required this.catalog});

  final List<Product> catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gemini = ref.read(geminiServiceProvider);
    return _AiConciergeBody(catalog: catalog, gemini: gemini);
  }
}

class _AiConciergeBody extends StatefulWidget {
  final List<Product> catalog;
  final GeminiService gemini;

  const _AiConciergeBody({required this.catalog, required this.gemini});

  @override
  State<_AiConciergeBody> createState() => _AiConciergeBodyState();
}

class _AiConciergeBodyState extends State<_AiConciergeBody> {
  bool _analyzing = false;
  List<Product>? _recommendations;
  String? _error;

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _analyzing = true;
      _error = null;
      _recommendations = null;
    });

    try {
      final recs = await widget.gemini.getDesignRecommendations(
        imageBytes: bytes,
        catalog: widget.catalog,
      );
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _analyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _analyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(CupertinoIcons.sparkles, color: Colors.indigo, size: 20),
            SizedBox(width: 8),
            Text('AI Design Concierge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clear),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload a room photo to get personalized product recommendations matching your space.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _analyzing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 16),
                          Text('Analyzing room with Gemini...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : _recommendations != null
                      ? _buildRecommendations(context)
                      : _buildUploadTrigger(context),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTrigger(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickAndAnalyze,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.photo_on_rectangle, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Upload Living / Bedroom Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Supports JPG, PNG up to 10MB', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Match found! These pieces complement your space.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Matching Pieces',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _recommendations!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = _recommendations![index];
              return AnimatedTapScale(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductDetailView(product: product)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 48,
                          height: 48,
                          memCacheWidth: 100,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: theme.colorScheme.surfaceContainerHighest, width: 48, height: 48),
                          errorWidget: (c, u, e) => Container(color: theme.colorScheme.surfaceContainerHighest, width: 48, height: 48, child: const Icon(CupertinoIcons.photo)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('\$${product.price.toStringAsFixed(0)}', style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
