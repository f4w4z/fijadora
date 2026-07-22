import 'package:flutter/foundation.dart';

enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  failed;

  String get label => name[0].toUpperCase() + name.substring(1);
}

@immutable
class Delivery {
  final String id;
  final String orderId;
  final DeliveryStatus status;
  final String? assignedWorkerId;
  final String? trackingNote;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Delivery({
    required this.id,
    required this.orderId,
    required this.status,
    this.assignedWorkerId,
    this.trackingNote,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => DeliveryStatus.pending,
      ),
      assignedWorkerId: json['assigned_worker_id'] as String?,
      trackingNote: json['tracking_note'] as String?,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'status': status.name,
      'assigned_worker_id': assignedWorkerId,
      'tracking_note': trackingNote,
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
