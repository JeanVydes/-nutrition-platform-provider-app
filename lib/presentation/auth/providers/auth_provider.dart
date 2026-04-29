import 'package:flutter/material.dart';
import 'package:untitled2/domain/model/user_profile.dart';
import 'package:untitled2/data/remote/datasource/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserProfile? _userProfile;
  String? _token;

  AuthProvider() {
    // Wire the 401 interceptor so expired tokens auto-redirect to login
    ApiService.on401 = handle401;
  }

  UserProfile? get currentProfile => _userProfile;
  String? get token => _token;
  String get activeAccountId => _userProfile?.idAccount ?? '';
  bool get isLogged => _token != null && _token!.trim().isNotEmpty;

  Future<void> requestPin(String identifier) async {
    await ApiService.requestSecurityPin(identifier);
  }

  Future<bool> loginWithPin({
    required String identifier,
    required String pin,
  }) async {
    final token = await ApiService.loginWithSecurityPin(
      identifier: identifier,
      pin: pin,
    );
    _token = token;
    _userProfile = await ApiService.getSecurityMe();

    if (_userProfile == null || _userProfile!.idAccount.trim().isEmpty) {
      debugPrint('[AuthProvider] Login succeeded but no accountId was resolved from /me');
      throw Exception('No se pudo obtener el ID de cuenta del servicio de seguridad. Contacta soporte.');
    }

    notifyListeners();
    return true;
  }

  /// Dev-only: skip OTP, use existing JWT directly.
  Future<bool> loginWithDevToken(String token) async {
    ApiService.setAccessToken(token);
    _token = token;
    _userProfile = await ApiService.getSecurityMe();

    if (_userProfile == null || _userProfile!.idAccount.trim().isEmpty) {
      debugPrint('[AuthProvider] Dev login succeeded but no accountId was resolved from /me');
      throw Exception('No se pudo obtener el ID de cuenta del servicio de seguridad.');
    }

    notifyListeners();
    return true;
  }

  /// Called by ApiService when a 401 is received — clears session,
  /// auth gate will automatically redirect to login.
  void handle401() {
    if (!isLogged) return;
    _userProfile = null;
    _token = null;
    ApiService.clearAccessToken();
    notifyListeners();
  }

  void logout() {
    _userProfile = null;
    _token = null;
    ApiService.clearAccessToken();
    notifyListeners();
  }
}
