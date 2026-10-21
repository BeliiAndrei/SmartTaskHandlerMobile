import 'package:flutter/foundation.dart';

enum UserRole { administrator, user }

/// Local role selection for the L4 demo; authentication belongs to the backend.
class SessionModel extends ChangeNotifier {
  static const adminEmail = 'admin@smarttask.local';
  static const adminPassword = 'admin123';

  UserRole? _role;

  UserRole? get role => _role;
  bool get isAdministrator => _role == UserRole.administrator;

  void signIn(String email, String password) {
    _role =
        email.trim().toLowerCase() == adminEmail && password == adminPassword
        ? UserRole.administrator
        : UserRole.user;
    notifyListeners();
  }

  void register() {
    _role = UserRole.user;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    notifyListeners();
  }
}
