import 'package:flutter/foundation.dart';

class UserProfile {
  final String idAccount;
  final String? email;
  final String? phone;
  final String? nombres;
  final String? apellidos;
  final List<String> roles;

  UserProfile({
    required this.idAccount,
    this.email,
    this.phone,
    this.nombres,
    this.apellidos,
    this.roles = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      idAccount: (json['id_account'] ?? json['idAccount'] ?? json['id'] ?? '').toString(),
      email: json['email']?.toString(),
      nombres: json['nombre']?.toString(),
      roles: json['rol'] != null ? [json['rol'].toString()] : const [],
    );
  }

  factory UserProfile.fromSecurityMe(Map<String, dynamic> json) {
    final datos = json['datos'] as Map<String, dynamic>? ?? {};
    final roles = (datos['roles'] as List?)?.map((r) => r.toString()).toList() ?? const [];

    // Try multiple possible keys for the account/user ID
    final resolvedId = (datos['idUsuario'] ?? datos['id'] ?? datos['idAccount'] ?? datos['id_account'])?.toString() ?? '';

    if (resolvedId.isEmpty) {
      debugPrint('[UserProfile] WARNING: No account ID found in /me response. Keys present: ${datos.keys.toList()}');
    }

    return UserProfile(
      idAccount: resolvedId,
      email: datos['correo']?.toString(),
      phone: datos['celular']?.toString(),
      nombres: datos['primerNombre']?.toString(),
      apellidos: datos['primerApellido']?.toString(),
      roles: roles,
    );
  }

  String get nombreCompleto {
    final parts = [nombres, apellidos].whereType<String>().where((v) => v.trim().isNotEmpty).toList();
    if (parts.isEmpty) return email ?? phone ?? 'Usuario';
    return parts.join(' ');
  }

  String get rolLabel => roles.isNotEmpty ? roles.join(', ') : 'Sin rol';
}

