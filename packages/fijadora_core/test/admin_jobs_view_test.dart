import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fijadora_core/data/repositories/auth_repository.dart';
import 'package:fijadora_core/data/repositories/jobs_repository.dart';
import 'package:fijadora_core/data/repositories/users_repository.dart';
import 'package:fijadora_core/data/services/app_notification_service.dart';
import 'package:fijadora_core/domain/models/app_user.dart';
import 'package:fijadora_core/domain/models/job_status.dart';
import 'package:fijadora_core/domain/models/maintenance_job.dart';
import 'package:fijadora_core/domain/models/trade_type.dart';
import 'package:fijadora_core/domain/models/user_role.dart';
import 'package:fijadora_core/ui/features/auth/view_models/auth_view_model.dart';
import 'package:fijadora_core/ui/features/staff/views/admin_jobs_view.dart';

class _StubAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? currentUser = AppUser(
    id: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin User',
    role: UserRole.admin,
    createdAt: DateTime(2026),
  );

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {}
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> resendEmailVerification({required String email}) async {}
  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {}
  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}
  @override
  Future<void> updatePassword({required String newPassword}) async {}
  @override
  Future<void> refreshUser() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  void dispose() => _controller.close();
}

class _StubJobsRepository implements JobsRepository {
  final _controller = StreamController<List<MaintenanceJob>>.broadcast();

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    return _controller.stream;
  }

  void emitJobs(List<MaintenanceJob> jobs) {
    _controller.add(List.unmodifiable(jobs));
  }

  @override
  Future<MaintenanceJob> createJob({required MaintenanceJob job}) async => throw UnimplementedError();
  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async => throw UnimplementedError();
  @override
  Future<MaintenanceJob> getJob({required String jobId}) async => throw UnimplementedError();
  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async => throw UnimplementedError();
  @override
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async => throw UnimplementedError();
  @override
  Future<MaintenanceJob> completeJob({required String jobId, required String notes, required List<String> images}) async => throw UnimplementedError();
  @override
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId}) async => throw UnimplementedError();
  @override
  Future<MaintenanceJob> rejectJob({required String jobId}) async => throw UnimplementedError();
  @override
  void dispose() => _controller.close();
}

class _StubNotificationService implements NotificationService {
  @override
  void sendNotification({required String title, required String body}) {}

  @override
  Stream<AppNotification> get notificationsStream => const Stream.empty();

  @override
  void dispose() {}
}

MaintenanceJob _createJob({
  required String id,
  String description = 'Test job',
  TradeType tradeType = TradeType.plumbing,
  JobStatus status = JobStatus.pending,
  String address = '123 Test St',
}) {
  return MaintenanceJob(
    id: id,
    description: description,
    tradeType: tradeType,
    status: status,
    address: address,
    images: [],
    customerId: 'customer-1',
    createdAt: DateTime(2026),
  );
}

Widget _buildTestWidget({
  required _StubJobsRepository jobsRepo,
  required _StubAuthRepository authRepo,
  required _StubNotificationService notificationService,
}) {
  return ProviderScope(
    overrides: [
      jobsRepositoryProvider.overrideWithValue(jobsRepo),
      authRepositoryProvider.overrideWithValue(authRepo),
      workersProvider.overrideWith((ref) => [
        AppUser(id: 'worker-1', email: 'worker@test.com', name: 'Worker One', role: UserRole.worker, createdAt: DateTime(2026)),
        AppUser(id: 'worker-2', email: 'worker2@test.com', name: 'Worker Two', role: UserRole.worker, createdAt: DateTime(2026)),
      ]),
      notificationServiceProvider.overrideWithValue(notificationService),
      authViewModelProvider.overrideWith((ref) => AuthViewModel(ref.watch(authRepositoryProvider))),
    ],
    child: const MaterialApp(
      home: AdminJobsView(),
    ),
  );
}

void main() {
  late _StubJobsRepository stubJobsRepo;
  late _StubAuthRepository stubAuthRepo;
  late _StubNotificationService stubNotificationService;

  setUp(() {
    stubJobsRepo = _StubJobsRepository();
    stubAuthRepo = _StubAuthRepository();
    stubNotificationService = _StubNotificationService();
  });

  tearDown(() {
    stubJobsRepo.dispose();
    stubAuthRepo.dispose();
    stubNotificationService.dispose();
  });

  group('AdminJobsView', () {
    Future<void> pumpView(WidgetTester tester) async {
      await tester.pumpWidget(_buildTestWidget(
        jobsRepo: stubJobsRepo,
        authRepo: stubAuthRepo,
        notificationService: stubNotificationService,
      ));
      await tester.pump();
    }

    testWidgets('renders the admin jobs view', (tester) async {
      await pumpView(tester);
      stubJobsRepo.emitJobs([]);
      await tester.pump();

      expect(find.text('Jobs'), findsOneWidget);
      expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    });

    testWidgets('shows job list', (tester) async {
      await pumpView(tester);

      final jobs = [
        _createJob(id: 'j1', description: 'Fix plumbing leak'),
        _createJob(id: 'j2', description: 'Electrical rewiring', tradeType: TradeType.electrical),
      ];
      stubJobsRepo.emitJobs(jobs);
      await tester.pump();

      expect(find.text('Fix plumbing leak'), findsOneWidget);
      expect(find.text('Electrical rewiring'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await pumpView(tester);
      stubJobsRepo.emitJobs([]);
      await tester.pump();

      expect(find.text('No jobs found'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.square_list), findsOneWidget);
    });

    testWidgets('shows filter tabs', (tester) async {
      await pumpView(tester);
      stubJobsRepo.emitJobs([]);
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
