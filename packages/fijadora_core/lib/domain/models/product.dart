import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> imageUrls;
  final String category;
  final int inventoryCount;
  final bool isReserved;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.category,
    required this.inventoryCount,
    this.isReserved = false,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final primaryImage = json['image_url'] as String? ?? '';
    final rawUrls = json['image_urls'] as List<dynamic>?;
    final imageUrls = rawUrls != null
        ? rawUrls.where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[if (primaryImage.isNotEmpty) primaryImage];
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: primaryImage,
      imageUrls: imageUrls,
      category: json['category'] as String? ?? '',
      inventoryCount: json['inventory_count'] as int? ?? 0,
      isReserved: json['is_reserved'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'category': category,
      'inventory_count': inventoryCount,
      'is_reserved': isReserved,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? imageUrls,
    String? category,
    int? inventoryCount,
    bool? isReserved,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      inventoryCount: inventoryCount ?? this.inventoryCount,
      isReserved: isReserved ?? this.isReserved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          imageUrl == other.imageUrl &&
          category == other.category &&
          inventoryCount == other.inventoryCount &&
          isReserved == other.isReserved &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      category.hashCode ^
      inventoryCount.hashCode ^
      isReserved.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, price: $price, inventoryCount: $inventoryCount, isReserved: $isReserved)';
  }
}
