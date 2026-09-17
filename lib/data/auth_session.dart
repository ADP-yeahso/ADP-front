import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthSession extends ChangeNotifier {
  AuthTokens? _tokens;

  AuthTokens? get tokens => _tokens;
  bool get isAuthenticated => _tokens != null;

  void signIn(AuthTokens tokens) {
    _tokens = tokens;
    notifyListeners();
  }

  void signOut() {
    _tokens = null;
    notifyListeners();
  }
}
