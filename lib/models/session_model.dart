import 'package:flutter/foundation.dart';

enum UserRole { administrator, user }

class SessionModel extends ChangeNotifier {
  SessionModel({UserRole? initialRole}) : _role = initialRole;

  UserRole? _role;

  UserRole? get role => _role;
  bool get isAuthenticated => _role != null;
  bool get isAdministrator => _role == UserRole.administrator;

  void signIn({UserRole role = UserRole.user}) {
    _role = role;
    notifyListeners();
  }

  void register() {
    signIn();
  }

  void signOut() {
    _role = null;
    notifyListeners();
  }
}
