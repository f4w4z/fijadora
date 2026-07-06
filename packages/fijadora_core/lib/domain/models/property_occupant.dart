import 'package:flutter/foundation.dart';

@immutable
class PropertyOccupant {
  final String id;
  final String propertyId;
  final String userId;
  final String? unitId;
  final String role;
  final DateTime createdAt;

  const PropertyOccupant({
    required this.id,
    required this.propertyId,
    required this.userId,
    this.unitId,
    this.role = 'tenant',
    required this.createdAt,
  });

  factory PropertyOccupant.fromJson(Map<String, dynamic> json) => PropertyOccupant(
    id: json['id'] as String,
    propertyId: json['property_id'] as String,
    userId: json['user_id'] as String,
    unitId: json['unit_id'] as String?,
    role: json['role'] as String? ?? 'tenant',
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'property_id': propertyId,
    'user_id': userId,
    if (unitId != null) 'unit_id': unitId,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };

  PropertyOccupant copyWith({
    String? id,
    String? propertyId,
    String? userId,
    String? unitId,
    String? role,
    DateTime? createdAt,
  }) => PropertyOccupant(
    id: id ?? this.id,
    propertyId: propertyId ?? this.propertyId,
    userId: userId ?? this.userId,
    unitId: unitId ?? this.unitId,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
}
