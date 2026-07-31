import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/delivery.dart';

class OrderTimeline extends ConsumerWidget {
  const OrderTimeline({required this.order, super.key});
  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deliveryAsync = ref.watch(deliveryForOrderProvider(order.id));
    final delivery = deliveryAsync.valueOrNull;

    final stages = _buildStages(order, delivery);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.clock, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Order Timeline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(stages.length, (i) {
              final stage = stages[i];
              final isLast = i == stages.length - 1;
              return _TimelineStage(
                stage: stage,
                isLast: isLast,
                theme: theme,
              );
            }),
          ],
        ),
      ),
    );
  }

  List<_StageData> _buildStages(Order order, Delivery? delivery) {
    final active = order.status.isActive;
    final paid = order.paystackPaidAt != null ||
        order.status.index >= OrderStatus.preparing.index;
    final preparing = order.status.index >= OrderStatus.preparing.index;
    final assigned = delivery != null && delivery.status.index >= DeliveryStatus.assigned.index;
    final inTransit = delivery != null && delivery.status.index >= DeliveryStatus.inTransit.index;
    final delivered = delivery != null && delivery.status.index >= DeliveryStatus.delivered.index;
    final cancelled = order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded;

    return [
      _StageData(
        title: 'Order Placed',
        subtitle: _formatDate(order.createdAt),
        done: true,
        active: true,
      ),
      _StageData(
        title: 'Payment Confirmed',
        subtitle: order.paystackPaidAt != null ? _formatDate(order.paystackPaidAt!) : null,
        done: paid,
        active: active && !cancelled,
      ),
      _StageData(
        title: 'Packing',
        subtitle: preparing ? 'Your items are being prepared' : null,
        done: preparing,
        active: active && paid && !cancelled,
      ),
      _StageData(
        title: 'Courier Assigned',
        subtitle: delivery?.trackingId != null
            ? (delivery!.trackingCompany != null
                ? '${delivery.trackingCompany}: ${delivery.trackingId}'
                : 'Tracking: ${delivery.trackingId}')
            : (assigned ? 'Courier picked up your package' : null),
        done: assigned,
        active: active && preparing && !cancelled,
      ),
      _StageData(
        title: 'In Transit',
        subtitle: delivery?.trackingId != null
            ? (delivery!.trackingCompany != null
                ? '${delivery.trackingCompany}: ${delivery.trackingId}'
                : 'Tracking: ${delivery.trackingId}')
            : (inTransit ? 'On its way to you' : null),
        done: inTransit,
        active: active && assigned && !cancelled,
      ),
      _StageData(
        title: cancelled ? 'Cancelled' : 'Delivered',
        subtitle: delivered && delivery.deliveredAt != null
            ? _formatDate(delivery.deliveredAt!)
            : (cancelled ? 'Order was cancelled' : null),
        done: delivered || cancelled,
        active: cancelled || (active && inTransit),
        isError: cancelled,
      ),
    ];
  }
}

class _StageData {
  final String title;
  final String? subtitle;
  final bool done;
  final bool active;
  final bool isError;

  const _StageData({
    required this.title,
    this.subtitle,
    this.done = false,
    this.active = false,
    this.isError = false,
  });
}

class _TimelineStage extends StatelessWidget {
  const _TimelineStage({
    required this.stage,
    required this.isLast,
    required this.theme,
  });

  final _StageData stage;
  final bool isLast;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final doneColor = stage.isError ? Colors.red : Colors.green;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    final circleColor = stage.done
        ? doneColor
        : (stage.active ? activeColor : inactiveColor);
    final lineColor = stage.done
        ? doneColor
        : (stage.active ? activeColor.withValues(alpha: 0.3) : inactiveColor.withValues(alpha: 0.2));
    final textColor = stage.done
        ? theme.colorScheme.onSurface
        : (stage.active ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45));
    final subtitleColor = stage.done
        ? theme.colorScheme.onSurfaceVariant
        : (stage.active ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stage.done ? circleColor : Colors.transparent,
                    border: Border.all(color: circleColor, width: stage.done ? 0 : 2.2),
                  ),
                  child: stage.done
                      ? Icon(CupertinoIcons.check_mark, size: 14, color: Colors.white)
                      : (stage.active
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor,
                              ),
                            )
                          : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: TextStyle(
                      fontWeight: stage.done || stage.active ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  if (stage.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      stage.subtitle!,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
