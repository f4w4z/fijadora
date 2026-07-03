import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/property.dart';
import '../services/supabase_service.dart';

abstract class PropertiesRepository {
  Stream<List<Property>> streamProperties(String managerId);
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
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

class MockPropertiesRepository implements PropertiesRepository {
  final _controller = StreamController<List<Property>>.broadcast();

  @override
  Stream<List<Property>> streamProperties(String managerId) {
    final props = [
      Property(
        id: 'prop-1',
        name: 'Greenwood Apartments',
        address: '742 Evergreen Terrace, Springfield',
        managerId: managerId,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        units: [
          Unit(id: 'unit-1', number: '302', rooms: [
            Room(id: 'room-1', name: 'Kitchen', assets: [
              const Asset(id: 'asset-1', name: 'Bosch Dishwasher', type: 'Appliance', status: 'Healthy'),
              const Asset(id: 'asset-2', name: 'Samsung Refrigerator', type: 'Appliance', status: 'Healthy'),
            ]),
            Room(id: 'room-2', name: 'Living Room', assets: [
              const Asset(id: 'asset-3', name: 'Noguchi Coffee Table', type: 'Furniture', status: 'Good Condition'),
              const Asset(id: 'asset-4', name: 'Carrier AC Unit', type: 'Appliance', status: 'Needs Service'),
            ]),
          ]),
          Unit(id: 'unit-2', number: '304', rooms: [
            Room(id: 'room-3', name: 'Kitchen', assets: [
              const Asset(id: 'asset-5', name: 'Kitchen Sink Washer', type: 'Plumbing', status: 'Leaking'),
            ]),
          ]),
        ],
      ),
      Property(
        id: 'prop-2',
        name: 'Oakwood Heights',
        address: 'Apartment 4B, Oakwood Heights, NY',
        managerId: managerId,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        units: [
          Unit(id: 'unit-3', number: '4B', rooms: [
            Room(id: 'room-4', name: 'Kitchen', assets: [
              const Asset(id: 'asset-6', name: 'Kitchen Sink Pipe', type: 'Plumbing', status: 'Repaired'),
            ]),
            Room(id: 'room-5', name: 'Living Room', assets: [
              const Asset(id: 'asset-7', name: 'Ceiling Light Switch', type: 'Electrical', status: 'Flickering'),
            ]),
          ]),
        ],
      ),
    ];

    Timer.run(() => _controller.add(props));
    return _controller.stream;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

final propertiesRepositoryProvider = Provider<PropertiesRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  PropertiesRepository repo;
  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('PropertiesRepository: Using MOCK implementation');
    repo = MockPropertiesRepository();
  } else {
    try {
      final client = SupabaseService.instance.client;
      repo = SupabasePropertiesRepository(client);
    } catch (e) {
      debugPrint('PropertiesRepository: Failed to get Supabase client. Falling back to MOCK.');
      repo = MockPropertiesRepository();
    }
  }

  ref.onDispose(() => repo.dispose());
  return repo;
});
