import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/collection.dart';
import '../view_models/collections_view_model.dart';
import '../widgets/collection_feed_card.dart';
import 'collection_detail_view.dart';
import '../../../shared/widgets/app_animations.dart';
import 'collection_form_page.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class CollectionsTabView extends ConsumerStatefulWidget {
  const CollectionsTabView({super.key});

  @override
  ConsumerState<CollectionsTabView> createState() => _CollectionsTabViewState();
}

class _CollectionsTabViewState extends ConsumerState<CollectionsTabView>
    with AutomaticKeepAliveClientMixin {
  CollectionCategory? _selectedCategory;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final vm = ref.watch(collectionsViewModelProvider);

    var collections = vm.allCollections;
    if (_selectedCategory != null) {
      collections = collections.where((c) => c.category == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Collections',
          actions: [
            GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedCategory != null
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.line_horizontal_3_decrease_circle,
                  size: 20,
                  color: _selectedCategory != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          bottomChild: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const CollectionFormPage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.add, size: 16),
              label: const Text('Make Your Own Collection'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        bodyBuilder: (context, topPadding) => _BrowseFeed(
          collections: collections,
          theme: theme,
          isLoading: vm.isLoading,
          error: vm.error,
          topPadding: topPadding + 4,
          onCollectionTap: (c) => _openDetail(context, c),
          onFollowTap: (c) => vm.toggleFollow(c.id),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Collection collection) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => CollectionDetailView(collection: collection),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161616) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xl, context.pagePad, AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter by category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                    if (_selectedCategory != null)
                      GestureDetector(
                        onTap: () { setState(() => _selectedCategory = null); Navigator.pop(ctx); },
                        child: Text('Clear', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CollectionCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = _selectedCategory == cat ? null : cat);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          cat.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrowseFeed extends StatelessWidget {
  const _BrowseFeed({
    required this.collections,
    required this.theme,
    required this.isLoading,
    this.error,
    required this.topPadding,
    required this.onCollectionTap,
    required this.onFollowTap,
  });

  final List<Collection> collections;
  final ThemeData theme;
  final bool isLoading;
  final String? error;
  final double topPadding;
  final void Function(Collection) onCollectionTap;
  final void Function(Collection) onFollowTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          const SliverToBoxAdapter(
            child: ShimmerCollectionCard(count: 2),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }
    if (error != null) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(error!, style: TextStyle(color: theme.colorScheme.error))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }
    if (collections.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: AnimatedAppearance(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.square_list, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('No collections found', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
    }

    final columns = AppBreakpoints.value(context, mobile: 1, tablet: 2, desktop: 3);
    final aspectRatio = AppBreakpoints.value(context, mobile: 1.7, tablet: 1.4, desktop: 1.55);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPadding)),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.lg, context.pagePad, AppSpacing.xxl),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppGrid.spacing(context),
              crossAxisSpacing: AppGrid.spacing(context),
              childAspectRatio: aspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final collection = collections[index];
                return StaggeredListItem(
                  index: index,
                  child: CollectionFeedCard(
                    collection: collection,
                    onTap: () => onCollectionTap(collection),
                    onFollow: () => onFollowTap(collection),
                  ),
                );
              },
              childCount: collections.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
