import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'job_status.dart';
import 'trade_type.dart';

enum JobPaymentStatus {
  none,
  depositPaid,
  balanceDue,
  paid;

  static JobPaymentStatus fromString(String? value) {
    return JobPaymentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? 'none').toLowerCase().replaceAll('_', ''),
      orElse: () => JobPaymentStatus.none,
    );
  }
}

@immutable
class JobChangeOrder {
  final String id;
  final String description;
  final double amount;
  final String status; // pending | approved | paid
  final DateTime createdAt;

  const JobChangeOrder({
    required this.id,
    required this.description,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory JobChangeOrder.fromJson(Map<String, dynamic> json) {
    return JobChangeOrder(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class MaintenanceJob {
  final String id;
  final String description;
  final TradeType tradeType;
  final JobStatus status;
  final DateTime? scheduleDateTime;
  final String address;
  final List<String> images;
  final String customerId;
  final String? workerId;
  final String? assetId;
  final String contactPhone;
  final String accessNotes;
  final double? quoteAmount;
  final double? depositAmount;
  final double? maxAmount;
  final List<JobChangeOrder> changeOrders;
  final double? finalAmount;
  final JobPaymentStatus paymentStatus;
  final DateTime createdAt;

  const MaintenanceJob({
    required this.id,
    required this.description,
    required this.tradeType,
    required this.status,
    this.scheduleDateTime,
    required this.address,
    required this.images,
    required this.customerId,
    this.workerId,
    this.assetId,
    this.contactPhone = '',
    this.accessNotes = '',
    this.quoteAmount,
    this.depositAmount,
    this.maxAmount,
    this.changeOrders = const [],
    this.finalAmount,
    this.paymentStatus = JobPaymentStatus.none,
    required this.createdAt,
  });

  factory MaintenanceJob.fromJson(Map<String, dynamic> json) {
    return MaintenanceJob(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      tradeType: TradeType.fromString(json['trade_type'] as String?),
      status: JobStatus.fromString(json['status'] as String?),
      scheduleDateTime: json['schedule_date_time'] != null ? DateTime.parse(json['schedule_date_time'] as String) : null,
      address: json['address'] as String? ?? '',
      images: _parseImages(json['images']),
      customerId: json['customer_id'] as String? ?? '',
      workerId: json['worker_id'] as String?,
      assetId: json['asset_id'] as String?,
      contactPhone: json['contact_phone'] as String? ?? '',
      accessNotes: json['access_notes'] as String? ?? '',
      quoteAmount: (json['quote_amount'] as num?)?.toDouble(),
      depositAmount: (json['deposit_amount'] as num?)?.toDouble(),
      maxAmount: (json['max_amount'] as num?)?.toDouble(),
      changeOrders: _parseChangeOrders(json['change_orders']),
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      paymentStatus: JobPaymentStatus.fromString(json['payment_status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'trade_type': tradeType.name,
      'status': status.name,
      'schedule_date_time': scheduleDateTime?.toIso8601String(),
      'address': address,
      'images': images,
      'customer_id': customerId,
      'worker_id': workerId,
      'asset_id': assetId,
      'contact_phone': contactPhone,
      'access_notes': accessNotes,
      'quote_amount': quoteAmount,
      'deposit_amount': depositAmount,
      'max_amount': maxAmount,
      'change_orders': changeOrders.map((c) => c.toJson()).toList(),
      'final_amount': finalAmount,
      'payment_status': paymentStatus.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MaintenanceJob copyWith({
    String? id,
    String? description,
    TradeType? tradeType,
    JobStatus? status,
    DateTime? scheduleDateTime,
    String? address,
    List<String>? images,
    String? customerId,
    String? workerId,
    String? assetId,
    String? contactPhone,
    String? accessNotes,
    double? quoteAmount,
    double? depositAmount,
    double? maxAmount,
    List<JobChangeOrder>? changeOrders,
    double? finalAmount,
    JobPaymentStatus? paymentStatus,
    DateTime? createdAt,
  }) {
    return MaintenanceJob(
      id: id ?? this.id,
      description: description ?? this.description,
      tradeType: tradeType ?? this.tradeType,
      status: status ?? this.status,
      scheduleDateTime: scheduleDateTime ?? this.scheduleDateTime,
      address: address ?? this.address,
      images: images ?? this.images,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      assetId: assetId ?? this.assetId,
      contactPhone: contactPhone ?? this.contactPhone,
      accessNotes: accessNotes ?? this.accessNotes,
      quoteAmount: quoteAmount ?? this.quoteAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      changeOrders: changeOrders ?? this.changeOrders,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get balanceDue {
    final total = finalAmount ?? quoteAmount ?? 0;
    return (total - (depositAmount ?? 0)).clamp(0, double.infinity).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceJob &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          description == other.description &&
          tradeType == other.tradeType &&
          status == other.status &&
          scheduleDateTime == other.scheduleDateTime &&
          address == other.address &&
          listEquals(images, other.images) &&
          customerId == other.customerId &&
          workerId == other.workerId &&
          contactPhone == other.contactPhone &&
          accessNotes == other.accessNotes &&
          quoteAmount == other.quoteAmount &&
          depositAmount == other.depositAmount &&
          maxAmount == other.maxAmount &&
          listEquals(changeOrders, other.changeOrders) &&
          finalAmount == other.finalAmount &&
          paymentStatus == other.paymentStatus &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      description.hashCode ^
      tradeType.hashCode ^
      status.hashCode ^
      scheduleDateTime.hashCode ^
      address.hashCode ^
      images.hashCode ^
      customerId.hashCode ^
      workerId.hashCode ^
      contactPhone.hashCode ^
      accessNotes.hashCode ^
      quoteAmount.hashCode ^
      depositAmount.hashCode ^
      maxAmount.hashCode ^
      changeOrders.hashCode ^
      finalAmount.hashCode ^
      paymentStatus.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'MaintenanceJob(id: $id, description: $description, tradeType: $tradeType, status: $status, contactPhone: $contactPhone)';
  }
}

List<String> _parseImages(dynamic value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) {
    try {
      final parsed = jsonDecode(value);
      if (parsed is List) return parsed.map((e) => e.toString()).toList();
    } catch (_) {}
  }
  return const [];
}

List<JobChangeOrder> _parseChangeOrders(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(JobChangeOrder.fromJson)
        .toList();
  }
  if (value is String) {
    try {
      final parsed = jsonDecode(value);
      if (parsed is List) {
        return parsed
            .whereType<Map<String, dynamic>>()
            .map(JobChangeOrder.fromJson)
            .toList();
      }
    } catch (_) {}
  }
  return const [];
}
