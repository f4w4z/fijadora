import 'package:flutter_test/flutter_test.dart';
import 'package:phoebe_core/domain/models/collection.dart';
import 'package:phoebe_core/domain/models/collection_item.dart';

void main() {
  group('CollectionItem', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'item-1',
        'item_type': 'product',
        'reference_id': 'prod-1',
        'label': 'Test Item',
        'subtitle': 'A subtitle',
        'image_url': 'https://example.com/img.jpg',
        'note_content': null,
      };
      final item = CollectionItem.fromJson(json);
      expect(item.id, 'item-1');
      expect(item.itemType, CollectionItemType.product);
      expect(item.label, 'Test Item');
      expect(item.subtitle, 'A subtitle');

      final output = item.toJson();
      expect(output['id'], 'item-1');
      expect(output['item_type'], 'product');
      expect(output['reference_id'], 'prod-1');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = {
        'id': 'item-2',
        'item_type': 'unknown_type',
        'label': 'Fallback',
      };
      final item = CollectionItem.fromJson(json);
      expect(item.itemType, CollectionItemType.note);
      expect(item.referenceId, isNull);
      expect(item.subtitle, isNull);
    });
  });

  group('Collection', () {
    test('fromJson/toJson roundtrip with items', () {
      final json = {
        'id': 'col-1',
        'title': 'My Collection',
        'description': 'A test collection',
        'cover_image_url': 'https://example.com/cover.jpg',
        'creator_id': 'user-1',
        'creator_name': 'Test User',
        'creator_avatar_url': null,
        'category': 'trending',
        'is_public': true,
        'is_featured': true,
        'featured_order': 42,
        'created_at': '2026-06-01T12:00:00.000Z',
        'items': [
          {'id': 'item-1', 'item_type': 'product', 'label': 'Item 1', 'reference_id': 'prod-1'},
          {'id': 'item-2', 'item_type': 'service', 'label': 'Item 2', 'reference_id': 'serv-1'},
        ],
        'follower_count': 10,
        'like_count': 5,
        'is_edited': false,
      };
      final collection = Collection.fromJson(json);
      expect(collection.id, 'col-1');
      expect(collection.title, 'My Collection');
      expect(collection.category, CollectionCategory.trending);
      expect(collection.isFeatured, true);
      expect(collection.featuredOrder, 42);
      expect(collection.items.length, 2);
      expect(collection.followerCount, 10);
      expect(collection.likeCount, 5);

      final output = collection.toJson();
      expect(output['title'], 'My Collection');
      expect(output['category'], 'trending');
      expect(output['items'].length, 2);
      expect(output['follower_count'], 10);
    });

    test('fromJson handles missing items', () {
      final json = {
        'id': 'col-2',
        'title': 'Empty',
        'description': '',
        'creator_id': 'user-1',
        'creator_name': 'Test',
        'created_at': '2026-06-01T12:00:00.000Z',
      };
      final collection = Collection.fromJson(json);
      expect(collection.items, isEmpty);
      expect(collection.itemCount, 0);
    });

    test('itemCount returns items length', () {
      final collection = Collection(
        id: 'col-3',
        title: 'Test',
        description: '',
        creatorId: 'user-1',
        creatorName: 'Test',
        createdAt: DateTime(2026),
        items: [
          const CollectionItem(id: 'i1', itemType: CollectionItemType.product, label: 'A'),
          const CollectionItem(id: 'i2', itemType: CollectionItemType.service, label: 'B'),
        ],
      );
      expect(collection.itemCount, 2);
    });

    test('copyWith preserves unset fields and overrides set ones', () {
      final original = Collection(
        id: 'col-1',
        title: 'Original',
        description: 'Desc',
        creatorId: 'u1',
        creatorName: 'User',
        createdAt: DateTime(2026),
      );
      final updated = original.copyWith(title: 'Updated', featuredOrder: 99);
      expect(updated.id, 'col-1');
      expect(updated.title, 'Updated');
      expect(updated.description, 'Desc');
      expect(updated.featuredOrder, 99);
    });

    test('equality based on id and title', () {
      final a = Collection(id: '1', title: 'Same', description: '', creatorId: 'u1', creatorName: 'U', createdAt: DateTime(2026));
      final b = Collection(id: '1', title: 'Same', description: 'Different desc', creatorId: 'u1', creatorName: 'U', createdAt: DateTime(2026));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('CollectionCategory', () {
    test('all values have display names', () {
      for (final cat in CollectionCategory.values) {
        expect(cat.displayName, isNotEmpty);
      }
    });
  });
}
