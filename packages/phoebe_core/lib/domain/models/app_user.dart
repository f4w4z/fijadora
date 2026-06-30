import 'package:flutter/foundation.dart';
import 'user_role.dart';

@immutable
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.key,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
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
          role == other.role;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, name: $name, role: $role)';
  }
}
