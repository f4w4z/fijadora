import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:phoebe_core/data/services/local_cache_service.dart';

class _TestModel {
  final String id;
  final String name;
  _TestModel({required this.id, required this.name});
  factory _TestModel.fromJson(Map<String, dynamic> json) => _TestModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    await LocalCacheService.instance.init();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('app_cache');
    tempDir.deleteSync(recursive: true);
  });

  group('LocalCacheService', () {
    test('put and get roundtrip', () {
      final data = [{'id': '1', 'name': 'test'}];
      LocalCacheService.instance.put('test_key', data);
      final result = LocalCacheService.instance.get('test_key');
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0]['id'], '1');
    });

    test('get returns null for missing key', () {
      final result = LocalCacheService.instance.get('nonexistent');
      expect(result, isNull);
    });

    test('put overwrites existing data', () {
      LocalCacheService.instance.put('key', [{'v': 1}]);
      LocalCacheService.instance.put('key', [{'v': 2}]);
      final result = LocalCacheService.instance.get('key');
      expect(result!.first['v'], 2);
    });
  });

  group('cacheStream', () {
    test('caches data on successful stream', () async {
      final controller = StreamController<List<_TestModel>>();
      final events = <List<_TestModel>>[];

      cacheStream(
        controller.stream,
        'cache_key',
        _TestModel.fromJson,
        (m) => m.toJson(),
      ).listen(events.add, onError: (_) {});

      controller.add([_TestModel(id: '1', name: 'cached')]);
      await Future(() {});
      await controller.close();

      expect(events.length, 1);
      expect(events[0].first.name, 'cached');
      final cached = LocalCacheService.instance.get('cache_key');
      expect(cached, isNotNull);
      expect(cached!.first['name'], 'cached');
    });

    test('serves cached data on stream error when cache exists', () async {
      final controller = StreamController<List<_TestModel>>();
      final events = <List<_TestModel>>[];

      // Seed cache
      LocalCacheService.instance.put('err_key', [
        {'id': 'cached-1', 'name': 'from cache'},
      ]);

      cacheStream(
        controller.stream,
        'err_key',
        _TestModel.fromJson,
        (m) => m.toJson(),
      ).listen(events.add, onError: (_) {});

      controller.addError(Exception('network error'));
      await Future(() {});

      expect(events.length, 1);
      expect(events[0].first.name, 'from cache');
    });

    test('propagates error when no cache exists', () async {
      final controller = StreamController<List<_TestModel>>();
      final errors = <Object>[];

      cacheStream(
        controller.stream,
        'missing_key',
        _TestModel.fromJson,
        (m) => m.toJson(),
      ).listen((_) {}, onError: errors.add);

      controller.addError(Exception('network error'));
      await Future(() {});

      expect(errors.length, 1);
    });
  });
}
