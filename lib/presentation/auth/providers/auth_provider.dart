import 'package:flutter/material.dart';
import 'package:untitled2/core/constants/env.dart';
import 'package:untitled2/domain/model/user_profile.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _userProfile;

  UserProfile get _mockProfile => UserProfile(
        idAccount: Env.defaultAccountId,
        email: 'offline@local',
        nombre: 'Usuario Offline',
        rol: 'DuenoProvider',
      );

  UserProfile? get currentProfile => _userProfile;

  UserProfile get effectiveProfile => _userProfile ?? _mockProfile;

  String get activeAccountId => effectiveProfile.idAccount;

  bool get isLogged => _userProfile != null;

  Future<bool> login(String email, String password) async {
    try {
      final profile = await ApiService.login(email, password);
      _userProfile = profile ?? _mockProfile;
      notifyListeners();
      return true;
    } catch (_) {
      _userProfile = _mockProfile;
      notifyListeners();
      return true;
    }
  }

  void logout() {
    _userProfile = null;
    notifyListeners();
  }
}
