import 'package:flutter/foundation.dart';

enum CollectionItemType { product, service, note }

@immutable
class CollectionItem {
  final String id;
  final CollectionItemType itemType;
  final String? referenceId;
  final String label;
  final String? subtitle;
  final String? imageUrl;
  final String? noteContent;

  const CollectionItem({
    required this.id,
    required this.itemType,
    this.referenceId,
    required this.label,
    this.subtitle,
    this.imageUrl,
    this.noteContent,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      itemType: CollectionItemType.values.firstWhere(
        (e) => e.name == json['item_type'],
        orElse: () => CollectionItemType.note,
      ),
      referenceId: json['reference_id'] as String?,
      label: json['label'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      noteContent: json['note_content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_type': itemType.name,
    'reference_id': referenceId,
    'label': label,
    'subtitle': subtitle,
    'image_url': imageUrl,
    'note_content': noteContent,
  };

  CollectionItem copyWith({
    String? id,
    CollectionItemType? itemType,
    String? referenceId,
    String? label,
    String? subtitle,
    String? imageUrl,
    String? noteContent,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      itemType: itemType ?? this.itemType,
      referenceId: referenceId ?? this.referenceId,
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      noteContent: noteContent ?? this.noteContent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          itemType == other.itemType &&
          referenceId == other.referenceId &&
          label == other.label;

  @override
  int get hashCode =>
      id.hashCode ^ itemType.hashCode ^ referenceId.hashCode ^ label.hashCode;

  @override
  String toString() => 'CollectionItem(id: $id, type: $itemType, label: $label)';
}
