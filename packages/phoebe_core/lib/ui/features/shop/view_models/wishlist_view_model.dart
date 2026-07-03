import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';

final wishlistProvider = StreamProvider<List<String>>((ref) {
  final shopRepo = ref.watch(shopRepositoryProvider);
  return shopRepo.streamWishlist();
});

final wishlistedProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final wishlistAsync = ref.watch(wishlistProvider);

  return wishlistAsync.when(
    data: (ids) {
      return ref.watch(productsStreamProvider).when(
        data: (products) => AsyncValue.data(products.where((p) => ids.contains(p.id)).toList()),
        error: (e, st) => AsyncValue.error(e, st),
        loading: () => const AsyncValue.loading(),
      );
    },
    error: (e, st) => AsyncValue.error(e, st),
    loading: () => const AsyncValue.loading(),
  );
});

// Retry helper - silently reconnects when Supabase realtime disconnects
Stream<T> _retryOnError<T>(Stream<T> Function() factory) async* {
  while (true) {
    try {
      yield* factory();
      break;
    } catch (_) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

// Helper stream provider for all products
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(shopRepositoryProvider);
  return _retryOnError(() => repo.streamProducts());
});
