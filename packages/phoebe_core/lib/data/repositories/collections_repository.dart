import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/collection.dart';
import '../../domain/models/collection_item.dart';

abstract class CollectionsRepository {
  Stream<List<Collection>> streamCollections();
  Future<void> toggleFollow(String collectionId, String userId);
  Future<void> toggleLike(String collectionId, String userId);
  void dispose();
}

class MockCollectionsRepository implements CollectionsRepository {
  MockCollectionsRepository() {
    _populateMockCollections();
  }

  final _collectionsController = StreamController<List<Collection>>.broadcast();
  final List<Collection> _mockCollections = [];
  final Set<String> _followedIds = {};
  final Set<String> _likedIds = {};

  void _populateMockCollections() {
    _mockCollections.addAll([
      Collection(
        id: 'col-1',
        title: 'Kitchen Reno Essentials',
        description: 'Everything you need for a stunning kitchen renovation — from countertops to lighting.',
        coverImageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-2',
        creatorName: 'Alex Chen',
        creatorAvatarUrl: 'https://i.pravatar.cc/150?u=alex',
        category: CollectionCategory.kitchen,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        items: [
          const CollectionItem(id: 'ci-1', itemType: CollectionItemType.product, referenceId: 'prod-1', label: 'Noguchi Coffee Table', subtitle: '\$780', imageUrl: 'https://images.unsplash.com/photo-1581428982868-e410dd047a90?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-2', itemType: CollectionItemType.product, referenceId: 'prod-4', label: 'Flos Arco Floor Lamp', subtitle: '\$450', imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-3', itemType: CollectionItemType.service, referenceId: 'kitchenDesigns', label: 'Kitchen Design Service', subtitle: 'Professional layout & cabinetry'),
          const CollectionItem(id: 'ci-4', itemType: CollectionItemType.note, label: 'Tip: Measure twice', noteContent: 'Always confirm your cabinet dimensions before ordering countertops.'),
        ],
        followerCount: 248,
        likeCount: 312,
      ),
      Collection(
        id: 'col-2',
        title: 'Best Plumbers in Austin',
        description: 'Curated list of top-rated plumbing professionals verified by the community.',
        coverImageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-3',
        creatorName: 'Jamie Rivera',
        creatorAvatarUrl: 'https://i.pravatar.cc/150?u=jamie',
        category: CollectionCategory.renovation,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        items: [
          const CollectionItem(id: 'ci-5', itemType: CollectionItemType.service, referenceId: 'plumbing', label: 'Plumbing Service', subtitle: '⭐ 4.9 · Emergency available'),
          const CollectionItem(id: 'ci-6', itemType: CollectionItemType.service, referenceId: 'plumbing', label: 'Drain Masters', subtitle: '⭐ 4.8 · Same-day service'),
          const CollectionItem(id: 'ci-7', itemType: CollectionItemType.note, label: 'Tip: Check licenses', noteContent: 'Verify all plumbing licenses through the Texas State Board before hiring.'),
        ],
        followerCount: 89,
        likeCount: 134,
      ),
      Collection(
        id: 'col-3',
        title: 'Winter Home Prep',
        description: 'Get your home ready for the cold months with these essential checks and upgrades.',
        coverImageUrl: 'https://images.unsplash.com/photo-1517292987719-0369a794ec0f?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-4',
        creatorName: 'Priya Sharma',
        creatorAvatarUrl: 'https://i.pravatar.cc/150?u=priya',
        category: CollectionCategory.seasonal,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        items: [
          const CollectionItem(id: 'ci-8', itemType: CollectionItemType.product, referenceId: 'prod-4', label: 'Smart Thermostat', subtitle: '\$249', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-9', itemType: CollectionItemType.service, referenceId: 'acEngineering', label: 'HVAC Inspection', subtitle: 'Annual maintenance check'),
          const CollectionItem(id: 'ci-10', itemType: CollectionItemType.note, label: 'Checklist: Seal windows', noteContent: 'Use weatherstripping tape on drafty windows. Save up to 15% on heating bills.'),
        ],
        followerCount: 156,
        likeCount: 201,
      ),
      Collection(
        id: 'col-4',
        title: 'Bathroom Makeover Ideas',
        description: 'Inspiring bathroom transformations from minimal to spa-like luxury.',
        coverImageUrl: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-5',
        creatorName: 'Maya Johnson',
        category: CollectionCategory.bathroom,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        items: [
          const CollectionItem(id: 'ci-11', itemType: CollectionItemType.product, referenceId: 'prod-3', label: 'Minimalist Oak Vanity', subtitle: '\$1,200', imageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-12', itemType: CollectionItemType.service, referenceId: 'tiling', label: 'Custom Tiling', subtitle: 'Porcelain & ceramic specialists'),
          const CollectionItem(id: 'ci-13', itemType: CollectionItemType.note, label: 'Budget tip', noteContent: 'Keep plumbing in the same layout to save thousands on renovation costs.'),
        ],
        followerCount: 203,
        likeCount: 278,
      ),
      Collection(
        id: 'col-5',
        title: 'Energy Saving Tips',
        description: 'Reduce your utility bills with these community-tested energy efficiency hacks.',
        coverImageUrl: 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-6',
        creatorName: 'Tom Bradley',
        category: CollectionCategory.energy,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
        items: [
          const CollectionItem(id: 'ci-14', itemType: CollectionItemType.product, referenceId: 'prod-4', label: 'Smart Thermostat', subtitle: '\$249', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-15', itemType: CollectionItemType.note, label: 'LED swap', noteContent: 'Replace all bulbs with LEDs. Average saving: \$225/year.'),
          const CollectionItem(id: 'ci-16', itemType: CollectionItemType.note, label: 'Phantom loads', noteContent: 'Use smart power strips to cut standby power usage by 10%.'),
        ],
        followerCount: 312,
        likeCount: 445,
      ),
      Collection(
        id: 'col-6',
        title: 'Spring Cleaning Bootcamp',
        description: 'A room-by-room guide to deep cleaning your home this spring.',
        coverImageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&auto=format&fit=crop&q=80',
        creatorId: 'user-7',
        creatorName: 'Sarah Kim',
        category: CollectionCategory.cleaning,
        isPublic: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        items: [
          const CollectionItem(id: 'ci-17', itemType: CollectionItemType.service, referenceId: 'cleaning', label: 'Deep Clean Service', subtitle: 'Top-rated in your area'),
          const CollectionItem(id: 'ci-18', itemType: CollectionItemType.product, referenceId: 'prod-9', label: 'Industrial Shelving', subtitle: '\$1,450', imageUrl: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=200&auto=format&fit=crop&q=80'),
          const CollectionItem(id: 'ci-19', itemType: CollectionItemType.note, label: 'Schedule', noteContent: 'Start from the top floor and work down. Clean one room completely before moving on.'),
        ],
        followerCount: 178,
        likeCount: 223,
      ),
    ]);
  }

  void _notify() {
    _collectionsController.add(List<Collection>.from(_mockCollections));
  }

  @override
  Stream<List<Collection>> streamCollections() {
    Timer.run(() => _notify());
    return _collectionsController.stream;
  }

  @override
  Future<void> toggleFollow(String collectionId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _mockCollections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    if (_followedIds.contains(collectionId)) {
      _followedIds.remove(collectionId);
      _mockCollections[idx] = _mockCollections[idx].copyWith(
        followerCount: _mockCollections[idx].followerCount - 1,
      );
    } else {
      _followedIds.add(collectionId);
      _mockCollections[idx] = _mockCollections[idx].copyWith(
        followerCount: _mockCollections[idx].followerCount + 1,
      );
    }
    _notify();
  }

  @override
  Future<void> toggleLike(String collectionId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _mockCollections.indexWhere((c) => c.id == collectionId);
    if (idx == -1) return;
    if (_likedIds.contains(collectionId)) {
      _likedIds.remove(collectionId);
      _mockCollections[idx] = _mockCollections[idx].copyWith(
        likeCount: _mockCollections[idx].likeCount - 1,
      );
    } else {
      _likedIds.add(collectionId);
      _mockCollections[idx] = _mockCollections[idx].copyWith(
        likeCount: _mockCollections[idx].likeCount + 1,
      );
    }
    _notify();
  }

  @override
  void dispose() {
    _collectionsController.close();
  }
}

final collectionsRepositoryProvider = Provider<CollectionsRepository>((ref) {
  debugPrint('CollectionsRepository: Using MOCK implementation');
  final repo = MockCollectionsRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});
