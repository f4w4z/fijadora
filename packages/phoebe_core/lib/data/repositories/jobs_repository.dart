import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/job_status.dart';
import '../../domain/models/maintenance_job.dart';
import '../../domain/models/trade_type.dart';
import '../../domain/models/user_role.dart';
import '../services/supabase_service.dart';
import 'package:hive/hive.dart';

abstract class JobsRepository {
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role});
  Future<MaintenanceJob> createJob({required MaintenanceJob job});
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status});
  Future<MaintenanceJob> getJob({required String jobId});
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId});
  void dispose();
}

// 1. Supabase Jobs Repository Implementation
class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    if (role == UserRole.admin || role == UserRole.manager) {
      return _client
          .from('jobs')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => MaintenanceJob.fromJson(json)).toList());
    }

    final filterColumn = role == UserRole.worker ? 'worker_id' : 'customer_id';
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq(filterColumn, userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => MaintenanceJob.fromJson(json)).toList());
  }

  @override
  Future<MaintenanceJob> createJob({required MaintenanceJob job}) async {
    final json = job.toJson();
    json.remove('id');
    json.remove('created_at');
    final response = await _client
        .from('jobs')
        .insert(json)
        .select()
        .single();
    return MaintenanceJob.fromJson(response);
  }

  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async {
    final response = await _client
        .from('jobs')
        .update({'status': status.name})
        .eq('id', jobId)
        .select()
        .single();
    return MaintenanceJob.fromJson(response);
  }

  @override
  Future<MaintenanceJob> getJob({required String jobId}) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('id', jobId)
        .single();
    return MaintenanceJob.fromJson(response);
  }

  @override
  void dispose() {}

  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async {
    final response = await _client
        .from('jobs')
        .update({'worker_id': workerId, 'status': JobStatus.assigned.name})
        .eq('id', jobId)
        .select()
        .single();
    return MaintenanceJob.fromJson(response);
  }
}

class _MockSubscription {
  final String userId;
  final UserRole role;
  final void Function(List<MaintenanceJob>) callback;

  _MockSubscription(this.userId, this.role, this.callback);

  void notify(List<MaintenanceJob> jobs) {
    callback(jobs);
  }
}

// 2. Mock Jobs Repository Implementation (for testing & fallback)
class MockJobsRepository implements JobsRepository {
  MockJobsRepository() {
    _populateInitialMockJobs();
  }

  final List<_MockSubscription> _activeSubscriptions = [];
  final List<MaintenanceJob> _mockJobs = [];

  void _saveToHive() {
    try {
      final box = Hive.box('cached_jobs');
      final list = _mockJobs.map((j) => j.toJson()).toList();
      box.put('jobs_list', list);
    } catch (e) {
      debugPrint('Hive write error: $e');
    }
  }

