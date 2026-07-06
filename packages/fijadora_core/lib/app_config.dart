import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/models/user_role.dart';

class AppConfig {
  final String label;
  final List<UserRole> allowedRoles;
  final UserRole signUpRole;
  final bool canRegister;

  const AppConfig._(this.label, this.allowedRoles, this.signUpRole, this.canRegister);

  static const customer = AppConfig._('customer', [UserRole.customer], UserRole.customer, true);
  static const worker = AppConfig._('worker', [UserRole.worker], UserRole.worker, true);
  static const staff = AppConfig._('staff', [UserRole.admin, UserRole.manager], UserRole.admin, false);
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.customer);
