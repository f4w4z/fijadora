import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'job_status.dart';
import 'trade_type.dart';

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
      createdAt: createdAt ?? this.createdAt,
    );
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
          scheduleDateTime == other.scheduleDateTime && // ignore: null_argument
          address == other.address &&
          listEquals(images, other.images) &&
          customerId == other.customerId &&
          workerId == other.workerId &&
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
      createdAt.hashCode;

  @override
  String toString() {
    return 'MaintenanceJob(id: $id, description: $description, tradeType: $tradeType, status: $status)';
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
