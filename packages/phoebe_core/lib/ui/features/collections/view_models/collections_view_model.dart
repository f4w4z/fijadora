import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/collections_repository.dart';
import '../../../../domain/models/collection.dart';

class CollectionsViewModel extends ChangeNotifier {
  CollectionsViewModel(this._repository) {
    _init();
  }

  final CollectionsRepository _repository;

  List<Collection> _allCollections = [];
  List<Collection> get allCollections => _allCollections;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void _init() {
    _repository.streamCollections().listen((collections) {
      _allCollections = collections;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleFollow(String collectionId) async {
    await _repository.toggleFollow(collectionId, 'mock-user-id');
  }

  Future<void> toggleLike(String collectionId) async {
    await _repository.toggleLike(collectionId, 'mock-user-id');
  }
}

final collectionsViewModelProvider =
    ChangeNotifierProvider<CollectionsViewModel>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  return CollectionsViewModel(repository);
});
