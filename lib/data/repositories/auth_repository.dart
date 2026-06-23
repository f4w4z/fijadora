import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> signOut();
}

// 1. Supabase Auth Repository Implementation
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client) {
    _initStream();
  }

  final sb.SupabaseClient _client;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  void _initStream() {
    _client.auth.onAuthStateChange.listen((data) async {
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
    );

    // Write profile to database users table
    try {
      await _client.from('users').insert(newUser.toJson());
    } catch (e) {
      debugPrint('Warning: Could not insert profile row in DB: $e');
    }

    return newUser;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

// 2. Mock Auth Repository Implementation (for testing & fallback)
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    // Add initial null state
    _controller.add(null);
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
      
      final newUser = AppUser(
        id: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name[0].toUpperCase() + name.substring(1),
        role: UserRole.fromString(roleStr),
      );
      _mockUsers[key] = newUser;
      _currentUser = newUser;
    }

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
    );

    _mockUsers[key] = newUser;
    _currentUser = newUser;
    _controller.add(_currentUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _controller.add(null);
  }
}

// 3. Riverpod Provider definition
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isEmpty || anonKey.isEmpty || url.contains('placeholder')) {
    debugPrint('AuthRepository: Using MOCK implementation (credentials missing/placeholders)');
    return MockAuthRepository();
  }

  try {
    final client = SupabaseService.instance.client;
    return SupabaseAuthRepository(client);
  } catch (e) {
    debugPrint('AuthRepository: Failed to get Supabase client ($e). Falling back to MOCK.');
    return MockAuthRepository();
  }
});
