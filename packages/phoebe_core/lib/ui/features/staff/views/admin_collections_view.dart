import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/collections_repository.dart';
import '../../../../domain/models/collection.dart';
import '../../collections/view_models/collections_view_model.dart';
import '../../collections/views/collection_form_page.dart';
import '../../../core/theme.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../view_models/admin_collections_view_model.dart';

class AdminCollectionsView extends ConsumerStatefulWidget {
  const AdminCollectionsView({super.key});

  @override
  ConsumerState<AdminCollectionsView> createState() => _AdminCollectionsViewState();
}

class _AdminCollectionsViewState extends ConsumerState<AdminCollectionsView> {
  String _searchQuery = '';
  CollectionCategory? _selectedCategory;
  bool _showFeaturedOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = ref.watch(collectionsViewModelProvider);
    final collections = vm.allCollections;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Looks',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.add_circled, color: theme.colorScheme.primary, size: 28),
            tooltip: 'Create Look',
            onPressed: () => _openCollectionForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: AppSpacing.sm),
              child: CupertinoSearchTextField(
                placeholder: 'Search looks by title...',
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: theme.colorScheme.onSurface),
                placeholderStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                itemColor: theme.colorScheme.onSurfaceVariant,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: context.pagePad - 8),
                itemCount: CollectionCategory.values.length + 1,
                itemBuilder: (context, index) {
                  final cat = index == 0 ? null : CollectionCategory.values[index - 1];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: AnimatedTapScale(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cat?.displayName ?? 'All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showFeaturedOnly = !_showFeaturedOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showFeaturedOnly
                            ? Colors.amber.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showFeaturedOnly
                              ? Colors.amber
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: _showFeaturedOnly ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _showFeaturedOnly ? FontWeight.bold : FontWeight.w500,
                              color: _showFeaturedOnly ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: vm.isLoading
                  ? const ShimmerProductGrid(itemCount: 4)
                  : vm.error != null
                      ? Center(
                          child: EmptyStateWidget(
                            icon: CupertinoIcons.exclamationmark_triangle,
                            title: 'Error Loading Looks',
                            message: vm.error!,
                          ),
                        )
                      : Builder(builder: (context) {
                  final filtered = collections.where((c) {
                    final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        c.description.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesCategory = _selectedCategory == null || c.category == _selectedCategory;
                    final matchesFeatured = !_showFeaturedOnly || c.isFeatured;
                    return matchesSearch && matchesCategory && matchesFeatured;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyStateWidget(
                        icon: CupertinoIcons.photo_on_rectangle,
                        title: 'No Looks Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No matches found for "$_searchQuery".'
                            : 'No looks created yet. Tap + to create one.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: EdgeInsets.fromLTRB(context.pagePad, 8, context.pagePad, 80),
                    itemBuilder: (context, index) {
                      final collection = filtered[index];
                      return _CollectionListCard(
                        collection: collection,
                        onEdit: () => _openCollectionForm(context, collection: collection),
                        onDelete: () => _confirmDelete(context, collection),
                        theme: theme,
                        isDark: isDark,
                      );
                    },
                  );
                }),
            ),
          ],
        ),
      ),
    );
  }

  void _openCollectionForm(BuildContext context, {Collection? collection}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CollectionFormPage(collection: collection),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Collection collection) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Look'),
        content: Text('Are you sure you want to permanently delete "${collection.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final viewModel = ref.read(adminCollectionsViewModelProvider.notifier);
      try {
        await viewModel.removeCollection(collection.id, collection.title);
        if (context.mounted) {
          context.showSnackBar('Look deleted successfully', type: SnackBarType.success);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBar('Failed to delete look: $e', type: SnackBarType.error);
        }
      }
    }
  }
}

class _CollectionListCard extends ConsumerWidget {
  const _CollectionListCard({
    required this.collection,
    required this.onEdit,
    required this.onDelete,
    required this.theme,
    required this.isDark,
  });

  final Collection collection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 100,
                child: collection.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: collection.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainer,
                          child: const Center(child: CupertinoActivityIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainer,
                          child: Icon(CupertinoIcons.photo, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(CupertinoIcons.photo_on_rectangle, color: theme.colorScheme.primary),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              collection.category.displayName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${collection.itemCount} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        collection.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collection.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        collection.isFeatured ? CupertinoIcons.star_fill : CupertinoIcons.star,
                        color: collection.isFeatured ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(collectionsRepositoryProvider).setFeatured(
                          collection.id,
                          !collection.isFeatured,
                        );
                      },
                      tooltip: collection.isFeatured ? 'Remove from Shop the Look' : 'Add to Shop the Look',
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.pencil, color: theme.colorScheme.primary, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit look',
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.trash, color: theme.colorScheme.error, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete look',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


