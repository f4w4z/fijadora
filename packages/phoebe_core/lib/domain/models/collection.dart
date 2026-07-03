import 'package:flutter/foundation.dart';
import 'collection_item.dart';

enum CollectionCategory {
  trending,
  kitchen,
  diy,
  seasonal,
  renovation,
  bathroom,
  bedroom,
  livingRoom,
  outdoor,
  energy,
  cleaning,
  organization;

  String get displayName {
    switch (this) {
      case CollectionCategory.trending:
        return 'Trending';
      case CollectionCategory.kitchen:
        return 'Kitchen';
      case CollectionCategory.diy:
        return 'DIY';
      case CollectionCategory.seasonal:
        return 'Seasonal';
      case CollectionCategory.renovation:
        return 'Renovation';
      case CollectionCategory.bathroom:
        return 'Bathroom';
      case CollectionCategory.bedroom:
        return 'Bedroom';
      case CollectionCategory.livingRoom:
        return 'Living Room';
      case CollectionCategory.outdoor:
        return 'Outdoor';
      case CollectionCategory.energy:
        return 'Energy';
      case CollectionCategory.cleaning:
        return 'Cleaning';
      case CollectionCategory.organization:
        return 'Organization';
    }
  }
}

@immutable
class Collection {
  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatarUrl;
  final CollectionCategory category;
  final bool isPublic;
  final bool isFeatured;
  final int featuredOrder;
  final DateTime createdAt;
  final List<CollectionItem> items;
  final int followerCount;
  final int likeCount;

  const Collection({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatarUrl,
    this.category = CollectionCategory.trending,
    this.isPublic = true,
    this.isFeatured = false,
    this.featuredOrder = 0,
    required this.createdAt,
    this.items = const [],
    this.followerCount = 0,
    this.likeCount = 0,
  });

  int get itemCount => items.length;

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      creatorId: json['creator_id'] as String? ?? '',
      creatorName: json['creator_name'] as String? ?? '',
      creatorAvatarUrl: json['creator_avatar_url'] as String?,
      category: CollectionCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CollectionCategory.trending,
      ),
      isPublic: json['is_public'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredOrder: json['featured_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CollectionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      followerCount: json['follower_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'cover_image_url': coverImageUrl,
    'creator_id': creatorId,
    'creator_name': creatorName,
    'creator_avatar_url': creatorAvatarUrl,
    'category': category.name,
    'is_public': isPublic,
    'is_featured': isFeatured,
    'featured_order': featuredOrder,
    'created_at': createdAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'follower_count': followerCount,
    'like_count': likeCount,
  };

  Collection copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    CollectionCategory? category,
    bool? isPublic,
    bool? isFeatured,
    int? featuredOrder,
    DateTime? createdAt,
    List<CollectionItem>? items,
    int? followerCount,
    int? likeCount,
  }) {
    return Collection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredOrder: featuredOrder ?? this.featuredOrder,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      followerCount: followerCount ?? this.followerCount,
      likeCount: likeCount ?? this.likeCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;

  @override
  String toString() => 'Collection(id: $id, title: $title, items: $itemCount)';
}
