import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/models/user_role.dart';

class AppConfig {
  final String label;
  final List<UserRole> allowedRoles;

  const AppConfig._(this.label, this.allowedRoles);

  static const customer = AppConfig._('customer', [UserRole.customer]);
  static const worker = AppConfig._('worker', [UserRole.worker]);
  static const staff = AppConfig._('staff', [UserRole.admin, UserRole.manager]);
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.customer);
