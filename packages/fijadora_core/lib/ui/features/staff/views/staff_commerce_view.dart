import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../data/repositories/item_request_repository.dart';
import '../../../../data/repositories/wallet_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/item_request.dart';
import '../../../../domain/models/wallet.dart';
import '../../../../domain/models/app_user.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/pin_keypad.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../core/utilities/responsive_helpers.dart';
import 'admin_order_detail_view.dart';
import 'admin_request_detail_view.dart';

final allOrdersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).streamAllOrders();
});

final allItemRequestsProvider = StreamProvider<List<ItemRequest>>((ref) {
  return ref.watch(itemRequestRepositoryProvider).streamAllRequests();
});

final pendingPayoutsProvider = StreamProvider<List<Payout>>((ref) {
  return ref.watch(walletRepositoryProvider).streamPendingPayouts();
});

final allWalletsProvider = StreamProvider<List<WorkerWallet>>((ref) {
  return ref.watch(walletRepositoryProvider).streamAllWallets();
});

/// A single worker's wallet (null until a wallet row exists / they've been credited).
final workerWalletProvider = FutureProvider.family<WorkerWallet?, String>((ref, workerId) {
  return ref.watch(walletRepositoryProvider).getWalletForWorker(workerId);
});

/// Builds an id -> AppUser map for the given ids (customers/workers).
final usersMapProvider = FutureProvider.family<Map<String, AppUser>, List<String>>((ref, ids) {
  return ref.watch(usersRepositoryProvider).fetchUsersByIds(ids);
});

class StaffCommerceView extends ConsumerStatefulWidget {
  const StaffCommerceView({super.key});

  @override
  ConsumerState<StaffCommerceView> createState() => _StaffCommerceViewState();
}

class _StaffCommerceViewState extends ConsumerState<StaffCommerceView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Commerce'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Requests'),
            Tab(text: 'Payouts'),
            Tab(text: 'Workers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OrdersTab(),
          _RequestsTab(),
          _PayoutsTab(),
          _WorkersTab(),
        ],
      ),
    );
  }
}

