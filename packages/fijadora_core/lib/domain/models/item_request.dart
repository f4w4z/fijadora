import 'package:flutter/foundation.dart';

enum ItemRequestStatus {
  open,
  reviewing,
  fulfilled,
  rejected,
  closed;

  String get label => name[0].toUpperCase() + name.substring(1);
}

@immutable
class ItemRequest {
  final String id;
  final String customerId;
  final String title;
  final String description;
  final String? category;
  final String? imageUrl;
  final ItemRequestStatus status;
  final String? linkedProductId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemRequest({
    required this.id,
    required this.customerId,
    required this.title,
    required this.description,
    this.category,
    this.imageUrl,
    required this.status,
    this.linkedProductId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) {
    return ItemRequest(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      status: ItemRequestStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'open'),
        orElse: () => ItemRequestStatus.open,
      ),
      linkedProductId: json['linked_product_id'] as String?,
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
      'customer_id': customerId,
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'status': status.name,
      'linked_product_id': linkedProductId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
