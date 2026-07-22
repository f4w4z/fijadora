import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._();
  LocalCacheService._();

  static const _boxName = 'app_cache';
  static const _keyStorageKey = 'hive_encryption_key';
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<List<int>> _getOrCreateKey(String storageKey) async {
    final stored = await _secureStorage.read(key: storageKey);
    if (stored != null) {
      return base64.decode(stored);
    }
    final key = sha256.convert(_randomBytes(32)).bytes;
    await _secureStorage.write(key: storageKey, value: base64.encode(key));
    return key;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  Future<void> init({FlutterSecureStorage? secureStorage}) async {
    if (secureStorage != null) _secureStorage = secureStorage;
    final key = await _getOrCreateKey(_keyStorageKey);
    await Hive.openBox(_boxName, encryptionCipher: HiveAesCipher(key));
  }

  void put(String key, List<Map<String, dynamic>> data) {
    Hive.box(_boxName).put(key, data);
  }

  List<Map<String, dynamic>>? get(String key) {
    final data = Hive.box(_boxName).get(key);
    if (data == null) return null;
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> clear() async {
    await Hive.box(_boxName).clear();
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
