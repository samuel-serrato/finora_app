// En: lib/models/pago.dart (o en su propio archivo lib/models/abono.dart)

// +++ AÑADE ESTA NUEVA CLASE COMPLETA +++

class Abono {
  final String idpagos;
  final String idpagosdetalles;
  final String fechaDeposito;
  final double deposito;
  final String garantia; // "Si" o "No"
  final String moratorio; // "Si" o "No"

  Abono({
    required this.idpagos,
    required this.idpagosdetalles,
    required this.fechaDeposito,
    required this.deposito,
    required this.garantia,
    required this.moratorio,
  });

  factory Abono.fromJson(Map<String, dynamic> json) {
    // Función de ayuda para parsear el depósito de forma segura
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Abono(
      idpagos: json['idpagos'] ?? '',
      idpagosdetalles: json['idpagosdetalles'] ?? '',
      fechaDeposito: json['fechaDeposito'] ?? '',
      deposito: parseDouble(json['deposito']),
      garantia: json['garantia'] ?? 'No',
      moratorio: json['moratorio'] ?? 'No', // Leemos el campo clave
    );
  }
}