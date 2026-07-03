import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/job_status.dart';
import '../../domain/models/maintenance_job.dart';
import '../../domain/models/user_role.dart';
import '../services/supabase_service.dart';

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

// 2. Riverpod Provider definition
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabaseJobsRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});