// ───────────────────────── Orders ─────────────────────────

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load orders: $e')),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyStateWidget(
            icon: CupertinoIcons.bag,
            title: 'No orders yet',
            message: 'Customer purchases will appear here.',
          );
        }
        final customerIds = orders.map((o) => o.customerId).toSet().toList();
        final usersAsync = ref.watch(usersMapProvider(customerIds));
        return ListView.separated(
          padding: EdgeInsets.all(context.pagePad),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => usersAsync.when(
            data: (users) => _OrderCard(order: orders[i], customer: users[orders[i].customerId]),
            loading: () => _OrderCard(order: orders[i]),
            error: (_, __) => _OrderCard(order: orders[i]),
          ),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({this.customer, required this.order});
  final AppUser? customer;
  final Order order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _busy = false;

  Color get _statusColor {
    final s = widget.order.status;
    if (s == OrderStatus.delivered) return Colors.green;
    if (s == OrderStatus.cancelled || s == OrderStatus.refunded) return Colors.red;
    if (s == OrderStatus.paid || s == OrderStatus.shipped || s == OrderStatus.processing) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.primary;
  }

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(widget.order.id, status);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showActions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.checkmark_seal),
              title: const Text('Mark Paid'),
              onTap: () { Navigator.of(c).pop(); _updateStatus(OrderStatus.paid); },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.car),
              title: const Text('Mark Shipped'),
              onTap: () { Navigator.of(c).pop(); _updateStatus(OrderStatus.shipped); },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.checkmark_circle),
              title: const Text('Mark Delivered'),
              onTap: () { Navigator.of(c).pop(); _updateStatus(OrderStatus.delivered); },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.xmark_circle),
              title: const Text('Cancel Order'),
              onTap: () { Navigator.of(c).pop(); _updateStatus(OrderStatus.cancelled); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final itemCount = order.items.fold<int>(0, (a, b) => a + b.quantity);
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminOrderDetailView(orderId: order.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: widget.customer?.name ?? '?', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.customer?.name ?? 'Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('#${order.id.substring(0, 8).toUpperCase()} · ${order.createdAt.formattedShort}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: order.status.label, color: _statusColor),
            ],
          ),
          const SizedBox(height: 14),
          if (order.items.isNotEmpty) ...[
            _ItemThumbStrip(items: order.items),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: CupertinoIcons.cube_box,
                  label: '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  value: '\$${order.subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  icon: CupertinoIcons.car_detailed,
                  label: 'Delivery',
                  value: order.deliveryFee == 0 ? 'Free' : '\$${order.deliveryFee.toStringAsFixed(2)}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
                _SummaryRow(
                  icon: CupertinoIcons.money_dollar_circle,
                  label: 'Total',
                  value: '\$${order.total.toStringAsFixed(2)}',
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, size: 15, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(order.deliveryAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ))
                : FilledButton.tonalIcon(
                    onPressed: _showActions,
                    icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18),
                    label: const Text('Update Status'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasize ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
        Text(value,
            style: TextStyle(
              color: emphasize ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}

class _ItemThumbStrip extends StatelessWidget {
  const _ItemThumbStrip({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxThumbs = 4;
    final shown = items.take(maxThumbs).toList();
    final extra = items.length - shown.length;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RoundedNetworkImage(
                url: item.imageUrl,
                height: 48,
                width: 48,
                radius: 12,
              ),
            ),
          if (extra > 0)
            Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('+$extra',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Requests ─────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allItemRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load requests: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            icon: CupertinoIcons.search,
            title: 'No requests',
            message: "Customers haven't requested items yet.",
          );
        }
        final customerIds = requests.map((r) => r.customerId).toSet().toList();
        final usersAsync = ref.watch(usersMapProvider(customerIds));
        return ListView.separated(
          padding: EdgeInsets.all(context.pagePad),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => usersAsync.when(
            data: (users) => _RequestCard(request: requests[i], customer: users[requests[i].customerId]),
            loading: () => _RequestCard(request: requests[i]),
            error: (_, __) => _RequestCard(request: requests[i]),
          ),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, this.customer});
  final ItemRequest request;
  final AppUser? customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = switch (request.status) {
      ItemRequestStatus.open => theme.colorScheme.primary,
      ItemRequestStatus.reviewing => Colors.orange,
      ItemRequestStatus.fulfilled => Colors.green,
      ItemRequestStatus.rejected => theme.colorScheme.error,
      ItemRequestStatus.closed => theme.colorScheme.onSurfaceVariant,
    };
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminRequestDetailView(requestId: request.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
                RoundedNetworkImage(url: request.imageUrl, height: 64, width: 64, radius: 12)
              else
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.photo, color: theme.colorScheme.onSurfaceVariant),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(request.description,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (customer != null) ...[
                InitialsAvatar(name: customer!.name, size: 26),
                const SizedBox(width: 8),
                Text(customer!.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
              ] else
                const Spacer(),
              StatusPill(label: request.status.label, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (request.status == ItemRequestStatus.open)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(itemRequestRepositoryProvider).updateStatus(request.id, ItemRequestStatus.reviewing),
                    child: const Text('Mark Reviewing'),
                  ),
                ),
              if (request.status == ItemRequestStatus.reviewing) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(itemRequestRepositoryProvider).updateStatus(request.id, ItemRequestStatus.fulfilled),
                    child: const Text('Mark Fulfilled'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(itemRequestRepositoryProvider).updateStatus(request.id, ItemRequestStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Payouts ─────────────────────────

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab();

  Future<void> _managePin(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(walletRepositoryProvider);
    final existing = await repo.getPayoutPin();

    if (existing != null && existing.isNotEmpty) {
      final oldPin = await showPinKeypad(
        context: context,
        title: 'Verify PIN',
        subtitle: 'Enter your current approval PIN to continue',
      );
      if (oldPin == null) return;
      if (oldPin != existing) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current PIN is incorrect')));
        }
        return;
      }
    }

    final newPin = await showPinKeypad(
      context: context,
      title: 'New Approval PIN',
      subtitle: 'Choose a 4-digit approval PIN',
    );
    if (newPin == null) return;
    final confirm = await showPinKeypad(
      context: context,
      title: 'Confirm PIN',
      subtitle: 'Re-enter your new approval PIN',
    );
    if (confirm == null) return;

    if (newPin != confirm) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      }
      return;
    }

    await repo.setPayoutPin(newPin);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approval PIN updated')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(pendingPayoutsProvider);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(context.pagePad, 12, context.pagePad, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _managePin(context, ref),
              icon: const Icon(CupertinoIcons.lock, size: 18),
              label: const Text('Set / Reset Approval PIN'),
            ),
          ),
        ),
        Expanded(
          child: payoutsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Could not load payouts: $e')),
            data: (payouts) {
              if (payouts.isEmpty) {
                return const EmptyStateWidget(
                  icon: CupertinoIcons.money_dollar,
                  title: 'No pending payouts',
                  message: 'Worker withdrawal requests will appear here.',
                );
              }
              final workerIds = payouts.map((p) => p.workerId).toSet().toList();
              final usersAsync = ref.watch(usersMapProvider(workerIds));
              return ListView.separated(
                padding: EdgeInsets.all(context.pagePad),
                itemCount: payouts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => usersAsync.when(
                  data: (users) => _PayoutTile(payout: payouts[i], worker: users[payouts[i].workerId]),
                  loading: () => _PayoutTile(payout: payouts[i]),
                  error: (_, __) => _PayoutTile(payout: payouts[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PayoutTile extends ConsumerStatefulWidget {
  const _PayoutTile({required this.payout, this.worker});
  final Payout payout;
  final AppUser? worker;

  @override
  ConsumerState<_PayoutTile> createState() => _PayoutTileState();
}

class _PayoutTileState extends ConsumerState<_PayoutTile> {
  bool _busy = false;

  Future<void> _approve() async {
    final repo = ref.read(walletRepositoryProvider);
    final existing = await repo.getPayoutPin();

    if (existing == null || existing.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set an approval PIN first (tap Set/Reset Approval PIN)')),
        );
      }
      return;
    }

    final pin = await showPinKeypad(
      context: context,
      title: 'Approve Payout',
      subtitle: 'Enter your approval PIN to release \$${widget.payout.amount.toStringAsFixed(2)}',
    );
    if (pin == null) return;

    if (pin != existing) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect approval PIN')));
      return;
    }

    setState(() => _busy = true);
    try {
      await repo.approvePayout(widget.payout.id, pin: pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout approved & transfer initiated')));
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
    final color = switch (widget.payout.status) {
      PayoutStatus.completed => Colors.green,
      PayoutStatus.processing || PayoutStatus.approved => Colors.orange,
      PayoutStatus.rejected => theme.colorScheme.error,
      PayoutStatus.pending => theme.colorScheme.primary,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.worker != null)
                InitialsAvatar(name: widget.worker!.name, size: 40)
              else
                const InitialsAvatar(name: '?', size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.worker?.name ?? 'Worker',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      widget.payout.bankAccountNumber != null
                          ? '${widget.payout.bankName ?? ''} ****${widget.payout.bankAccountNumber!.substring(widget.payout.bankAccountNumber!.length - 4)}'
                          : 'No bank details',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              StatusPill(label: widget.payout.status.label, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${widget.payout.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          _busy
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(CupertinoIcons.lock, size: 18),
                    label: const Text('Approve & Pay'),
                  ),
                ),
        ],
      ),
    );
  }
}

// ───────────────────────── Workers ─────────────────────────

class _WorkersTab extends ConsumerWidget {
  const _WorkersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersProvider);
    return workersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load workers: $e')),
      data: (workers) {
        if (workers.isEmpty) {
          return const EmptyStateWidget(
            icon: CupertinoIcons.person,
            title: 'No workers',
            message: 'Approved workers will appear here.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(context.pagePad),
          itemCount: workers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _WorkerTile(user: workers[i]),
        );
      },
    );
  }
}

class _WorkerTile extends ConsumerStatefulWidget {
  const _WorkerTile({required this.user});
  final AppUser user;

  @override
  ConsumerState<_WorkerTile> createState() => _WorkerTileState();
}

class _WorkerTileState extends ConsumerState<_WorkerTile> {
  final _amountController = TextEditingController();
  bool _busy = false;

  Future<void> _credit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(walletRepositoryProvider).creditWorker(widget.user.id, amount, description: 'Job payout credited');
      ref.invalidate(workerWalletProvider(widget.user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credited to worker wallet')));
        _amountController.clear();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showCreditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(c).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Credit ${widget.user.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            _busy
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _credit, child: const Text('Credit Wallet')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(workerWalletProvider(widget.user.id));
    final balance = walletAsync.value?.balance ?? 0.0;
    return AppCard(
      child: Row(
        children: [
          InitialsAvatar(name: widget.user.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('Balance: \$${balance.toStringAsFixed(2)}',
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _busy
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _showCreditSheet,
                  child: const Text('Credit'),
                ),
        ],
      ),
    );
  }
}
