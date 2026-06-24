import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/product.dart';
import 'product_detail_view.dart';

class AiConciergePage extends StatefulWidget {
  const AiConciergePage({super.key, required this.recommended});

  final List<Product> recommended;

  @override
  State<AiConciergePage> createState() => _AiConciergePageState();
}

class _AiConciergePageState extends State<AiConciergePage> {
  bool _uploaded = false;
  bool _analyzing = false;

  Future<void> _uploadAndAnalyze() async {
    setState(() => _analyzing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _uploaded = true;
        _analyzing = false;
      });
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
              'Upload a room photo to get recommendations matching your space layout and aesthetic.',
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
                          Text('Analyzing room geometry & lighting...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : _uploaded
                      ? _buildRecommendations(context)
                      : _buildUploadTrigger(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTrigger(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _uploadAndAnalyze,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=400&auto=format&fit=crop&q=60',
            height: 140,
            width: double.infinity,
            memCacheWidth: 400,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(color: theme.colorScheme.surfaceContainerHighest, height: 140),
            errorWidget: (c, u, e) => Container(color: theme.colorScheme.surfaceContainerHighest, height: 140, child: const Icon(CupertinoIcons.photo)),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text(
              'Aesthetic Style: Warm Minimalist Modern',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Matching Pieces in Shop',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.recommended.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = widget.recommended[index];
              return InkWell(
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
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
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
