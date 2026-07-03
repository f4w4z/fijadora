import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/collection.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/animated_tap_scale.dart';

class CollectionFeedCard extends StatelessWidget {
  const CollectionFeedCard({
    super.key,
    required this.collection,
    this.onTap,
    this.onFollow,
  });

  final Collection collection;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AnimatedTapScale(
        onTap: onTap ?? () {},
        scaleFactor: 0.97,
        child: Container(
          height: 25.h(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (collection.coverImageUrl != null)
                CachedNetworkImage(
                  imageUrl: collection.coverImageUrl!,
                  memCacheWidth: 400,
                  placeholder: (_, _) => Container(color: theme.colorScheme.surfaceContainer),
                  errorWidget: (_, _, _) => Container(color: theme.colorScheme.surfaceContainer, child: const Center(child: Icon(CupertinoIcons.photo, size: 32))),
                )
              else
                Container(color: theme.colorScheme.primary.withValues(alpha: 0.08), child: Center(child: Icon(CupertinoIcons.square_list, size: 40, color: theme.colorScheme.primary.withValues(alpha: 0.4)))),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              if (onFollow != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFollow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collection.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundImage: collection.creatorAvatarUrl != null ? CachedNetworkImageProvider(collection.creatorAvatarUrl!) : null,
                          child: collection.creatorAvatarUrl == null
                              ? Text(collection.creatorName.isNotEmpty ? collection.creatorName[0].toUpperCase() : '?', style: TextStyle(fontSize: 8, color: Colors.white))
                              : null,
                        ),
                        const SizedBox(width: 5),
                        Text(collection.creatorName, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        const Spacer(),
                        Text('${collection.itemCount} items', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                      ],
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
