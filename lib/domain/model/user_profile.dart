class UserProfile {
  final String idAccount;
  final String email;
  final String nombre;
  final String rol;

  UserProfile({
    required this.idAccount,
    required this.email,
    required this.nombre,
    required this.rol,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      idAccount: json['id_account'],
      email: json['email'],
      nombre: json['nombre'],
      rol: json['rol'],
    );
  }
}
