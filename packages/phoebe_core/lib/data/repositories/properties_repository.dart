import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/property.dart';
import '../services/local_cache_service.dart';
import '../services/supabase_service.dart';

abstract class PropertiesRepository {
  Stream<List<Property>> streamProperties(String managerId);
  Future<Property?> fetchPropertyById(String id);
  Future<Property> createProperty(Property property);
  Future<Property> updateProperty(Property property);
  Future<void> deleteProperty(String id);
  Future<Unit> addUnit(String propertyId, String number);
  Future<void> deleteUnit(String propertyId, String unitId);
  Future<Room> addRoom(String propertyId, String unitId, String name);
  Future<PropertyAsset> addAsset(String propertyId, String roomId, String name, String type, String status);
  Future<PropertyAsset> updateAsset(String propertyId, String assetId, String name, String type, String status);
  Future<void> deleteAsset(String propertyId, String assetId);
  void dispose();
}

class SupabasePropertiesRepository implements PropertiesRepository {
  SupabasePropertiesRepository(this._client);

  final sb.SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final _controller = StreamController<List<Property>>.broadcast();

  @override
  Stream<List<Property>> streamProperties(String managerId) {
    final cacheKey = 'properties_$managerId';
    final cache = LocalCacheService.instance;
    _sub = _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('manager_id', managerId)
        .listen((data) async {
          try {
            final properties = await Future.wait(data.map((json) => _hydrateProperty(json)));
            cache.put(cacheKey, properties.map((p) => p.toJson()).toList());
            if (!_controller.isClosed) _controller.add(properties);
          } catch (e) {
            debugPrint('SupabasePropertiesRepository - hydrate error: $e');
          }
        }, onError: (e) {
          final cached = cache.get(cacheKey);
          if (cached != null) {
            final properties = cached.map((json) => Property.fromJson(json)).toList();
            if (!_controller.isClosed) _controller.add(properties);
          } else {
            debugPrint('SupabasePropertiesRepository - stream error: $e');
          }
        });

    return _controller.stream;
  }

  Future<Property> _hydrateProperty(Map<String, dynamic> json) async {
    final unitsData = await _client
        .from('units')
        .select()
        .eq('property_id', json['id'] as String);

    final units = await Future.wait(unitsData.map((uJson) => _hydrateUnit(uJson)));
    json['units'] = units.map((u) => u.toJson()).toList();
    return Property.fromJson(json);
  }

  Future<Unit> _hydrateUnit(Map<String, dynamic> json) async {
    final roomsData = await _client
        .from('rooms')
        .select()
        .eq('unit_id', json['id'] as String);

    final rooms = await Future.wait(roomsData.map((rJson) => _hydrateRoom(rJson)));
    json['rooms'] = rooms.map((r) => r.toJson()).toList();
    return Unit.fromJson(json);
  }

  Future<Room> _hydrateRoom(Map<String, dynamic> json) async {
    final assetsData = await _client
        .from('assets')
        .select()
        .eq('room_id', json['id'] as String);

    json['assets'] = assetsData;
    return Room.fromJson(json);
  }

  @override
  Future<Property?> fetchPropertyById(String id) async {
    try {
      final data = await _client
          .from('properties')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return _hydrateProperty(data);
    } catch (e) {
      debugPrint('SupabasePropertiesRepository - fetchPropertyById error: $e');
      return null;
    }
  }

  @override
  Future<Property> createProperty(Property property) async {
    final json = property.toJson();
    json.remove('id');
    json.remove('created_at');
    json.remove('units');
    final response = await _client.from('properties').insert(json).select().single();
    return _hydrateProperty(response);
  }

  @override
  Future<Property> updateProperty(Property property) async {
    final response = await _client.from('properties').update({
      'name': property.name,
      'address': property.address,
    }).eq('id', property.id).select().single();
    return _hydrateProperty(response);
  }

  @override
  Future<void> deleteProperty(String id) async {
    await _client.from('properties').delete().eq('id', id);
  }

  @override
  Future<Unit> addUnit(String propertyId, String number) async {
    final response = await _client.from('units').insert({
      'property_id': propertyId,
      'number': number,
    }).select().single();
    await _touchProperty(propertyId);
    return Unit.fromJson(response);
  }

  @override
  Future<void> deleteUnit(String propertyId, String unitId) async {
    await _client.from('units').delete().eq('id', unitId);
    await _touchProperty(propertyId);
  }

  @override
  Future<Room> addRoom(String propertyId, String unitId, String name) async {
    final response = await _client.from('rooms').insert({
      'unit_id': unitId,
      'name': name,
    }).select().single();
    await _touchProperty(propertyId);
    return Room.fromJson(response);
  }

  @override
  Future<PropertyAsset> addAsset(String propertyId, String roomId, String name, String type, String status) async {
    final response = await _client.from('assets').insert({
      'room_id': roomId,
      'name': name,
      'type': type,
      'status': status,
    }).select().single();
    await _touchProperty(propertyId);
    return PropertyAsset.fromJson(response);
  }

  @override
  Future<PropertyAsset> updateAsset(String propertyId, String assetId, String name, String type, String status) async {
    final response = await _client.from('assets').update({
      'name': name,
      'type': type,
      'status': status,
    }).eq('id', assetId).select().single();
    await _touchProperty(propertyId);
    return PropertyAsset.fromJson(response);
  }

  @override
  Future<void> deleteAsset(String propertyId, String assetId) async {
    await _client.from('assets').delete().eq('id', assetId);
    await _touchProperty(propertyId);
  }

  Future<void> _touchProperty(String propertyId) async {
    try {
      final res = await _client.from('properties').select('name').eq('id', propertyId).maybeSingle();
      if (res != null) {
        await _client.from('properties').update({'name': res['name'] as String}).eq('id', propertyId);
      }
    } catch (e) {
      debugPrint('SupabasePropertiesRepository - touchProperty error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

// 3. Riverpod Provider definition
final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabasePropertiesRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final propertiesStreamProvider = StreamProvider.family<List<Property>, String>((ref, userId) {
  final repo = ref.watch(propertiesRepositoryProvider);
  return repo.streamProperties(userId);
});
