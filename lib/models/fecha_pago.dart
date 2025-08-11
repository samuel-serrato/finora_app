// Archivo: models/fecha_pago.dart

class FechaPago {
  final int numPago;
  final String fechaPago;
  final String estado;

  FechaPago({
    required this.numPago,
    required this.fechaPago,
    required this.estado,
  });

  factory FechaPago.fromJson(Map<String, dynamic> json) {
    return FechaPago(
      numPago: json['numPago'] ?? 0,
      fechaPago: json['fechaPago'] ?? '',
      estado: json['estado'] ?? '',
    );
  }
}