import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/services/paystack_service.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../domain/models/order.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../services/service_constants.dart';

class CustomerOrderDetailView extends ConsumerStatefulWidget {
  const CustomerOrderDetailView({required this.orderId, super.key});
  final String orderId;

  @override
  ConsumerState<CustomerOrderDetailView> createState() => _CustomerOrderDetailViewState();
}

class _CustomerOrderDetailViewState extends ConsumerState<CustomerOrderDetailView> with WidgetsBindingObserver {
  bool _busy = false;
  String? _pendingRef;
  bool _awaitingPayment = false;
  late final Future<Order> _orderFuture =
      ref.read(orderRepositoryProvider).getOrderWithItems(widget.orderId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingPayment) {
      _awaitingPayment = false;
      final refToVerify = _pendingRef;
      _pendingRef = null;
      if (refToVerify != null) {
        _verifyPayment(refToVerify);
      }
    }
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled || OrderStatus.refunded => Colors.red,
        OrderStatus.quoteSent => Colors.amber,
        OrderStatus.preparing || OrderStatus.outForDelivery => Colors.orange,
        _ => Theme.of(context).colorScheme.primary,
      };

  Future<void> _acceptQuote() async {
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).acceptDeliveryQuote(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote accepted! Your order is being prepared.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payForOrder(double total) async {
    setState(() => _busy = true);
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      final email = user?.email ?? 'customer@fijadora.com';
      final reference = 'ORD_${DateTime.now().millisecondsSinceEpoch}_${widget.orderId}';

      final init = await PaystackService.instance.initializeCheckout(
        email: email,
        amountKobo: (total * 100).round(),
        reference: reference,
        orderId: widget.orderId,
        callbackUrl: 'fijadora://app/paystack-callback',
      );

      final isMock = init['mock'] == true;
      final authUrl = init['authorization_url'] as String?;

      if (isMock) {
        await _verifyPayment(reference);
        return;
      }

      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open browser. Pay at:\n$authUrl')),
            );
          }
          return;
        }
        _pendingRef = reference;
        _awaitingPayment = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete payment in browser, then return here to verify.')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyPayment(String reference) async {
    try {
      final result = await PaystackService.instance.verifyTransaction(reference);
      final status = result['status'] as String?;
      final gatewayResponse = result['gateway_response'] as String?;

      if (status == 'success') {
        await ref.read(orderRepositoryProvider).markOrderPaid(widget.orderId, reference);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful! Your order is being prepared.')),
          );
          Navigator.of(context).pop();
        }
      } else if (status == 'failed') {
        final reason = gatewayResponse ?? 'Payment declined by bank or card issuer';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $reason. Please try again.')),
          );
        }
      } else if (status == 'abandoned') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment was not completed. Please try again.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment could not be verified. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
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
          return _Body(
            order: order,
            ref: ref,
            busy: _busy,
            statusColor: _statusColor(order.status),
            onAcceptQuote: _acceptQuote,
            onPayForOrder: _payForOrder,
          );
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.order,
    required this.ref,
    required this.busy,
    required this.statusColor,
    required this.onAcceptQuote,
    required this.onPayForOrder,
  });

  final Order order;
  final WidgetRef ref;
  final bool busy;
  final Color statusColor;
  final VoidCallback onAcceptQuote;
  final void Function(double total) onPayForOrder;

  @override
  Widget build(BuildContext context, final WidgetRef ref) {
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
            StatusPill(label: order.status.label, color: statusColor),
          ],
        ),
        const SizedBox(height: 16),

        // Awaiting quote banner
        if (order.status == OrderStatus.pending) ...[
          AppCard(
            child: Row(
              children: [
                Icon(CupertinoIcons.clock, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Awaiting Delivery Quote',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        'We\'re reviewing your delivery location and will send you a quote shortly.',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Delivery quote banner
        if (order.status == OrderStatus.quoteSent) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.money_dollar_circle, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Delivery Quote Ready',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TotalRow(label: 'Subtotal', value: order.subtotal),
                _TotalRow(label: 'Delivery fee', value: order.deliveryFee),
                const Divider(height: 16),
                _TotalRow(label: 'Total', value: order.total, bold: true),
                const SizedBox(height: 16),
                if (busy)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onPayForOrder(order.total),
                      child: const Text('Pay with Paystack'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onAcceptQuote,
                      child: const Text('Accept Quote'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

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
                                Text('Qty: ${it.quantity}  Â·  ${formatGhs(it.unitPrice)} each',
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(formatGhs((it.unitPrice * it.quantity)),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              const Divider(height: 20),
              _TotalRow(label: 'Subtotal', value: order.subtotal),
              if (order.status != OrderStatus.pending) ...[
                _TotalRow(label: 'Delivery fee', value: order.deliveryFee),
                _TotalRow(label: 'Total', value: order.total, bold: true),
              ] else ...[
                _TotalRow(label: 'Delivery fee', value: 0, muted: true),
              ],
            ],
          ),
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
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rejection reason
        if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.xmark_circle_fill, color: Colors.red, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Rejected',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(order.rejectionReason!,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Order timeline
        if (order.status != OrderStatus.pending && order.status != OrderStatus.quoteSent) ...[
          OrderTimeline(order: order),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// â”€â”€â”€ Shared widgets â”€â”€â”€

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
                  TextSpan(text: value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
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
    final color = muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
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
            muted ? 'TBD' : formatGhs(value),
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
