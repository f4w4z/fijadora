import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../services/crash_reporting_service.dart';
import '../services/local_cache_service.dart';
import '../services/supabase_service.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<void> signUp({required String email, required String password, required String name, required UserRole role});
  Future<void> signIn({required String email, required String password});
  Future<void> resendEmailVerification({required String email});
  Future<void> updateWorkerStatus({required String userId, required String status});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> updatePassword({required String newPassword});
  Future<void> refreshUser();
  Future<void> signOut();
  Future<void> deleteAccount();
  void dispose();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    final sbUser = _client.auth.currentUser;
    if (sbUser != null && sbUser.emailConfirmedAt != null) {
      final roleStr = sbUser.userMetadata?['role'] as String?;
      final name = sbUser.userMetadata?['name'] as String? ?? '';
      _currentUser = AppUser(
        id: sbUser.id,
        email: sbUser.email ?? '',
        name: name,
        role: UserRole.fromString(roleStr),
        emailConfirmedAt: _parseEmailConfirmedAt(sbUser.emailConfirmedAt),
        createdAt: DateTime.now(),
      );
    }
    _initStream();
  }

  final sb.SupabaseClient _client;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  StreamSubscription? _authSubscription;

  void _initStream() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final sbUser = data.session?.user;
      if (sbUser == null || sbUser.emailConfirmedAt == null) {
        _currentUser = null;
        _controller.add(null);
      } else {
        try {
          final profile = await _fetchProfile(sbUser.id);
          _currentUser = profile.copyWith(
            emailConfirmedAt: DateTime.parse(sbUser.emailConfirmedAt!),
          );
          _controller.add(_currentUser);
        } catch (e) {
          CrashReportingService.captureException(e);
          final roleStr = sbUser.userMetadata?['role'] as String?;
          final name = sbUser.userMetadata?['name'] as String? ?? '';
          final fallbackUser = AppUser(
            id: sbUser.id,
            email: sbUser.email ?? '',
            name: name,
            role: UserRole.fromString(roleStr),
            emailConfirmedAt: _parseEmailConfirmedAt(sbUser.emailConfirmedAt),
            createdAt: DateTime.now(),
          );
          _currentUser = fallbackUser;
          _controller.add(fallbackUser);
        }
      }
    });
  }

  Future<AppUser> _fetchProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return AppUser.fromJson(response);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signUp({required String email, required String password, required String name, required UserRole role}) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.key,
      },
      emailRedirectTo: 'fijadora://app',
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> resendEmailVerification({required String email}) async {
    await _client.auth.resend(
      type: sb.OtpType.signup,
      email: email,
      emailRedirectTo: 'fijadora://app',
    );
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
  }

  @override
  Future<void> refreshUser() async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {}
    final sbUser = _client.auth.currentUser;
    if (sbUser == null) return;
    try {
      final profile = await _fetchProfile(sbUser.id);
      _currentUser = profile.copyWith(
        emailConfirmedAt:
            sbUser.emailConfirmedAt != null ? DateTime.parse(sbUser.emailConfirmedAt!) : null,
      );
      if (!_controller.isClosed) _controller.add(_currentUser);
    } catch (e) {
      CrashReportingService.captureException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await LocalCacheService.instance.clear();
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_user_account');
    _currentUser = null;
    await LocalCacheService.instance.clear();
  }

  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {
    await _client.from('users').update({'worker_status': status}).eq('id', userId);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: 'fijadora://app');
  }

  DateTime? _parseEmailConfirmedAt(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = SupabaseService.instance.client;
  final repo = SupabaseAuthRepository(client);
  ref.onDispose(() => repo.dispose());
  return repo;
});
