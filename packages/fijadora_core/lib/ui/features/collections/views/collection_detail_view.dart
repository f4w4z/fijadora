import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../../data/repositories/collections_repository.dart';
import '../widgets/collection_item_tile.dart';
import '../../shop/views/product_detail_view.dart';
import '../../shop/view_models/products_provider.dart';
import '../../services/views/new_request_page.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/product.dart';
import 'collection_form_page.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../staff/view_models/admin_collections_view_model.dart';
import '../../../shared/utils/notification_helper.dart';

class CollectionDetailView extends ConsumerStatefulWidget {
  const CollectionDetailView({super.key, required this.collection});

  final Collection collection;

  @override
  ConsumerState<CollectionDetailView> createState() => _CollectionDetailViewState();
}

class _CollectionDetailViewState extends ConsumerState<CollectionDetailView> {
  bool _contentReady = false;
  bool _isLiked = false;
  bool _isFollowing = false;
  late int _likeCount;
  late int _followerCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.collection.likeCount;
    _followerCount = widget.collection.followerCount;
    if (widget.collection.coverImageUrl == null) {
      _contentReady = true;
    }
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final repo = ref.read(collectionsRepositoryProvider);
    final liked = await repo.hasUserLiked(widget.collection.id, user.id);
    final followed = await repo.hasUserFollowed(widget.collection.id, user.id);
    if (mounted) setState(() { _isLiked = liked; _isFollowing = followed; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final collection = widget.collection;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(context, theme, isDark, collection),
            if (!_contentReady)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _buildShimmer(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Stack(
      key: const ValueKey('shimmer'),
      children: [
        const ShimmerCollectionDetail(),
        // Back button stays usable during loading.
        Positioned(
          top: 0,
          left: 12,
          child: SafeArea(
            child: AnimatedTapScale(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(CupertinoIcons.back, size: 20)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark,
      Collection collection) {
    final hasCover = collection.coverImageUrl != null;
    return CustomScrollView(
      key: const ValueKey('content'),
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 52,
          leading: AnimatedTapScale(
            onTap: () => Navigator.pop(context),
            child: const Center(child: Icon(CupertinoIcons.back, size: 20)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedTapScale(
                onTap: _toggleLike,
                child: Center(
                  child: Icon(
                    _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    size: 20,
                    color: _isLiked ? Colors.red : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (collection.creatorId == ref.read(authViewModelProvider).user?.id)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AnimatedTapScale(
                  onTap: () => _showCreatorOptions(context, ref, collection),
                  child: const Center(child: Icon(CupertinoIcons.ellipsis_vertical, size: 20)),
                ),
              ),
          ],
        ),
        if (hasCover)
          SliverToBoxAdapter(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: collection.coverImageUrl!,
                height: 30.h(context),
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  height: 30.h(context),
                  color: theme.colorScheme.surfaceContainer,
                ),
                errorWidget: (_, _, _) => Container(
                  height: 30.h(context),
                  color: theme.colorScheme.surfaceContainer,
                ),
                imageBuilder: (_, imageProvider) {
                  if (!_contentReady) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _contentReady = true);
                    });
                  }
                  return Image(image: imageProvider, fit: BoxFit.cover,
                    height: 30.h(context), width: double.infinity);
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.xl, context.pagePad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: collection.creatorAvatarUrl != null ? CachedNetworkImageProvider(collection.creatorAvatarUrl!) : null,
                      child: collection.creatorAvatarUrl == null
                          ? Text(collection.creatorName.isNotEmpty ? collection.creatorName[0].toUpperCase() : '?', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('by ${collection.creatorName}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                    if (collection.isEdited) ...[
                      const SizedBox(width: 6),
                      Text('•  Edited', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                    ],
                    const Spacer(),
                    Icon(
                      _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                      size: 14,
                      color: _isLiked ? Colors.red : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text('$_likeCount', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                if (collection.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(collection.description, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(collection.category.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.colorScheme.primary)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0EEEA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('${collection.itemCount} items', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isFollowing ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isFollowing ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePad),
          sliver: SliverList.builder(
            itemCount: collection.items.length,
            itemBuilder: (context, idx) {
              final item = collection.items[idx];
              return CollectionItemTile(
                item: item,
                onTap: () => _onItemTap(context, ref, item),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Future<void> _toggleLike() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final repo = ref.read(collectionsRepositoryProvider);
    final previous = _isLiked;
    final previousCount = _likeCount;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await repo.toggleLike(widget.collection.id, user.id);
    } catch (e) {
      if (mounted) setState(() { _isLiked = previous; _likeCount = previousCount; });
    }
  }

  Future<void> _toggleFollow() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final repo = ref.read(collectionsRepositoryProvider);
    final previous = _isFollowing;
    final previousCount = _followerCount;
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });
    try {
      await repo.toggleFollow(widget.collection.id, user.id);
    } catch (e) {
      if (mounted) setState(() { _isFollowing = previous; _followerCount = previousCount; });
    }
  }

  void _showCreatorOptions(BuildContext context, WidgetRef ref, Collection collection) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil, color: Colors.blue),
                  title: const Text('Edit Look', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => CollectionFormPage(collection: collection),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(CupertinoIcons.trash, color: Colors.red),
                  title: const Text('Delete Look', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Look'),
                        content: const Text('Are you sure you want to delete this look? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await ref.read(adminCollectionsViewModelProvider.notifier).removeCollection(
                          collection.id,
                          collection.title,
                        );
                        if (context.mounted) {
                          context.showSnackBar('Look deleted successfully', type: SnackBarType.success);
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          context.showSnackBar('Failed to delete look: $e', type: SnackBarType.error);
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onItemTap(BuildContext context, WidgetRef ref, CollectionItem item) {
    switch (item.itemType) {
      case CollectionItemType.product:
        if (item.referenceId != null) {
          final catalog = ref.read(productsStreamProvider).valueOrNull ?? [];
          final product = _resolveProduct(item, catalog);
          if (product != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailView(product: product),
              ),
            );
          }
        }
      case CollectionItemType.service:
        if (item.referenceId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewRequestPage(
                initialTrade: TradeType.fromString(item.referenceId),
              ),
            ),
          );
        }
      case CollectionItemType.note:
        break;
    }
  }
}

Product? _resolveProduct(CollectionItem item, List<Product> catalog) {
  final match = catalog.where((p) => p.id == item.referenceId).firstOrNull;
  return match;
}
