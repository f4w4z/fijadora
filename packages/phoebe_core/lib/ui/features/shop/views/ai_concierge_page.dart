import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/product.dart';
import 'product_detail_view.dart';
import '../../../core/utilities/responsive_helpers.dart';

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
        padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload a room photo to get recommendations matching your space layout and aesthetic.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: _analyzing
                  ? const AiScanningSimulator()
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
            const SizedBox(height: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Matching Pieces in Shop',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: widget.recommended.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
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

class AiScanningSimulator extends StatefulWidget {
  const AiScanningSimulator({super.key});

  @override
  State<AiScanningSimulator> createState() => _AiScanningSimulatorState();
}

class _AiScanningSimulatorState extends State<AiScanningSimulator> with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  late final Animation<double> _scanAnimation;
  late final Timer _textTimer;
  int _textIndex = 0;

  final List<String> _steps = [
    'Detecting walls and ceiling plane...',
    'Analyzing ambient lighting & shadows...',
    'Mapping room dimensions...',
    'Selecting matching color palettes...',
    'Selecting curated pieces...',
  ];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _textTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 240,
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GridPaper(
                    color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    divisions: 1,
                    subdivisions: 1,
                    interval: 30,
                  ),
                ),
                const Positioned(
                  top: 16, left: 16,
                  child: SkeletonBox(width: 20, height: 2, borderRadius: 0),
                ),
                const Positioned(
                  top: 16, left: 16,
                  child: SkeletonBox(width: 2, height: 20, borderRadius: 0),
                ),
                const Positioned(
                  top: 16, right: 16,
                  child: SkeletonBox(width: 20, height: 2, borderRadius: 0),
                ),
                const Positioned(
                  top: 16, right: 16,
                  child: SkeletonBox(width: 2, height: 20, borderRadius: 0),
                ),
                const Positioned(
                  bottom: 16, left: 16,
                  child: SkeletonBox(width: 20, height: 2, borderRadius: 0),
                ),
                const Positioned(
                  bottom: 16, left: 16,
                  child: SkeletonBox(width: 2, height: 20, borderRadius: 0),
                ),
                const Positioned(
                  bottom: 16, right: 16,
                  child: SkeletonBox(width: 20, height: 2, borderRadius: 0),
                ),
                const Positioned(
                  bottom: 16, right: 16,
                  child: SkeletonBox(width: 2, height: 20, borderRadius: 0),
                ),
                Center(
                  child: Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanAnimation.value * 240,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 3,
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
        ),
        const SizedBox(height: 32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _steps[_textIndex],
            key: ValueKey<int>(_textIndex),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
              letterSpacing: 0.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aesthetic Analysis Engine Active',
          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
