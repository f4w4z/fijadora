import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/shop_repository.dart';
import '../../../../domain/models/product.dart';

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
