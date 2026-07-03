import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/property_occupant.dart';
import '../services/supabase_service.dart';

abstract class PropertyOccupantsRepository {
  Stream<List<PropertyOccupant>> streamByUser(String userId);
  Stream<List<PropertyOccupant>> streamByProperty(String propertyId);
  Future<void> addOccupant({
    required String propertyId,
    required String userId,
    String? unitId,
    String role = 'tenant',
  });
  Future<void> removeOccupant(String id);
  void dispose();
}

class SupabasePropertyOccupantsRepository implements PropertyOccupantsRepository {
  SupabasePropertyOccupantsRepository(this._client);

  final sb.SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _userSub;
  StreamSubscription<List<Map<String, dynamic>>>? _propertySub;
  final _userController = StreamController<List<PropertyOccupant>>.broadcast();
  final _propertyController = StreamController<List<PropertyOccupant>>.broadcast();

  @override
  Stream<List<PropertyOccupant>> streamByUser(String userId) {
    _userSub = _client
        .from('property_occupants')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          if (!_userController.isClosed) {
            _userController.add(data.map((json) => PropertyOccupant.fromJson(json)).toList());
          }
        }, onError: (e) {
          debugPrint('SupabasePropertyOccupantsRepository - streamByUser error: $e');
        });

    return _userController.stream;
  }

  @override
  Stream<List<PropertyOccupant>> streamByProperty(String propertyId) {
    _propertySub = _client
        .from('property_occupants')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .listen((data) {
          if (!_propertyController.isClosed) {
            _propertyController.add(data.map((json) => PropertyOccupant.fromJson(json)).toList());
          }
        }, onError: (e) {
          debugPrint('SupabasePropertyOccupantsRepository - streamByProperty error: $e');
        });

    return _propertyController.stream;
  }

  @override
  Future<void> addOccupant({
    required String propertyId,
    required String userId,
    String? unitId,
    String role = 'tenant',
  }) async {
    await _client.from('property_occupants').insert({
      'property_id': propertyId,
      'user_id': userId,
      'unit_id': unitId,
      'role': role,
    });
  }

  @override
  Future<void> removeOccupant(String id) async {
    await _client.from('property_occupants').delete().eq('id', id);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _propertySub?.cancel();
    _userController.close();
    _propertyController.close();
  }
}

final propertyOccupantsRepositoryProvider = Provider<PropertyOccupantsRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabasePropertyOccupantsRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});
