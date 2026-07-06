import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/job_status.dart';
import 'package:fijadora_core/domain/models/maintenance_job.dart';
import 'package:fijadora_core/domain/models/product.dart';
import 'package:fijadora_core/domain/models/trade_type.dart';
import 'package:fijadora_core/domain/models/user_role.dart';

void main() {
  group('AppUser', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'test-id',
        'email': 'test@test.com',
        'name': 'Test User',
        'role': 'worker',
        'worker_status': 'pending',
        'created_at': '2026-06-01T12:00:00.000Z',
      };
      final user = AppUser.fromJson(json);
      expect(user.id, 'test-id');
      expect(user.email, 'test@test.com');
      expect(user.name, 'Test User');
      expect(user.role, UserRole.worker);
      expect(user.workerStatus, 'pending');

      final output = user.toJson();
      expect(output['id'], 'test-id');
      expect(output['email'], 'test@test.com');
      expect(output['role'], 'worker');
      expect(output['worker_status'], 'pending');
    });

    test('fromJson handles missing fields gracefully', () {
      final json = {
        'id': 'test-id',
        'email': 'test@test.com',
        'name': 'Test',
        'role': null,
      };
      final user = AppUser.fromJson(json);
      expect(user.role, UserRole.customer); // default
      expect(user.workerStatus, isNull);
    });

    test('copyWith preserves fields', () {
      final user = AppUser(
        id: '1', email: 'a@b.com', name: 'A', role: UserRole.customer, createdAt: DateTime(2026),
      );
      final updated = user.copyWith(role: UserRole.admin);
      expect(updated.id, '1');
      expect(updated.role, UserRole.admin);
      expect(updated.name, 'A'); // unchanged
    });
  });

  group('JobStatus', () {
    test('all 13 values exist', () {
      expect(JobStatus.values.length, 13);
    });

    test('fromString works for all values', () {
      for (final status in JobStatus.values) {
        expect(JobStatus.fromString(status.name), status);
      }
    });

    test('fromString returns pending for unknown', () {
      expect(JobStatus.fromString('nonexistent'), JobStatus.pending);
    });
  });

  group('MaintenanceJob', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'job-1',
        'description': 'Test job',
        'trade_type': 'plumbing',
        'status': 'assigned',
        'schedule_date_time': '2026-06-16T14:00:00.000Z',
        'address': '123 Test St',
        'images': '["img1.jpg","img2.jpg"]',
        'customer_id': 'cust-1',
        'worker_id': 'worker-1',
        'created_at': '2026-06-15T10:30:00.000Z',
      };
      final job = MaintenanceJob.fromJson(json);
      expect(job.id, 'job-1');
      expect(job.tradeType, TradeType.plumbing);
      expect(job.status, JobStatus.assigned);
      expect(job.workerId, 'worker-1');

      final output = job.toJson();
      expect(output['id'], 'job-1');
      expect(output['trade_type'], 'plumbing');
      expect(output['worker_id'], 'worker-1');
    });

    test('supports nullable scheduleDateTime', () {
      final json = {
        'id': 'job-2',
        'description': 'No schedule',
        'trade_type': 'electrical',
        'status': 'pending',
        'address': '',
        'images': '[]',
        'customer_id': 'cust-1',
        'created_at': '2026-06-15T10:30:00.000Z',
      };
      final job = MaintenanceJob.fromJson(json);
      expect(job.scheduleDateTime, isNull);

      final output = job.toJson();
      expect(output['schedule_date_time'], isNull);
    });
  });

  group('Product', () {
    test('fromJson/toJson roundtrip', () {
      final json = {
        'id': 'prod-1',
        'name': 'Test Product',
        'description': 'A test product',
        'price': 99.99,
        'image_url': 'https://example.com/img.jpg',
        'image_urls': ['https://example.com/img.jpg', 'https://example.com/img2.jpg'],
        'category': 'Decor',
        'inventory_count': 10,
        'is_reserved': false,
        'created_at': '2026-06-01T12:00:00.000Z',
      };
      final product = Product.fromJson(json);
      expect(product.name, 'Test Product');
      expect(product.price, 99.99);
      expect(product.imageUrls.length, 2);

      final output = product.toJson();
      expect(output['name'], 'Test Product');
      expect(output['category'], 'Decor');
    });

    test('handles null image_urls', () {
      final json = {
        'id': 'prod-2',
        'name': 'No Gallery',
        'description': '',
        'price': 0,
        'image_url': 'https://example.com/img.jpg',
        'image_urls': null,
        'category': '',
        'inventory_count': 0,
        'is_reserved': false,
        'created_at': '2026-06-01T12:00:00.000Z',
      };
      final product = Product.fromJson(json);
      expect(product.imageUrls, ['https://example.com/img.jpg']); // fallback
    });
  });
}
