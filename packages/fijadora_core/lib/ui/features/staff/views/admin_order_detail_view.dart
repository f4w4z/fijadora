import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/delivery.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../core/utilities/responsive_helpers.dart';

class AdminOrderDetailView extends ConsumerStatefulWidget {
  const AdminOrderDetailView({required this.orderId, super.key});
  final String orderId;

  @override
  ConsumerState<AdminOrderDetailView> createState() => _AdminOrderDetailViewState();
}

class _AdminOrderDetailViewState extends ConsumerState<AdminOrderDetailView> {
  bool _busy = false;
  late final Future<Order> _orderFuture =
      ref.read(orderRepositoryProvider).getOrderWithItems(widget.orderId);

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(widget.orderId, status);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked ${status.label}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmAction(OrderStatus status, String label) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(label),
        content: Text('Are you sure you want to mark this order as "${status.label}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(c).pop();
              _updateStatus(status);
            },
            child: Text(label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Order Detail')),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load order: ${snap.error}'));
          }
          final order = snap.data!;
          return _Body(order: order, ref: ref, busy: _busy, onAction: _confirmAction);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order, required this.ref, required this.busy, required this.onAction});
  final Order order;
  final WidgetRef ref;
  final bool busy;
  final void Function(OrderStatus, String) onAction;

  Color _statusColor(OrderStatus s) {
    if (s == OrderStatus.delivered) return Colors.green;
    if (s == OrderStatus.cancelled || s == OrderStatus.refunded) return Colors.red;
    if (s == OrderStatus.paid || s == OrderStatus.shipped || s == OrderStatus.processing) return Colors.orange;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(context.pagePad),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ${order.id.substring(0, 8)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_formatDate(order.createdAt),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            StatusPill(label: order.status.label, color: _statusColor(order.status)),
          ],
        ),
        const SizedBox(height: 16),

        // Customer
        Builder(
          builder: (context) {
            final u = ref.watch(userByIdProvider(order.customerId)).valueOrNull;
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
                        Text(u?.email ?? order.customerId,
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Delivery info
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              _InfoRow(icon: CupertinoIcons.location, label: 'Address', value: order.deliveryAddress),
              if (order.deliveryPhone != null && order.deliveryPhone!.isNotEmpty)
                _InfoRow(icon: CupertinoIcons.phone, label: 'Phone', value: order.deliveryPhone!),
              if (order.deliveryNote != null && order.deliveryNote!.isNotEmpty)
                _InfoRow(icon: CupertinoIcons.text_alignleft, label: 'Note', value: order.deliveryNote!),
              if (order.paystackReference != null)
                _InfoRow(icon: CupertinoIcons.creditcard, label: 'Paystack Ref', value: order.paystackReference!),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                const Text('No items found', style: TextStyle(fontSize: 13))
              else
                ...order.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          RoundedNetworkImage(url: it.imageUrl, height: 52, width: 52, radius: 10),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('Qty: ${it.quantity}  ·  \$${it.unitPrice.toStringAsFixed(2)} each',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('\$${(it.unitPrice * it.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              const Divider(height: 20),
              _TotalRow(label: 'Subtotal', value: order.subtotal),
              _TotalRow(label: 'Delivery fee', value: order.deliveryFee),
              _TotalRow(label: 'Total', value: order.total, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Delivery tracking
        _DeliveryTracker(orderId: order.id),
        const SizedBox(height: 16),

        // Actions
        if (busy) const Center(child: CircularProgressIndicator()),
        if (!busy) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onAction(OrderStatus.delivered, 'Mark Delivered'),
              icon: const Icon(CupertinoIcons.checkmark_circle),
              label: const Text('Mark Delivered'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAction(OrderStatus.shipped, 'Mark Shipped'),
                  child: const Text('Shipped'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAction(OrderStatus.paid, 'Mark Paid'),
                  child: const Text('Paid'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: () => onAction(OrderStatus.cancelled, 'Reject / Cancel'),
              icon: const Icon(CupertinoIcons.xmark_circle),
              label: const Text('Reject / Cancel Order'),
            ),
          ),
        ],
      ],
    );
  }
}

class _DeliveryTracker extends ConsumerWidget {
  const _DeliveryTracker({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deliveryAsync = ref.watch(deliveryForOrderProvider(orderId));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Tracking', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              if (deliveryAsync.isLoading && !deliveryAsync.hasValue) {
                return const Center(child: CircularProgressIndicator());
              }
              final d = deliveryAsync.valueOrNull;
              if (d == null) return const Text('No delivery assigned yet.', style: TextStyle(fontSize: 13));
              final steps = [
                ('Pending', d.status.index >= DeliveryStatus.pending.index),
                ('Assigned', d.status.index >= DeliveryStatus.assigned.index),
                ('In Transit', d.status.index >= DeliveryStatus.inTransit.index),
                ('Delivered', d.status.index >= DeliveryStatus.delivered.index),
              ];
              return Column(
                children: steps.map((s) {
                  final done = s.$2;
                  return Row(
                    children: [
                      Icon(done ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                          color: done ? Colors.green : theme.colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Text(s.$1, style: TextStyle(
                        fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                        color: done ? Colors.green : theme.colorScheme.onSurfaceVariant,
                      )),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$label:  ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  TextSpan(text: value, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
