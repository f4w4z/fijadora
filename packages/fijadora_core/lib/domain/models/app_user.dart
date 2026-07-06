import 'package:flutter/foundation.dart';
import 'user_role.dart';

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? workerStatus;
  final DateTime? emailConfirmedAt; // sourced from auth.users, not public.users
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.workerStatus,
    this.emailConfirmedAt,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      workerStatus: json['worker_status'] as String?,
      emailConfirmedAt: json['email_confirmed_at'] != null ? DateTime.parse(json['email_confirmed_at'] as String) : null, // from auth.users
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.key,
      'worker_status': workerStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? workerStatus,
    DateTime? emailConfirmedAt,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      workerStatus: workerStatus ?? this.workerStatus,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          workerStatus == other.workerStatus &&
          emailConfirmedAt == other.emailConfirmedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ role.hashCode ^ workerStatus.hashCode ^ createdAt.hashCode;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, name: $name, role: $role, workerStatus: $workerStatus)';
  }
}
