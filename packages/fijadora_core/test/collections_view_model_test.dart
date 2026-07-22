import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/data/repositories/collections_repository.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/collection.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/collections/view_models/collections_view_model.dart';

class StubCollectionsRepository implements CollectionsRepository {
  final _controller = StreamController<List<Collection>>.broadcast();
  final List<String> followed = [];
  final List<String> liked = [];

  @override
  Stream<List<Collection>> streamCollections() => _controller.stream;

  void emit(List<Collection> collections) => _controller.add(collections);

  @override
  Stream<List<Collection>> streamFeaturedCollections() => const Stream.empty();

  @override
  Future<void> toggleFollow(String collectionId, String userId) async {
    if (followed.contains(collectionId)) {
      followed.remove(collectionId);
    } else {
      followed.add(collectionId);
    }
  }

  @override
  Future<void> toggleLike(String collectionId, String userId) async {
    if (liked.contains(collectionId)) {
      liked.remove(collectionId);
    } else {
      liked.add(collectionId);
    }
  }

  @override
  Future<Collection> createCollection(Collection collection) async => collection;
  @override
  Future<Collection> updateCollection(Collection collection) async => collection;
  @override
  Future<void> deleteCollection(String id) async {}
  @override
  Future<String> uploadCoverImage(String fileName, Uint8List fileBytes) async => '';
  @override
  Future<void> setFeatured(String collectionId, bool isFeatured) async {}
  @override
  void dispose() {}
}

class StubAuthRepository implements AuthRepository {
  AppUser? user;

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();
  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {}
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> resendEmailVerification({required String email}) async {}
  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
  @override
  Future<void> updatePassword({required String newPassword}) async {}
  @override
  Future<void> refreshUser() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  void dispose() {}
}

Collection _collection(String id) => Collection(
  id: id, title: 'Collection $id', description: '',
  creatorId: 'u1', creatorName: 'User', createdAt: DateTime(2026),
);

void main() {
  late StubCollectionsRepository stubRepo;
  late StubAuthRepository stubAuth;
  late CollectionsViewModel vm;

  setUp(() {
    stubRepo = StubCollectionsRepository();
    stubAuth = StubAuthRepository();
    vm = CollectionsViewModel(stubRepo, stubAuth);
  });

  tearDown(() {
    vm.dispose();
  });

  group('initial state', () {
    test('starts empty with no error', () {
      expect(vm.allCollections, isEmpty);
      expect(vm.isLoading, isTrue);
      expect(vm.error, isNull);
    });
  });

  group('stream collections', () {
    test('populates collections on stream emit', () async {
      stubRepo.emit([_collection('c1'), _collection('c2')]);
      await Future(() {});
      expect(vm.allCollections.length, 2);
      expect(vm.isLoading, isFalse);
    });

    test('replaces collections on re-emit', () async {
      stubRepo.emit([_collection('c1')]);
      await Future(() {});
      stubRepo.emit([_collection('c2'), _collection('c3')]);
      await Future(() {});
      expect(vm.allCollections.length, 2);
      expect(vm.allCollections.first.id, 'c2');
    });
  });

  group('toggleFollow', () {
    test('follows a collection', () async {
      stubAuth.user = AppUser(id: 'u1', email: 'a@b.com', name: 'A', role: UserRole.customer, createdAt: DateTime(2026));
      await vm.toggleFollow('c1');
      expect(stubRepo.followed, contains('c1'));
    });

    test('unfollows a collection', () async {
      stubAuth.user = AppUser(id: 'u1', email: 'a@b.com', name: 'A', role: UserRole.customer, createdAt: DateTime(2026));
      await vm.toggleFollow('c1');
      await vm.toggleFollow('c1');
      expect(stubRepo.followed, isEmpty);
    });

    test('does nothing when user is null', () async {
      stubAuth.user = null;
      await vm.toggleFollow('c1');
      expect(stubRepo.followed, isEmpty);
    });
  });

  group('toggleLike', () {
    test('likes a collection', () async {
      stubAuth.user = AppUser(id: 'u1', email: 'a@b.com', name: 'A', role: UserRole.customer, createdAt: DateTime(2026));
      await vm.toggleLike('c1');
      expect(stubRepo.liked, contains('c1'));
    });

    test('unlikes a collection', () async {
      stubAuth.user = AppUser(id: 'u1', email: 'a@b.com', name: 'A', role: UserRole.customer, createdAt: DateTime(2026));
      await vm.toggleLike('c1');
      await vm.toggleLike('c1');
      expect(stubRepo.liked, isEmpty);
    });
  });
}
