import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/item_request_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../domain/models/item_request.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../core/utilities/responsive_helpers.dart';

class AdminRequestDetailView extends ConsumerStatefulWidget {
  const AdminRequestDetailView({required this.requestId, super.key});
  final String requestId;

  @override
  ConsumerState<AdminRequestDetailView> createState() => _AdminRequestDetailViewState();
}

class _AdminRequestDetailViewState extends ConsumerState<AdminRequestDetailView> {
  bool _busy = false;
  late final Future<ItemRequest> _requestFuture =
      ref.read(itemRequestRepositoryProvider).getRequest(widget.requestId);

  Future<void> _update(ItemRequestStatus status) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(itemRequestRepositoryProvider);
      if (status == ItemRequestStatus.fulfilled) {
        await repo.fulfillRequest(widget.requestId);
      } else {
        await repo.updateStatus(widget.requestId, status);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request ${status.label}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Request Detail')),
      body: FutureBuilder<ItemRequest>(
        future: _requestFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Could not load request: ${snap.error}'));
          final req = snap.data!;
          return _Body(req: req, ref: ref, busy: _busy, onUpdate: _update);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.req, required this.ref, required this.busy, required this.onUpdate});
  final ItemRequest req;
  final WidgetRef ref;
  final bool busy;
  final Future<void> Function(ItemRequestStatus) onUpdate;

  Color _statusColor(ItemRequestStatus s) {
    return switch (s) {
      ItemRequestStatus.open => Colors.teal,
      ItemRequestStatus.reviewing => Colors.orange,
      ItemRequestStatus.fulfilled => Colors.green,
      ItemRequestStatus.rejected => Colors.red,
      ItemRequestStatus.closed => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _statusColor(req.status);

    return ListView(
      padding: EdgeInsets.all(context.pagePad),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(req.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            StatusPill(label: req.status.label, color: color),
          ],
        ),
        const SizedBox(height: 6),
        Text('Requested ${_fmt(req.createdAt)}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),

        // Customer
        Builder(
          builder: (context) {
            final u = ref.watch(userByIdProvider(req.customerId)).valueOrNull;
            return AppCard(
              child: Row(
                children: [
                  if (u != null) InitialsAvatar(name: u.name, size: 44) else const InitialsAvatar(name: '?', size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u?.name ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(u?.email ?? req.customerId, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Photo (if any)
        if (req.imageUrl != null && req.imageUrl!.isNotEmpty)
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(req.imageUrl!, fit: BoxFit.cover),
            ),
          ),
        if (req.imageUrl != null && req.imageUrl!.isNotEmpty) const SizedBox(height: 12),

        // Description
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Text(req.description, style: const TextStyle(fontSize: 14, height: 1.5)),
              if (req.category != null && req.category!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Category: ${req.category}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (busy) const Center(child: CircularProgressIndicator()),
        if (!busy) ...[
          if (req.status == ItemRequestStatus.open)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onUpdate(ItemRequestStatus.reviewing),
                icon: const Icon(CupertinoIcons.eye),
                label: const Text('Mark Reviewing'),
              ),
            ),
          if (req.status == ItemRequestStatus.reviewing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onUpdate(ItemRequestStatus.fulfilled),
                icon: const Icon(CupertinoIcons.checkmark_circle),
                label: const Text('Mark Fulfilled'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: () => onUpdate(ItemRequestStatus.rejected),
                icon: const Icon(CupertinoIcons.xmark_circle),
                label: const Text('Reject Request'),
              ),
            ),
          ],
          if (req.status == ItemRequestStatus.rejected || req.status == ItemRequestStatus.closed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onUpdate(ItemRequestStatus.open),
                child: const Text('Reopen'),
              ),
            ),
        ],
      ],
    );
  }
}

String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
