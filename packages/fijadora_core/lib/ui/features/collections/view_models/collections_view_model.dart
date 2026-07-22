import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/collections_repository.dart';
import '../../../../domain/models/collection.dart';

class CollectionsViewModel extends ChangeNotifier {
  CollectionsViewModel(this._repository, this._authRepository) {
    _init();
  }

  final CollectionsRepository _repository;
  final AuthRepository _authRepository;

  StreamSubscription? _collectionsSub;

  List<Collection> _allCollections = [];
  List<Collection> get allCollections => _allCollections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? get _userId => _authRepository.currentUser?.id;

  void _init() {
    _isLoading = true;
    notifyListeners();
    _collectionsSub = _repository.streamCollections().listen((collections) {
      _allCollections = collections;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = 'Could not load collections.';
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _collectionsSub?.cancel();
    super.dispose();
  }

  Future<void> toggleFollow(String collectionId) async {
    final uid = _userId;
    if (uid == null) return;
    await _repository.toggleFollow(collectionId, uid);
  }

  Future<void> toggleLike(String collectionId) async {
    final uid = _userId;
    if (uid == null) return;
    await _repository.toggleLike(collectionId, uid);
  }
}

final collectionsViewModelProvider =
    ChangeNotifierProvider<CollectionsViewModel>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return CollectionsViewModel(repository, authRepository);
});

final featuredCollectionsProvider = StreamProvider<List<Collection>>((ref) {
  return ref.watch(collectionsRepositoryProvider).streamFeaturedCollections();
});
