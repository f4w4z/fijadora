import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/domain/models/property.dart';

void main() {
  group('PropertyAsset', () {
    test('fromJson/toJson roundtrip', () {
      final json = {'id': 'a1', 'name': 'HVAC Unit', 'type': 'hvac', 'status': 'Needs Repair'};
      final asset = PropertyAsset.fromJson(json);
      expect(asset.id, 'a1');
      expect(asset.name, 'HVAC Unit');
      expect(asset.type, 'hvac');
      expect(asset.status, 'Needs Repair');

      final output = asset.toJson();
      expect(output['name'], 'HVAC Unit');
      expect(output['status'], 'Needs Repair');
    });

    test('fromJson handles missing fields', () {
      final json = {'id': 'a2'};
      final asset = PropertyAsset.fromJson(json);
      expect(asset.name, '');
      expect(asset.type, '');
      expect(asset.status, 'Healthy');
    });

    test('copyWith overrides specified fields', () {
      final a = const PropertyAsset(id: 'a1', name: 'Old', type: 'hvac', status: 'Healthy');
      final b = a.copyWith(name: 'New', status: 'Broken');
      expect(b.id, 'a1');
      expect(b.name, 'New');
      expect(b.status, 'Broken');
      expect(b.type, 'hvac');
    });
  });

  group('Room', () {
    test('fromJson/toJson roundtrip with assets', () {
      final json = {
        'id': 'r1', 'name': 'Living Room',
        'assets': [
          {'id': 'a1', 'name': 'Light', 'type': 'lighting', 'status': 'Healthy'},
        ],
      };
      final room = Room.fromJson(json);
      expect(room.id, 'r1');
      expect(room.name, 'Living Room');
      expect(room.assets.length, 1);
      expect(room.assets.first.name, 'Light');

      final output = room.toJson();
      expect(output['assets'].length, 1);
    });

    test('fromJson handles missing assets', () {
      final json = {'id': 'r2', 'name': 'Empty'};
      final room = Room.fromJson(json);
      expect(room.assets, isEmpty);
    });
  });

  group('Unit', () {
    test('fromJson/toJson roundtrip with rooms', () {
      final json = {
        'id': 'u1', 'number': '101',
        'rooms': [
          {'id': 'r1', 'name': 'Bedroom', 'assets': []},
        ],
      };
      final unit = Unit.fromJson(json);
      expect(unit.number, '101');
      expect(unit.rooms.length, 1);

      final output = unit.toJson();
      expect(output['rooms'].length, 1);
    });

    test('fromJson handles missing rooms', () {
      final json = {'id': 'u2', 'number': '102'};
      final unit = Unit.fromJson(json);
      expect(unit.rooms, isEmpty);
    });
  });

  group('Property', () {
    test('fromJson/toJson roundtrip with full hierarchy', () {
      final json = {
        'id': 'p1',
        'name': 'Test Property',
        'address': '123 Main St',
        'manager_id': 'm1',
        'created_at': '2026-06-01T12:00:00.000Z',
        'units': [
          {
            'id': 'u1', 'number': 'Apt 1',
            'rooms': [
              {'id': 'r1', 'name': 'Kitchen', 'assets': [
                {'id': 'a1', 'name': 'Sink', 'type': 'plumbing', 'status': 'Healthy'},
              ]},
            ],
          },
        ],
      };
      final property = Property.fromJson(json);
      expect(property.id, 'p1');
      expect(property.name, 'Test Property');
      expect(property.units.length, 1);
      expect(property.units.first.rooms.first.assets.first.name, 'Sink');

      final output = property.toJson();
      expect(output['units'].length, 1);
      expect(output['units'][0]['rooms'][0]['assets'][0]['name'], 'Sink');
    });

    test('fromJson handles missing units', () {
      final json = {
        'id': 'p2', 'name': 'Empty', 'manager_id': 'm1',
        'created_at': '2026-06-01T12:00:00.000Z',
      };
      final property = Property.fromJson(json);
      expect(property.units, isEmpty);
    });

    test('fromJson handles missing fields', () {
      final json = {'id': 'p3', 'name': 'Minimal', 'manager_id': 'm1', 'created_at': null};
      final property = Property.fromJson(json);
      expect(property.address, '');
      expect(property.createdAt, isNotNull); // falls back to now
    });
  });
}
