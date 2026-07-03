import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/property_occupants_repository.dart';
import '../../../../domain/models/property.dart';
import '../../../../domain/models/user_role.dart';
import '../../auth/view_models/auth_view_model.dart';

final homePropertyProvider = FutureProvider<Property?>((ref) async {
  final user = ref.watch(authViewModelProvider).user;
  if (user == null) return null;
  final propRepo = ref.watch(propertiesRepositoryProvider);

  // Managers/admins: look up properties by manager_id
  if (user.role == UserRole.manager || user.role == UserRole.admin) {
    try {
      final properties = await propRepo.streamProperties(user.id).first;
      if (properties.isNotEmpty) return properties.first;
    } catch (_) {}
    return null;
  }

  // Customers/workers: look up property via occupants table
  try {
    final occRepo = ref.watch(propertyOccupantsRepositoryProvider);
    final occupants = await occRepo.streamByUser(user.id).first;
    if (occupants.isEmpty) return null;
    return propRepo.fetchPropertyById(occupants.first.propertyId);
  } catch (_) {
    return null;
  }
});