  void _populateInitialMockJobs() {
    _mockJobs.addAll([
      MaintenanceJob(
        id: 'job-1',
        description: 'Kitchen sink pipe is leaking from the joint underneath. Need washer replaced.',
        tradeType: TradeType.plumbing,
        status: JobStatus.completed,
        scheduleDateTime: DateTime.now().subtract(const Duration(days: 3)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        workerId: 'mock-worker',
        createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      ),
      MaintenanceJob(
        id: 'job-2',
        description: 'Living room main ceiling light switch is broken and flickering when turned on.',
        tradeType: TradeType.electrical,
        status: JobStatus.assigned,
        scheduleDateTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MaintenanceJob(
        id: 'job-3',
        description: 'AC unit is blowing warm air only. Fan seems to run but no cooling.',
        tradeType: TradeType.acEngineering,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 2, hours: 5)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1631545806605-7ed6658f0e2a?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      MaintenanceJob(
        id: 'job-4',
        description: 'Full interior design consultation for living room and master bedroom.',
        tradeType: TradeType.interiorDesign,
        status: JobStatus.workerEnRoute,
        scheduleDateTime: DateTime.now().add(const Duration(hours: 2)),
        address: 'Apartment 12C, Pineview Apartments, NY',
        images: const ['https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      MaintenanceJob(
        id: 'job-5',
        description: 'Fix broken tiles in bathroom floor. Cracked grout and loose tiles need replacing.',
        tradeType: TradeType.tiling,
        status: JobStatus.completed,
        scheduleDateTime: DateTime.now().subtract(const Duration(days: 1)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1622372738946-62e02505f1a4?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ),
      MaintenanceJob(
        id: 'job-6',
        description: 'Repair brick wall in backyard. Mortar is deteriorating between bricks.',
        tradeType: TradeType.masonry,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 3)),
        address: 'Apartment 8A, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      MaintenanceJob(
        id: 'job-7',
        description: 'Garden landscaping and pruning for the front yard. Overgrown shrubs need trimming.',
        tradeType: TradeType.gardening,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 5)),
        address: 'Apartment 15D, Pineview Apartments, NY',
        images: const ['https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MaintenanceJob(
        id: 'job-8',
        description: 'Customer submitted approval review for completed bathroom tiling work.',
        tradeType: TradeType.tiling,
        status: JobStatus.waitingApproval,
        scheduleDateTime: DateTime.now().subtract(const Duration(hours: 6)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const ['https://images.unsplash.com/photo-1622372738946-62e02505f1a4?w=400&h=300&fit=crop'],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(hours: 24)),
      ),
    ]);
    _saveToHive();
  }

  void _notifyListeners() {
    for (final sub in _activeSubscriptions) {
      sub.notify(_getFilteredJobs(sub.userId, sub.role));
    }
  }

  List<MaintenanceJob> _getFilteredJobs(String userId, UserRole role) {
    List<MaintenanceJob> filtered;
    if (role == UserRole.worker) {
      filtered = _mockJobs.where((j) => j.workerId == userId || j.workerId == null || j.workerId!.isEmpty).toList();
    } else if (role == UserRole.admin || role == UserRole.manager) {
      filtered = _mockJobs;
    } else {
      filtered = _mockJobs.where((j) => j.customerId == userId).toList();
    }
    // Sort by created date descending
    final list = List<MaintenanceJob>.from(filtered);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    late final StreamController<List<MaintenanceJob>> localController;
    
    final subscription = _MockSubscription(userId, role, (jobsList) {
      if (!localController.isClosed) {
        localController.add(jobsList);
      }
    });

    localController = StreamController<List<MaintenanceJob>>(
      onListen: () {
        _activeSubscriptions.add(subscription);
        subscription.notify(_getFilteredJobs(userId, role));
      },
      onCancel: () {
        _activeSubscriptions.remove(subscription);
        localController.close();
      },
    );

    return localController.stream;
  }

  @override
  Future<MaintenanceJob> createJob({required MaintenanceJob job}) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate delay
    final newJob = job.copyWith(
      id: 'job-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _mockJobs.add(newJob);
    _saveToHive();
    _notifyListeners();
    return newJob;
  }

  @override
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockJobs.indexWhere((j) => j.id == jobId);
    if (index == -1) {
      throw Exception('Job not found');
    }
    final updated = _mockJobs[index].copyWith(status: status);
    _mockJobs[index] = updated;
    _saveToHive();
    _notifyListeners();
    return updated;
  }

  @override
  Future<MaintenanceJob> getJob({required String jobId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final job = _mockJobs.firstWhere((j) => j.id == jobId, orElse: () => throw Exception('Job not found'));
    return job;
  }

  @override
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockJobs.indexWhere((j) => j.id == jobId);
    if (index == -1) {
      throw Exception('Job not found');
    }
    final updated = _mockJobs[index].copyWith(
      workerId: workerId,
      status: JobStatus.assigned,
    );
    _mockJobs[index] = updated;
    _saveToHive();
    _notifyListeners();
    return updated;
  }

  @override
  void dispose() {
    _activeSubscriptions.clear();
  }
}

// 3. Riverpod Provider definition
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  JobsRepository repo;
  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('JobsRepository: Using MOCK implementation');
    repo = MockJobsRepository();
  } else {
    try {
      final client = SupabaseService.instance.client;
      repo = SupabaseJobsRepository(client);
    } catch (e) {
      debugPrint('JobsRepository: Failed to get Supabase client. Falling back to MOCK.');
      repo = MockJobsRepository();
    }
  }

  ref.onDispose(() => repo.dispose());

  return repo;
});
