import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../models/user_role.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthSession?>(
  AuthController.new,
);

class AuthController extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  void login({required String name, required UserRole role}) {
    state = AuthSession(name: name, role: role);
  }

  void logout() {
    state = null;
  }
}
