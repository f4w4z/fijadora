enum UserRole {
  customer,
  worker,
  admin,
  manager;

  String get key => name;

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.customer;
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.customer,
    );
  }
}
