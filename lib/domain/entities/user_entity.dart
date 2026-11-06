class UserEntity {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final bool isGoogleLinked;
  final bool isBiometricEnabled;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.isGoogleLinked = false,
    this.isBiometricEnabled = false,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    bool? isGoogleLinked,
    bool? isBiometricEnabled,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
