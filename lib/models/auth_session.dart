import 'user_role.dart';

class AuthSession {
  const AuthSession({required this.name, required this.role});

  final String name;
  final UserRole role;

  AuthSession copyWith({String? name, UserRole? role}) {
    return AuthSession(name: name ?? this.name, role: role ?? this.role);
  }
}
