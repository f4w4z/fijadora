import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/job_status.dart';
import '../../domain/models/maintenance_job.dart';
import '../../domain/models/user_role.dart';
import '../services/local_cache_service.dart';
import '../services/supabase_service.dart';

abstract class JobsRepository {
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role});
  Future<MaintenanceJob> createJob({required MaintenanceJob job});
  Future<MaintenanceJob> updateJobStatus({required String jobId, required JobStatus status});
  Future<MaintenanceJob> getJob({required String jobId});
  Future<MaintenanceJob> assignWorker({required String jobId, required String workerId});
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes);
  Future<MaintenanceJob> completeJob({required String jobId, required String notes, required List<String> images});
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId});
  Future<MaintenanceJob> rejectJob({required String jobId});
  void dispose();
}

// 1. Supabase Jobs Repository Implementation
class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Stream<List<MaintenanceJob>> streamJobs({required String userId, required UserRole role}) {
    final cacheKey = 'jobs_${userId}_${role.name}';
    if (role == UserRole.admin || role == UserRole.manager) {
      return cacheStream(
        _client
            .from('jobs')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .map((data) => data.map((json) => MaintenanceJob.fromJson(json)).toList()),
        cacheKey,
        MaintenanceJob.fromJson,
        (j) => j.toJson(),
      );
    }

    final filterColumn = role == UserRole.worker ? 'worker_id' : 'customer_id';
    return cacheStream(
      _client
          .from('jobs')
          .stream(primaryKey: ['id'])
          .eq(filterColumn, userId)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => MaintenanceJob.fromJson(json)).toList()),
      cacheKey,
      MaintenanceJob.fromJson,
      (j) => j.toJson(),
    );
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
    final response = await _client.rpc('assign_job', params: {
      'p_job_id': jobId,
      'p_worker_id': workerId,
    });
    return MaintenanceJob.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> uploadJobImage(String fileName, Uint8List fileBytes) async {
    final path = 'job_images/$fileName';
    await _client.storage.from('product-images').uploadBinary(
      path,
      fileBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    return _client.storage.from('product-images').getPublicUrl(path);
  }

  @override
  Future<MaintenanceJob> completeJob({
    required String jobId,
    required String notes,
    required List<String> images,
  }) async {
    final currentJob = await getJob(jobId: jobId);
    final updatedDesc = '${currentJob.description}\n\nCompletion Notes: $notes';
    final updatedImages = [...currentJob.images, ...images];

    final response = await _client
        .from('jobs')
        .update({
          'description': updatedDesc,
          'images': updatedImages,
          'status': JobStatus.waitingApproval.name,
        })
        .eq('id', jobId)
        .select()
        .single();

    return MaintenanceJob.fromJson(response);
  }

  @override
  Future<List<MaintenanceJob>> fetchJobsForAsset({required String assetId}) async {
    final response = await _client
        .from('jobs')
        .select()
        .eq('asset_id', assetId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((json) => MaintenanceJob.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MaintenanceJob> rejectJob({required String jobId}) async {
    final response = await _client
        .from('jobs')
        .update({
          'status': JobStatus.pending.name,
          'worker_id': null,
        })
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
