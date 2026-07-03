import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../services/supabase_service.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signInWithEmail({required String email, required String password});
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });
  List<AppUser> getAllWorkers();
  Future<void> refreshWorkers();
  Future<void> updateWorkerStatus({required String userId, required String status});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> resendVerificationEmail();
  Future<void> updatePassword({required String newPassword});
  Future<void> signOut();
  void dispose();
}

// 1. Supabase Auth Repository Implementation
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    final sbUser = _client.auth.currentUser;
    if (sbUser != null) {
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
    _fetchWorkers();
  }

  final sb.SupabaseClient _client;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  StreamSubscription? _authSubscription;
  List<AppUser> _cachedWorkers = [];

  void _initStream() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        _currentUser = null;
        _controller.add(null);
      } else {
        try {
          final profile = await _fetchProfile(user.id);
          _currentUser = profile;
          _controller.add(profile);
        } catch (e) {
          debugPrint('Error fetching user profile from Supabase: $e');
          // If profile table doesn't exist or fail, create a fallback AppUser from auth metadata
          final roleStr = user.userMetadata?['role'] as String?;
          final name = user.userMetadata?['name'] as String? ?? '';
          final fallbackUser = AppUser(
            id: user.id,
            email: user.email ?? '',
            name: name,
            role: UserRole.fromString(roleStr),
            emailConfirmedAt: _parseEmailConfirmedAt(user.emailConfirmedAt),
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
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Authentication failed');
    }
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      final roleStr = user.userMetadata?['role'] as String?;
      final name = user.userMetadata?['name'] as String? ?? '';
      return AppUser(
        id: user.id,
        email: email,
        name: name,
        role: UserRole.fromString(roleStr),
        emailConfirmedAt: _parseEmailConfirmedAt(user.emailConfirmedAt),
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.key,
      },
    );
    final user = res.user;
    if (user == null) {
      throw Exception('Sign up failed');
    }

    final newUser = AppUser(
      id: user.id,
      email: email,
      name: name,
      role: role,
      emailConfirmedAt: _parseEmailConfirmedAt(user.emailConfirmedAt),
      createdAt: DateTime.now(),
    );

    // Profile is auto-created by the on_auth_user_created DB trigger
    if (role == UserRole.worker) {
      try {
        await _client.from('users').update({'worker_status': 'pending'}).eq('id', user.id);
      } catch (e) {
        debugPrint('Warning: Could not set worker_status: $e');
      }
    }

    return newUser;
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _client.auth.updateUser(sb.AdminUserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> _fetchWorkers() async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('role', 'worker');
      _cachedWorkers = data.map((json) => AppUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('SupabaseAuthRepository - fetch workers failed: $e');
    }
  }

  @override
  List<AppUser> getAllWorkers() => _cachedWorkers;

  @override
  Future<void> refreshWorkers() async {
    await _fetchWorkers();
  }

  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {
    await _client.from('users').update({'worker_status': status}).eq('id', userId);
    final idx = _cachedWorkers.indexWhere((w) => w.id == userId);
    if (idx != -1) {
      _cachedWorkers[idx] = _cachedWorkers[idx].copyWith(workerStatus: status);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> resendVerificationEmail() async {
    final user = _client.auth.currentUser;
    if (user != null && user.emailConfirmedAt == null) {
      await _client.auth.resend(type: sb.OtpType.signup, email: user.email!);
    }
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

// 2. Mock Auth Repository Implementation (for testing & fallback)
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _mockUsers['alex.worker@phoebe.com'] = AppUser(
      id: 'mock-worker-alex',
      email: 'alex.worker@phoebe.com',
      name: 'Alex Worker',
      role: UserRole.worker,
      workerStatus: 'pending',
      emailConfirmedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      final box = Hive.box('app_preferences');
      final cachedEmail = box.get('mock_user_email') as String?;
      if (cachedEmail != null) {
        final emailKey = cachedEmail.toLowerCase();
        if (_mockUsers.containsKey(emailKey)) {
          _currentUser = _mockUsers[emailKey];
        } else {
          final name = cachedEmail.split('@').first;
          String roleStr = 'customer';
          if (name.contains('worker')) {
            roleStr = 'worker';
          } else if (name.contains('admin')) {
            roleStr = 'admin';
          } else if (name.contains('manager')) {
            roleStr = 'manager';
          }
          final role = UserRole.fromString(roleStr);
          _currentUser = AppUser(
            id: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
            email: cachedEmail,
            name: name[0].toUpperCase() + name.substring(1),
            role: role,
            workerStatus: role == UserRole.worker ? 'pending' : null,
            emailConfirmedAt: DateTime.now(),
            createdAt: DateTime.now(),
          );
          _mockUsers[emailKey] = _currentUser!;
        }
      }
    } catch (e) {
      debugPrint('MockAuthRepository - failed to restore cached user: $e');
    }

    _controller.add(_currentUser);
  }

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  final Map<String, AppUser> _mockUsers = {};

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Find or create user dynamically
    final key = email.toLowerCase();
    if (_mockUsers.containsKey(key)) {
      _currentUser = _mockUsers[key];
    } else {
      // Create user automatically for convenience in mock mode
      final name = email.split('@').first;
      String roleStr = 'customer';
      if (name.contains('worker')) {
        roleStr = 'worker';
      } else if (name.contains('admin')) {
        roleStr = 'admin';
      } else if (name.contains('manager')) {
        roleStr = 'manager';
      }
      
      final role = UserRole.fromString(roleStr);
      final newUser = AppUser(
        id: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name[0].toUpperCase() + name.substring(1),
        role: role,
        workerStatus: role == UserRole.worker ? 'pending' : null,
        emailConfirmedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      _mockUsers[key] = newUser;
      _currentUser = newUser;
    }

    try {
      final box = Hive.box('app_preferences');
      await box.put('mock_user_email', email);
    } catch (_) {}

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    final key = email.toLowerCase();
    if (_mockUsers.containsKey(key)) {
      throw Exception('Email already in use');
    }

    final newUser = AppUser(
      id: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      role: role,
      workerStatus: role == UserRole.worker ? 'pending' : null,
      emailConfirmedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    _mockUsers[key] = newUser;
    _currentUser = newUser;

    try {
      final box = Hive.box('app_preferences');
      await box.put('mock_user_email', email);
    } catch (_) {}

    _controller.add(_currentUser);

    return newUser;
  }

  @override
  List<AppUser> getAllWorkers() {
    return _mockUsers.values
        .where((u) => u.role == UserRole.worker)
        .toList();
  }

  @override
  Future<void> refreshWorkers() async {
    // Mock: already in-memory, no-op
  }

  @override
  Future<void> updateWorkerStatus({required String userId, required String status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final key = _mockUsers.entries.firstWhere(
      (e) => e.value.id == userId,
      orElse: () => MapEntry('', AppUser(id: '', email: '', name: '', role: UserRole.customer, createdAt: DateTime.now())),
    );
    if (key.key.isEmpty) return;
    final updated = _mockUsers[key.key]!.copyWith(workerStatus: status);
    _mockUsers[key.key] = updated;
    if (_currentUser?.id == userId) {
      _currentUser = updated;
      _controller.add(updated);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('MockAuthRepository - Password reset email sent to $email');
  }

  @override
  Future<void> resendVerificationEmail() async {
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('MockAuthRepository - Verification email resent');
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    debugPrint('MockAuthRepository - Password updated');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    try {
      final box = Hive.box('app_preferences');
      await box.delete('mock_user_email');
    } catch (_) {}
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

// 3. Riverpod Provider definition
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  AuthRepository repo;
  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('AuthRepository: Using MOCK implementation (credentials missing/placeholders)');
    repo = MockAuthRepository();
  } else {
    try {
      final client = SupabaseService.instance.client;
      repo = SupabaseAuthRepository(client);
    } catch (e) {
      debugPrint('AuthRepository: Failed to get Supabase client ($e). Falling back to MOCK.');
      repo = MockAuthRepository();
    }
  }

  ref.onDispose(() => repo.dispose());

  return repo;
});
