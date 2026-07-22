import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/repositories/announcement_repository.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/announcement.dart';
import '../views/product_detail_view.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/utilities/responsive_helpers.dart';

class AnnouncementsView extends ConsumerWidget {
  const AnnouncementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final announcementsAsync = ref.watch(announcementsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load announcements.',
          onRetry: () => ref.invalidate(announcementsStreamProvider),
        ),
        data: (announcements) {
          if (announcements.isEmpty) {
            return const EmptyStateWidget(
              icon: CupertinoIcons.bell,
              title: 'No announcements yet',
              message: 'We\'ll notify you here when new products arrive.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(context.pagePad),
            itemCount: announcements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final a = announcements[index];
              return _AnnouncementCard(announcement: a);
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  const _AnnouncementCard({required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
      return AppCard(
        padding: EdgeInsets.zero,
        onTap: () async {
          if (announcement.productId == null) return;
          final product = await ref.read(productByIdProvider(announcement.productId!).future);
          if (product != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailView(product: product),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: announcement.imageUrl!,
                height: 170,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: theme.colorScheme.surfaceContainerHighest),
                errorWidget: (c, u, e) => Container(color: theme.colorScheme.surfaceContainerHighest),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.body,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  StatusPill(
                    label: 'New',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDate(announcement.createdAt),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

final announcementsStreamProvider = StreamProvider<List<Announcement>>((ref) {
  return ref.watch(announcementRepositoryProvider).streamAnnouncements();
});
