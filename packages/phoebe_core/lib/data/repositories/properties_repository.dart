import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/property.dart';
import '../services/supabase_service.dart';

abstract class PropertiesRepository {
  Stream<List<Property>> streamProperties(String managerId);
  Future<Property?> fetchPropertyById(String id);
  void dispose();
}

class SupabasePropertiesRepository implements PropertiesRepository {
  SupabasePropertiesRepository(this._client);

  final sb.SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final _controller = StreamController<List<Property>>.broadcast();

  @override
  Stream<List<Property>> streamProperties(String managerId) {
    _sub = _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('manager_id', managerId)
        .listen((data) async {
          try {
            final properties = await Future.wait(data.map((json) => _hydrateProperty(json)));
            if (!_controller.isClosed) _controller.add(properties);
          } catch (e) {
            debugPrint('SupabasePropertiesRepository - hydrate error: $e');
          }
        }, onError: (e) {
          debugPrint('SupabasePropertiesRepository - stream error: $e');
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
