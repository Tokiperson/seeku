class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? avatarUrl;
}

class UserSession {
  const UserSession({
    required this.profile,
    required this.accessToken,
    required this.expiresAt,
  });

  final AccountProfile profile;
  final String accessToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

abstract class AccountClient {
  const AccountClient();

  Future<UserSession?> restoreSession();
  Future<UserSession> signIn();
  Future<void> signOut();
}
