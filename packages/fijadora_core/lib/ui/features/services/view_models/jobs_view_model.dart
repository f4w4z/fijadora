import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../data/services/push_notification_service.dart';
import '../../../../data/services/telemetry_service.dart';

class JobsViewModel extends ChangeNotifier {
  JobsViewModel({
    required this.jobsRepository,
    required this.notificationService,
    required this.telemetryService,
    required this.userId,
    required this.role,
  }) {
    _init();
  }

  final JobsRepository jobsRepository;
  final NotificationService notificationService;
  final TelemetryService telemetryService;
  final String userId;
  final UserRole role;
  StreamSubscription<List<MaintenanceJob>>? _subscription;

  List<MaintenanceJob> _jobs = [];
  List<MaintenanceJob> get jobs => _jobs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _init() {
    if (userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    _subscription = jobsRepository
        .streamJobs(userId: userId, role: role)
        .listen(
      (jobsList) {
        _jobs = jobsList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Could not load jobs.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<MaintenanceJob> raiseJob({
    required String description,
    required TradeType tradeType,
    required DateTime schedule,
    required String address,
    required List<String> images,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final job = MaintenanceJob(
        id: '', // Will be set by repository
        description: description,
        tradeType: tradeType,
        status: JobStatus.pending,
        scheduleDateTime: schedule,
        address: address,
        images: images,
        customerId: userId,
        createdAt: DateTime.now(),
      );

      final created = await jobsRepository.createJob(job: job);
      telemetryService.logEvent('raise_job', {'trade_type': tradeType.name});
      notificationService.sendNotification(
        title: 'New Service Request Raised',
        body: 'A request for ${tradeType.displayName} has been submitted successfully.',
      );
      return created;
    } catch (e) {
      _errorMessage = 'Could not submit service request.';
      notifyListeners();
      rethrow;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String jobId, JobStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await jobsRepository.updateJobStatus(jobId: jobId, status: status);
      telemetryService.logEvent('update_status', {'job_id': jobId, 'status': status.name});
      notificationService.sendNotification(
        title: 'Job Status Updated',
        body: 'Job status is now ${status.displayName.toUpperCase()}.',
      );
    } catch (e) {
      _errorMessage = 'Could not update job status.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MaintenanceJob> fetchJob(String jobId) async {
    try {
      return await jobsRepository.getJob(jobId: jobId);
    } catch (e) {
      _errorMessage = 'Could not load job details.';
      notifyListeners();
      rethrow;
    }
  }

  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await jobsRepository.uploadJobImage(fileName, fileBytes);
    } catch (e) {
      _errorMessage = 'Could not upload image.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeJob(String jobId, String notes, List<String> images) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await jobsRepository.completeJob(jobId: jobId, notes: notes, images: images);
      telemetryService.logEvent('complete_job', {'job_id': jobId});
      PushNotificationService.sendNotification(
        role: 'admin',
        title: 'Job Completed',
        body: 'A job is ready for your review and approval.',
      );
      PushNotificationService.sendNotification(
        role: 'manager',
        title: 'Job Completed',
        body: 'A job is ready for your review and approval.',
      );
      notificationService.sendNotification(
        title: 'Job Completed',
        body: 'Job completion request submitted for approval.',
      );
    } catch (e) {
      _errorMessage = 'Could not complete job.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectJob(String jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await jobsRepository.rejectJob(jobId: jobId);
      telemetryService.logEvent('reject_job', {'job_id': jobId});
      notificationService.sendNotification(
        title: 'Job Rejected',
        body: 'Job was rejected by the manager and returned to pending assignment.',
      );
    } catch (e) {
      _errorMessage = 'Could not reject job.';
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void refresh() {
    _subscription?.cancel();
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Riverpod Provider for JobsViewModel
final jobsViewModelProvider = ChangeNotifierProvider<JobsViewModel>((ref) {
  final repository = ref.watch(jobsRepositoryProvider);
  final userId = ref.watch(authViewModelProvider.select((vm) => vm.user?.id ?? ''));
  final role = ref.watch(authViewModelProvider.select((vm) => vm.user?.role ?? UserRole.customer));
  final notificationService = ref.watch(notificationServiceProvider);
  final telemetryService = ref.watch(telemetryServiceProvider);

  return JobsViewModel(
    jobsRepository: repository,
    notificationService: notificationService,
    telemetryService: telemetryService,
    userId: userId,
    role: role,
  );
});

// Shared StreamProvider for caching and sharing the jobs stream.
// keepAlive() prevents the subscription from being torn down when the current
// tab stops watching it (e.g. swiping between shell tabs), so re-entering a
// page shows cached data instantly instead of flashing a loading shimmer.
// It still recomputes when userId/role change (login/logout/role switch).
final jobsStreamProvider = StreamProvider.autoDispose<List<MaintenanceJob>>((ref) {
  ref.keepAlive();
  final repository = ref.watch(jobsRepositoryProvider);
  final userId = ref.watch(authViewModelProvider.select((vm) => vm.user?.id ?? ''));
  final role = ref.watch(authViewModelProvider.select((vm) => vm.user?.role ?? UserRole.customer));

  if (userId.isEmpty) {
    return const Stream.empty();
  }

  return repository.streamJobs(userId: userId, role: role);
});
