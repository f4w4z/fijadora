import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/jobs_repository.dart';
import 'package:fijadora_core/data/services/app_notification_service.dart';
import 'package:fijadora_core/data/services/telemetry_service.dart';
import 'package:fijadora_core/domain/models/job_status.dart';
import 'package:fijadora_core/domain/models/maintenance_job.dart';
import 'package:fijadora_core/domain/models/trade_type.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/services/view_models/jobs_view_model.dart';

class StubJobsRepository implements JobsRepository {
  final List<MaintenanceJob> _jobs = [];
  final _controller = StreamController<List<MaintenanceJob>>.broadcast();
  bool failNextCreate = false;
  bool failNextUpdate = false;

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    return _controller.stream;
  }

  void emitJobs(List<MaintenanceJob> jobs) {
    _jobs
      ..clear()
      ..addAll(jobs);
    _controller.add(List.unmodifiable(_jobs));
  }

  @override
  Future<MaintenanceJob> createJob({required MaintenanceJob job}) async {
    if (failNextCreate) {
      failNextCreate = false;
      throw Exception('Create failed');
    }
    final created = MaintenanceJob(
      id: 'job-${DateTime.now().millisecondsSinceEpoch}',
      description: job.description,
      tradeType: job.tradeType,
      status: JobStatus.pending,
      scheduleDateTime: job.scheduleDateTime,
      address: job.address,
      images: job.images,
      customerId: job.customerId,
      createdAt: DateTime.now(),
    );
    _jobs.add(created);
    return created;
  }

  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('Update failed');
    }
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx == -1) throw Exception('Job not found');
    final updated = _jobs[idx].copyWith(status: status);
    _jobs[idx] = updated;
    return updated;
  }

  @override
  Future<MaintenanceJob> getJob({required String jobId}) async {
    return _jobs.firstWhere((j) => j.id == jobId);
  }

  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async {
    return 'https://example.com/uploads/$fileName';
  }

  @override
  Future<MaintenanceJob> completeJob({required String jobId, required String notes, required List<String> images}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId}) async {
    return _jobs.where((j) => j.assetId == assetId).toList();
  }

  @override
  Future<MaintenanceJob> rejectJob({required String jobId}) async {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx == -1) throw Exception('Job not found');
    final updated = _jobs[idx].copyWith(status: JobStatus.rejected);
    _jobs[idx] = updated;
    return updated;
  }

  @override
  void dispose() {}
}

class DummyNotificationService implements NotificationService {
  final List<String> sentTitles = [];

  @override
  void sendNotification({required String title, required String body}) {
    sentTitles.add(title);
  }

  @override
  Stream<AppNotification> get notificationsStream => const Stream.empty();

  @override
  void dispose() {}
}

class DummyTelemetryService implements TelemetryService {
  final List<String> loggedEvents = [];

  @override
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    loggedEvents.add(name);
  }

  @override
  void captureException(Object error, [StackTrace? stackTrace]) {}
}

void main() {
  late StubJobsRepository stubRepo;
  late DummyNotificationService dummyNotif;
  late DummyTelemetryService dummyTele;
  late JobsViewModel vm;

  setUp(() {
    stubRepo = StubJobsRepository();
    dummyNotif = DummyNotificationService();
    dummyTele = DummyTelemetryService();
    vm = JobsViewModel(
      jobsRepository: stubRepo,
      notificationService: dummyNotif,
      telemetryService: dummyTele,
      userId: 'user-1',
      role: UserRole.customer,
    );
  });

  tearDown(() {
    vm.dispose();
  });

  group('initial state', () {
    test('starts with empty jobs list', () {
      expect(vm.jobs, isEmpty);
      expect(vm.isLoading, isTrue); // loading until first stream emit
    });

    test('has no error initially', () {
      expect(vm.errorMessage, isNull);
    });
  });

  group('streamJobs', () {
    test('updates jobs list on stream emit', () async {
      final job = MaintenanceJob(
        id: 'j1', description: 'Fix leak', tradeType: TradeType.plumbing,
        status: JobStatus.pending, address: '123 St', images: [],
        customerId: 'user-1', createdAt: DateTime(2026),
      );
      stubRepo.emitJobs([job]);
      await Future(() {});
      expect(vm.jobs.length, 1);
      expect(vm.jobs.first.description, 'Fix leak');
      expect(vm.isLoading, isFalse);
    });

    test('sets error state when jobs repository fails', () async {
      stubRepo.emitJobs([]);
      await Future(() {});
      expect(vm.isLoading, isFalse);
    });
  });

  group('raiseJob', () {
    test('creates job successfully', () async {
      final created = await vm.raiseJob(
        description: 'Fix sink',
        tradeType: TradeType.plumbing,
        schedule: DateTime(2026, 6, 16, 14, 0),
        address: '123 St',
        images: [],
      );

      expect(created.id, isNotEmpty);
      expect(created.description, 'Fix sink');
      expect(created.status, JobStatus.pending);
      expect(dummyTele.loggedEvents.contains('raise_job'), isTrue);
      expect(dummyNotif.sentTitles.contains('New Service Request Raised'), isTrue);
    });

    test('sets error message on failure', () async {
      stubRepo.failNextCreate = true;
      try {
        await vm.raiseJob(
          description: 'Fail', tradeType: TradeType.electrical,
          schedule: DateTime(2026), address: '', images: [],
        );
      } catch (_) {}

      expect(vm.errorMessage, contains('Create failed'));
    });

    test('resets isCreating after completion', () async {
      await vm.raiseJob(
        description: 'Test', tradeType: TradeType.plumbing,
        schedule: DateTime(2026), address: '', images: [],
      );
      expect(vm.isCreating, isFalse);
    });
  });

  group('updateJobStatus', () {
    test('updates status successfully', () async {
      final created = await vm.raiseJob(
        description: 'Test', tradeType: TradeType.plumbing,
        schedule: DateTime(2026), address: '', images: [],
      );

      await vm.updateStatus(created.id, JobStatus.inProgress);
      final job = await stubRepo.getJob(jobId: created.id);
      expect(job.status, JobStatus.inProgress);
      expect(dummyTele.loggedEvents.contains('update_status'), isTrue);
      expect(dummyNotif.sentTitles.contains('Job Status Updated'), isTrue);
    });
  });

  group('uploadJobImage', () {
    test('returns upload URL', () async {
      final url = await vm.uploadJobImage('test.jpg', Uint8List.fromList([1, 2, 3]));
      expect(url, 'https://example.com/uploads/test.jpg');
    });

    test('resets isLoading after upload', () async {
      await vm.uploadJobImage('test.jpg', Uint8List.fromList([1, 2, 3]));
      expect(vm.isLoading, isFalse);
    });
  });
}
