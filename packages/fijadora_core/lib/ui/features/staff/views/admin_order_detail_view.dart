import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/delivery.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/order_timeline.dart';
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

  Future<void> _updateStatus(OrderStatus status, {String? trackingId, String? trackingCompany, String? reason}) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(orderRepositoryProvider);

      if (status == OrderStatus.cancelled) {
        await repo.rejectOrder(widget.orderId, reason ?? 'No reason provided');
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected')));
        }
        return;
      }

      await repo.updateOrderStatus(widget.orderId, status);

      // Also update delivery status when relevant
      if (status == OrderStatus.outForDelivery) {
        final delivery = await repo.streamDeliveryForOrder(widget.orderId).first;
        if (delivery != null) {
          await repo.updateDeliveryStatus(delivery.id, DeliveryStatus.inTransit, trackingId: trackingId, trackingCompany: trackingCompany);
        }
      } else if (status == OrderStatus.delivered) {
        final delivery = await repo.streamDeliveryForOrder(widget.orderId).first;
        if (delivery != null) {
          await repo.updateDeliveryStatus(delivery.id, DeliveryStatus.delivered);
        }
      } else if (status == OrderStatus.preparing) {
        final delivery = await repo.streamDeliveryForOrder(widget.orderId).first;
        if (delivery != null && delivery.status == DeliveryStatus.pending) {
          await repo.updateDeliveryStatus(delivery.id, DeliveryStatus.pickedUp);
        }
      }

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
    if (status == OrderStatus.outForDelivery) {
      final trackingController = TextEditingController();
      final companyController = TextEditingController();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Out for Delivery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Mark this order as out for delivery?'),
                const SizedBox(height: 12),
                TextField(
                  controller: trackingController,
                  decoration: const InputDecoration(
                    labelText: 'Tracking ID (optional)',
                    hintText: 'e.g. CP123456789',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Courier company (optional)',
                    hintText: 'e.g. DHL, FedEx, UPS',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(c).pop();
                final tid = trackingController.text.trim();
                final company = companyController.text.trim();
                _updateStatus(status, trackingId: tid.isNotEmpty ? tid : null, trackingCompany: company.isNotEmpty ? company : null);
              },
              child: const Text('Mark Out for Delivery'),
            ),
          ],
        ),
      );
      return;
    }

    if (status == OrderStatus.cancelled) {
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Reject Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Provide a reason the customer can see:'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Rejection reason',
                    hintText: 'e.g. Address is outside delivery zone',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(c).pop();
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a rejection reason')),
                  );
                  return;
                }
                _updateStatus(OrderStatus.cancelled, reason: reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Reject Order'),
            ),
          ],
        ),
      );
      return;
    }

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

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled || OrderStatus.refunded => Colors.red,
        OrderStatus.quoteSent => Colors.amber,
        OrderStatus.preparing || OrderStatus.outForDelivery => Colors.orange,
        _ => Colors.teal,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = order.status == OrderStatus.pending;
    final isQuoteSent = order.status == OrderStatus.quoteSent;

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

        // Delivery quote form (shown when pending)
        if (isPending) ...[
          _DeliveryQuoteForm(order: order, orderId: order.id),
          const SizedBox(height: 12),
        ],

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
              _TotalRow(
                label: 'Delivery fee',
                value: order.deliveryFee,
                muted: isPending,
              ),
              if (!isPending)
                _TotalRow(label: 'Total', value: order.total, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Order timeline
        OrderTimeline(order: order),
        const SizedBox(height: 16),

        // Actions
        if (busy) const Center(child: CircularProgressIndicator()),
        if (!busy) ...[
          if (isQuoteSent) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onAction(OrderStatus.preparing, 'Mark as Preparing'),
                icon: const Icon(CupertinoIcons.cube_box),
                label: const Text('Mark as Preparing'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (order.status == OrderStatus.preparing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onAction(OrderStatus.outForDelivery, 'Mark Out for Delivery'),
                icon: const Icon(CupertinoIcons.car),
                label: const Text('Out for Delivery'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (order.status == OrderStatus.outForDelivery) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onAction(OrderStatus.delivered, 'Mark Delivered'),
                icon: const Icon(CupertinoIcons.checkmark_circle),
                label: const Text('Mark Delivered'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (order.status == OrderStatus.pending || isQuoteSent || order.status == OrderStatus.preparing) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: () => onAction(OrderStatus.cancelled, 'Cancel Order'),
                icon: const Icon(CupertinoIcons.xmark_circle),
                label: const Text('Cancel Order'),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Delivery Quote Form ───

class _DeliveryQuoteForm extends ConsumerStatefulWidget {
  const _DeliveryQuoteForm({required this.order, required this.orderId});
  final Order order;
  final String orderId;

  @override
  ConsumerState<_DeliveryQuoteForm> createState() => _DeliveryQuoteFormState();
}

class _DeliveryQuoteFormState extends ConsumerState<_DeliveryQuoteForm> {
  final _feeController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.deliveryFee > 0) {
      _feeController.text = widget.order.deliveryFee.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _sendQuote() async {
    final fee = double.tryParse(_feeController.text.trim());
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid delivery fee')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).sendDeliveryQuote(widget.orderId, fee);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery quote sent to customer')));
        Navigator.of(context).pop();
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.money_dollar_circle, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Text('Send Delivery Quote', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Review the delivery address below and enter a fee.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feeController,
            decoration: const InputDecoration(
              labelText: 'Delivery fee',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          _busy
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendQuote,
                    icon: const Icon(CupertinoIcons.paperplane, size: 18),
                    label: const Text('Send Quote'),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───

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
  const _TotalRow({required this.label, required this.value, this.bold = false, this.muted = false});
  final String label;
  final double value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted ? theme.colorScheme.onSurfaceVariant : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            color: color,
          )),
          Text(
            muted ? 'TBD' : '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? theme.colorScheme.primary : color,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
