import 'package:flutter/material.dart';
import '../../core/utilities/responsive_helpers.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E5E5);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerListPlaceholder extends StatelessWidget {
  const ShimmerListPlaceholder({
    super.key,
    this.itemCount = 3,
    this.padding = const EdgeInsets.all(24.0),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF222222)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 80, height: 18, borderRadius: 4),
                  SkeletonBox(width: 60, height: 18, borderRadius: 12),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: double.infinity, height: 16),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 200, height: 16),
              SizedBox(height: AppSpacing.lg),
              Divider(height: 1),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShimmerProductGrid extends StatelessWidget {
  const ShimmerProductGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.pagePad),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridCols,
          crossAxisSpacing: AppGrid.spacing(context),
          mainAxisSpacing: AppGrid.spacing(context),
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: double.infinity,
                    borderRadius: 16.0,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(width: 120, height: 16, borderRadius: 4),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 60, height: 14, borderRadius: 4),
              ],
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}

class ShimmerServiceGrid extends StatelessWidget {
  const ShimmerServiceGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(context.pagePad, 4, context.pagePad, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.gridCols,
          crossAxisSpacing: AppGrid.spacing(context),
          mainAxisSpacing: AppGrid.spacing(context),
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: SkeletonBox(
                    width: double.infinity,
                    borderRadius: 20.0,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 100, height: 14, borderRadius: 4),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonBox(width: double.infinity, height: 10, borderRadius: 4),
                        SizedBox(height: AppSpacing.xs),
                        SkeletonBox(width: 80, height: 10, borderRadius: 4),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SkeletonBox(width: 60, height: 12, borderRadius: 4),
                            SkeletonBox(width: 26, height: 26, borderRadius: 13),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}

class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: context.pagePad, right: context.pagePad,
              bottom: index == itemCount - 1 ? 0 : 10,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 38, height: 38, borderRadius: 12),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SkeletonBox(height: 14, borderRadius: 4),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            SkeletonBox(width: 50, height: 14, borderRadius: 6),
                          ],
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            SkeletonBox(width: 14, height: 10, borderRadius: 2),
                            SizedBox(width: AppSpacing.xs),
                            SkeletonBox(width: 80, height: 10, borderRadius: 4),
                            SizedBox(width: AppSpacing.sm),
                            SkeletonBox(width: 40, height: 10, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }
}
