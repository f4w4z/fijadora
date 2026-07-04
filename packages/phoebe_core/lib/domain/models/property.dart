import 'package:flutter/foundation.dart';

@immutable
class PropertyAsset {
  final String id;
  final String name;
  final String type;
  final String status;

  const PropertyAsset({
    required this.id,
    required this.name,
    this.type = '',
    this.status = 'Healthy',
  });

  factory PropertyAsset.fromJson(Map<String, dynamic> json) => PropertyAsset(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    type: json['type'] as String? ?? '',
    status: json['status'] as String? ?? 'Healthy',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type, 'status': status,
  };

  PropertyAsset copyWith({String? id, String? name, String? type, String? status}) => PropertyAsset(
    id: id ?? this.id, name: name ?? this.name, type: type ?? this.type, status: status ?? this.status,
  );
}

@immutable
class Room {
  final String id;
  final String name;
  final List<PropertyAsset> assets;

  const Room({required this.id, required this.name, this.assets = const []});

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    assets: (json['assets'] as List<dynamic>?)
        ?.map((e) => PropertyAsset.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'assets': assets.map((e) => e.toJson()).toList(),
  };
}

@immutable
class Unit {
  final String id;
  final String number;
  final List<Room> rooms;

  const Unit({required this.id, required this.number, this.rooms = const []});

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json['id'] as String,
    number: json['number'] as String? ?? '',
    rooms: (json['rooms'] as List<dynamic>?)
        ?.map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'number': number, 'rooms': rooms.map((e) => e.toJson()).toList(),
  };
}

@immutable
class Property {
  final String id;
  final String name;
  final String address;
  final String managerId;
  final DateTime createdAt;
  final List<Unit> units;

  const Property({
    required this.id,
    required this.name,
    this.address = '',
    required this.managerId,
    required this.createdAt,
    this.units = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    managerId: json['manager_id'] as String? ?? '',
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    units: (json['units'] as List<dynamic>?)
        ?.map((e) => Unit.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'address': address,
    'manager_id': managerId,
    'created_at': createdAt.toIso8601String(),
    'units': units.map((e) => e.toJson()).toList(),
  };
}
