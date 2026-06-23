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
}

// 1. Supabase Jobs Repository Implementation
class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    // Determine filter column based on role
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
    final response = await _client
        .from('jobs')
        .insert(job.toJson())
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

// 2. Mock Jobs Repository Implementation (for testing & fallback)
class MockJobsRepository implements JobsRepository {
  MockJobsRepository() {
    _populateInitialMockJobs();
  }

  final _controller = StreamController<List<MaintenanceJob>>.broadcast();
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
    try {
      final box = Hive.box('cached_jobs');
      final list = box.get('jobs_list') as List<dynamic>?;
      if (list != null && list.length >= 7) {
        _mockJobs.clear();
        for (final item in list) {
          if (item is Map) {
            final jsonMap = Map<String, dynamic>.from(item);
            _mockJobs.add(MaintenanceJob.fromJson(jsonMap));
          }
        }
        return;
      }
    } catch (e) {
      debugPrint('Hive read error: $e. Falling back to default list.');
    }

    _mockJobs.addAll([
      MaintenanceJob(
        id: 'job-1',
        description: 'Kitchen sink pipe is leaking from the joint underneath. Need washer replaced.',
        tradeType: TradeType.plumbing,
        status: JobStatus.completed,
        scheduleDateTime: DateTime.now().subtract(const Duration(days: 3)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const [],
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
        images: const [],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MaintenanceJob(
        id: 'job-3',
        description: 'AC unit is blowing warm air only. Fan seems to run but no cooling.',
        tradeType: TradeType.hvac,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 2, hours: 5)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const [],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      MaintenanceJob(
        id: 'job-4',
        description: 'Water heater thermostat replacement. Unit is not heating water to correct temperature.',
        tradeType: TradeType.plumbing,
        status: JobStatus.workerEnRoute,
        scheduleDateTime: DateTime.now().add(const Duration(hours: 2)),
        address: 'Apartment 12C, Pineview Apartments, NY',
        images: const [],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      MaintenanceJob(
        id: 'job-5',
        description: 'Repair broken drawer slide in master bedroom dresser. Screws stripped out of wood.',
        tradeType: TradeType.generalRepairs,
        status: JobStatus.completed,
        scheduleDateTime: DateTime.now().subtract(const Duration(days: 1)),
        address: 'Apartment 4B, Oakwood Heights, NY',
        images: const [],
        customerId: 'mock-customer',
        workerId: 'mock-worker-alex',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      ),
      MaintenanceJob(
        id: 'job-6',
        description: 'Install smart ring doorbell and configure with home wifi network. Ring plate already mounted.',
        tradeType: TradeType.electrical,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 3)),
        address: 'Apartment 8A, Oakwood Heights, NY',
        images: const [],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      MaintenanceJob(
        id: 'job-7',
        description: 'Annual maintenance service check for residential furnace system before winter season.',
        tradeType: TradeType.hvac,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(days: 5)),
        address: 'Apartment 15D, Pineview Apartments, NY',
        images: const [],
        customerId: 'mock-customer',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
    _saveToHive();
  }

  void _notifyListeners(String userId, UserRole role) {
    final filtered = _getFilteredJobs(userId, role);
    _controller.add(filtered);
  }

  List<MaintenanceJob> _getFilteredJobs(String userId, UserRole role) {
    if (role == UserRole.worker) {
      return _mockJobs.where((j) => j.workerId == userId || j.workerId == null || j.workerId!.isEmpty).toList();
    }
    // Sort by created date descending
    final list = List<MaintenanceJob>.from(_mockJobs);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    // Push the current cached values immediately to start the stream
    Timer.run(() => _notifyListeners(userId, role));
    return _controller.stream;
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
    _notifyListeners(job.customerId, UserRole.customer);
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
    _notifyListeners(updated.customerId, UserRole.customer);
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
    _notifyListeners(updated.customerId, UserRole.customer);
    return updated;
  }
}

// 3. Riverpod Provider definition
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('JobsRepository: Using MOCK implementation');
    return MockJobsRepository();
  }

  try {
    final client = SupabaseService.instance.client;
    return SupabaseJobsRepository(client);
  } catch (e) {
    debugPrint('JobsRepository: Failed to get Supabase client. Falling back to MOCK.');
    return MockJobsRepository();
  }
});
