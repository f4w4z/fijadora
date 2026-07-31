import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/delivery.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../core/utilities/responsive_helpers.dart';
import 'customer_order_detail_view.dart';
import '../../services/service_constants.dart';

final customerOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).streamCustomerOrders();
});

class CustomerOrdersView extends ConsumerWidget {
  const CustomerOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(customerOrdersProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load orders.',
          onRetry: () => ref.invalidate(customerOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyStateWidget(
              icon: CupertinoIcons.bag,
              title: 'No orders yet',
              message: 'Items you buy will show up here with delivery tracking.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(context.pagePad),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _OrderTile(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends ConsumerWidget {
  const _OrderTile({required this.order});
  final Order order;

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled || OrderStatus.refunded => Colors.red,
        OrderStatus.quoteSent => Colors.amber,
        OrderStatus.preparing || OrderStatus.outForDelivery => Colors.orange,
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deliveryAsync = ref.watch(deliveryForOrderProvider(order.id));
    final delivery = deliveryAsync.valueOrNull;
    final color = _statusColor(order.status);
    final needsAction = order.status == OrderStatus.quoteSent;
    final showItems = order.items.take(3).toList();
    final extraCount = order.items.length - showItems.length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CustomerOrderDetailView(orderId: order.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color accent bar
            Container(height: 3, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (needsAction)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ACTION NEEDED',
                              style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(order.status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Item thumbnails row
                  if (showItems.isNotEmpty) ...[
                    Row(
                      children: [
                        ...showItems.map((item) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: RoundedNetworkImage(
                                url: item.imageUrl,
                                height: 36,
                                width: 36,
                                radius: 8,
                              ),
                            )),
                        if (extraCount > 0)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('+$extraCount',
                                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        const Spacer(),
                        Text(formatGhs(order.total),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Status info
                  Text(
                    order.status == OrderStatus.pending
                        ? 'Awaiting delivery quote'
                        : order.status == OrderStatus.quoteSent
                            ? 'Delivery fee: ${formatGhs(order.deliveryFee)}'
                            : order.deliveryAddress,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Delivery line
                  if (delivery != null && order.status != OrderStatus.pending && order.status != OrderStatus.quoteSent) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          delivery.status == DeliveryStatus.delivered
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.cube_box,
                          size: 14,
                          color: delivery.status == DeliveryStatus.delivered
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            delivery.trackingId != null
                                ? 'Tracking: ${delivery.trackingId}'
                                : delivery.status.label,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(order.updatedAt),
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day}/${d.month} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
