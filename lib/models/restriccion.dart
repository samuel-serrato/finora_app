// models/restriccion.dart

class Restriccion {
  final String nombre;
  final String fCreacion;
  final String restriccion;
  final String idrestriccion;
  final String tipoARestringir;

  Restriccion({
    required this.nombre,
    required this.fCreacion,
    required this.restriccion,
    required this.idrestriccion,
    required this.tipoARestringir,
  });

  factory Restriccion.fromJson(Map<String, dynamic> json) {
    return Restriccion(
      nombre: json['nombre'] ?? '',
      fCreacion: json['fCreacion'] ?? '',
      restriccion: json['restriccion'] ?? '0',
      idrestriccion: json['idrestriccion'] ?? '',
      tipoARestringir: json['tipoARestringir'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'fCreacion': fCreacion,
      'restriccion': restriccion,
      'idrestriccion': idrestriccion,
      'tipoARestringir': tipoARestringir,
    };
  }
}