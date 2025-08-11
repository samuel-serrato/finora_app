class Usuario {
  final String idusuarios;
  final String usuario;
  final String tipoUsuario;
  final String nombreCompleto;
  final String email;
  final List<String> roles;
  final String fCreacion;

  Usuario({
    required this.idusuarios,
    required this.usuario,
    required this.tipoUsuario,
    required this.nombreCompleto,
    required this.email,
    required this.roles,
    required this.fCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idusuarios: json['idusuarios'] ?? '',
      usuario: json['usuario'] ?? '',
      tipoUsuario: json['tipoUsuario'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      email: json['email'] == null || json['email'].toString().trim().isEmpty
          ? 'No asignado'
          : json['email'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : [], // Manejo seguro de roles cuando es null
      fCreacion: json['fCreacion'] ?? '',
    );
  }
}
