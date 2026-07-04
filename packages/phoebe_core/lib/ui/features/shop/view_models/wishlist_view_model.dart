import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';
import 'products_provider.dart';

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


