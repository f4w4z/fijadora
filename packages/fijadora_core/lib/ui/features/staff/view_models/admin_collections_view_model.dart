import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/collections_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../data/services/telemetry_service.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';

class AdminCollectionsViewModel extends ChangeNotifier {
  AdminCollectionsViewModel({
    required this.collectionsRepository,
    required this.notificationService,
    required this.telemetryService,
  });

  final CollectionsRepository collectionsRepository;
  final NotificationService notificationService;
  final TelemetryService telemetryService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<Collection> createCollection({
    required String title,
    required String description,
    String? coverImageUrl,
    required String creatorId,
    required String creatorName,
    String? creatorAvatarUrl,
    CollectionCategory category = CollectionCategory.trending,
    bool isPublic = true,
    List<CollectionItem> items = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collection = Collection(
        id: '',
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorAvatarUrl: creatorAvatarUrl,
        category: category,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        items: items,
      );

      final created = await collectionsRepository.createCollection(collection);
      telemetryService.logEvent('admin_create_look', {
        'title': title,
        'category': category.name,
      });
      notificationService.sendNotification(
        title: 'Look Created',
        body: 'Look "$title" has been successfully created.',
      );
      return created;
    } catch (e) {
      _errorMessage = 'Could not create look.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Collection> editCollection({
    required Collection existingCollection,
    required String title,
    required String description,
    String? coverImageUrl,
    CollectionCategory category = CollectionCategory.trending,
    bool isPublic = true,
    List<CollectionItem> items = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final collection = existingCollection.copyWith(
        title: title,
        description: description,
        coverImageUrl: coverImageUrl,
        category: category,
        isPublic: isPublic,
        items: items,
      );

      final updated = await collectionsRepository.updateCollection(collection);
      telemetryService.logEvent('admin_edit_look', {
        'collection_id': existingCollection.id,
        'title': title,
      });
      notificationService.sendNotification(
        title: 'Look Updated',
        body: 'Look "$title" has been successfully updated.',
      );
      return updated;
    } catch (e) {
      _errorMessage = 'Could not update look.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCollection(String id, String title) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await collectionsRepository.deleteCollection(id);
      telemetryService.logEvent('admin_delete_look', {
        'collection_id': id,
        'title': title,
      });
      notificationService.sendNotification(
        title: 'Look Removed',
        body: 'Look "$title" has been successfully removed.',
      );
    } catch (e) {
      _errorMessage = 'Could not remove look.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadCoverImage(String fileName, Uint8List fileBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await collectionsRepository.uploadCoverImage(fileName, fileBytes);
      return url;
    } catch (e) {
      _errorMessage = 'Could not upload cover image.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final adminCollectionsViewModelProvider = ChangeNotifierProvider<AdminCollectionsViewModel>((ref) {
  final repository = ref.watch(collectionsRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);

  return AdminCollectionsViewModel(
    collectionsRepository: repository,
    notificationService: notificationService,
    telemetryService: telemetryService,
  );
});
