import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._();
  LocalCacheService._();

  static const _boxName = 'app_cache';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  void put(String key, List<Map<String, dynamic>> data) {
    Hive.box(_boxName).put(key, data);
  }

  List<Map<String, dynamic>>? get(String key) {
    final data = Hive.box(_boxName).get(key);
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }
}

Stream<List<T>> cacheStream<T>(
  Stream<List<T>> source,
  String cacheKey,
  T Function(Map<String, dynamic>) fromJson,
  Map<String, dynamic> Function(T) toJson,
) {
  final cache = LocalCacheService.instance;
  return source.transform(StreamTransformer<List<T>, List<T>>.fromHandlers(
    handleData: (data, sink) {
      cache.put(cacheKey, data.map(toJson).toList());
      sink.add(data);
    },
    handleError: (error, _, sink) {
      final cached = cache.get(cacheKey);
      if (cached != null) {
        sink.add(cached.map(fromJson).toList());
      } else {
        sink.addError(error);
      }
    },
  ));
}
