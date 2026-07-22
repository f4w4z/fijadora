import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/app_user.dart';
import '../services/supabase_service.dart';

abstract class UsersRepository {
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids);
  Future<AppUser?> getUser(String id);
  Future<List<AppUser>> fetchWorkers();
}

class SupabaseUsersRepository implements UsersRepository {
  SupabaseUsersRepository(this._client);
  final sb.SupabaseClient _client;

  @override
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _client
        .from('users')
        .select('id, email, name, role, worker_status, created_at')
        .filter('id', 'in', '(${ids.join(',')})');
    final map = <String, AppUser>{};
    for (final row in data as List) {
      final u = AppUser.fromJson(row as Map<String, dynamic>);
      map[u.id] = u;
    }
    return map;
  }

  @override
  Future<AppUser?> getUser(String id) async {
    final data = await _client
        .from('users')
        .select('id, email, name, role, worker_status, created_at')
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : AppUser.fromJson(data);
  }

  @override
  Future<List<AppUser>> fetchWorkers() async {
    final data = await _client
        .from('users')
        .select('id, email, name, role, worker_status, created_at')
        .eq('role', 'worker')
        .order('created_at', ascending: true);
    return (data as List)
        .map((row) => AppUser.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return SupabaseUsersRepository(SupabaseService.instance.client);
});

/// Cached lookup of a single user by id. Results are cached by Riverpod so
/// widgets that watch this won't re-fetch (and re-flicker) on every rebuild.
final userByIdProvider = FutureProvider.family<AppUser?, String>((ref, id) {
  return ref.watch(usersRepositoryProvider).getUser(id);
});

/// Cached list of all workers. Shared across the workers and admin dashboard
/// views so re-entering a page does not trigger a re-fetch. Call
/// `ref.invalidate(workersProvider)` after mutating worker status to refresh.
final workersProvider = FutureProvider<List<AppUser>>((ref) {
  return ref.watch(usersRepositoryProvider).fetchWorkers();
});
