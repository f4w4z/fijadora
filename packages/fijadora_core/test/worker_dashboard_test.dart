import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/data/repositories/jobs_repository.dart';
import 'package:fijadora_core/data/services/app_notification_service.dart';
import 'package:fijadora_core/data/services/telemetry_service.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/job_status.dart';
import 'package:fijadora_core/domain/models/maintenance_job.dart';
import 'package:fijadora_core/domain/models/trade_type.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/worker/view_models/dispatch_provider.dart';
import 'package:fijadora_core/ui/features/worker/views/job_card.dart';
import 'package:fijadora_core/ui/features/worker/views/worker_dashboard_view.dart';

class StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  final AppUser? _currentUser;

  StubAuthRepository({AppUser? initialUser}) : _currentUser = initialUser;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  void emitUser(AppUser? user) => _controller.add(user);

  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {}
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> resendEmailVerification({required String email}) async {}
  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> refreshUser() async {}



  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

class StubJobsRepository implements JobsRepository {
  final _jobs = <MaintenanceJob>[];
  final _controller = StreamController<List<MaintenanceJob>>.broadcast();

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
    throw UnimplementedError();
  }

  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async {
    throw UnimplementedError();
  }

  @override
  Future<MaintenanceJob> getJob({required String jobId}) async {
    throw UnimplementedError();
  }

  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async {
    throw UnimplementedError();
  }

  @override
  Future<MaintenanceJob> completeJob({required String jobId, required String notes, required List<String> images}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId}) async {
    throw UnimplementedError();
  }

  @override
  Future<MaintenanceJob> rejectJob({required String jobId}) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}

class DummyNotificationService implements NotificationService {
  @override
  void sendNotification({required String title, required String body}) {}

  @override
  Stream<AppNotification> get notificationsStream => const Stream.empty();

  @override
  void dispose() {}
}

class DummyTelemetryService implements TelemetryService {
  @override
  void logEvent(String name, [Map<String, dynamic>? parameters]) {}

  @override
  void captureException(Object error, [StackTrace? stackTrace]) {}
}

Widget buildTestApp({
  required AuthRepository authRepo,
  required JobsRepository jobsRepo,
  required NotificationService notifService,
  required TelemetryService telemetryService,
  DispatchModel dispatchMode = DispatchModel.adminAssigned,
}) {
  return MaterialApp(
    home: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        jobsRepositoryProvider.overrideWithValue(jobsRepo),
        notificationServiceProvider.overrideWithValue(notifService),
        telemetryServiceProvider.overrideWithValue(telemetryService),
        dispatchModelProvider.overrideWith((ref) => dispatchMode),
      ],
      child: const WorkerDashboardTab(),
    ),
  );
}

void main() {
  final testUser = AppUser(
    id: 'worker-1',
    email: 'worker@test.com',
    name: 'John Worker',
    role: UserRole.worker,
    createdAt: DateTime(2026),
  );

  late StubAuthRepository authRepo;
  late StubJobsRepository jobsRepo;
  late DummyNotificationService notifService;
  late DummyTelemetryService telemetryService;

  setUp(() {
    authRepo = StubAuthRepository(initialUser: testUser);
    jobsRepo = StubJobsRepository();
    notifService = DummyNotificationService();
    telemetryService = DummyTelemetryService();
  });

  group('WorkerDashboardTab', () {
    testWidgets('renders dashboard', (tester) async {
      await tester.pumpWidget(buildTestApp(
        authRepo: authRepo,
        jobsRepo: jobsRepo,
        notifService: notifService,
        telemetryService: telemetryService,
      ));
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.textContaining('Hey'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows job cards', (tester) async {
      final jobs = [
        MaintenanceJob(
          id: 'j1',
          description: 'Fix plumbing',
          tradeType: TradeType.plumbing,
          status: JobStatus.pending,
          address: '123 Main St',
          images: [],
          customerId: 'cust-1',
          workerId: testUser.id,
          createdAt: DateTime(2026),
        ),
        MaintenanceJob(
          id: 'j2',
          description: 'Electrical repair',
          tradeType: TradeType.electrical,
          status: JobStatus.assigned,
          address: '456 Oak Ave',
          images: [],
          customerId: 'cust-2',
          workerId: null,
          createdAt: DateTime(2026),
        ),
      ];

      await tester.pumpWidget(buildTestApp(
        authRepo: authRepo,
        jobsRepo: jobsRepo,
        notifService: notifService,
        telemetryService: telemetryService,
      ));

      jobsRepo.emitJobs(jobs);
      await tester.pumpAndSettle();

      expect(find.byType(WorkerJobCard), findsNWidgets(2));
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(buildTestApp(
        authRepo: authRepo,
        jobsRepo: jobsRepo,
        notifService: notifService,
        telemetryService: telemetryService,
      ));

      jobsRepo.emitJobs([]);
      await tester.pump();

      expect(find.text('No jobs yet'), findsOneWidget);
      expect(find.byType(WorkerJobCard), findsNothing);
    });

    testWidgets('shows greeting', (tester) async {
      await tester.pumpWidget(buildTestApp(
        authRepo: authRepo,
        jobsRepo: jobsRepo,
        notifService: notifService,
        telemetryService: telemetryService,
      ));
      await tester.pump();

      expect(find.textContaining('Hey John,'), findsOneWidget);
      expect(find.text('Let\'s get to work'), findsOneWidget);
    });
  });
}
