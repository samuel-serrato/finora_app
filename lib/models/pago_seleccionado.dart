class PagoSeleccionado {
  final int semana;
  final String tipoPago;
  double deposito; // Hacerlo mutable si planeas actualizarlo
  final String fechaPago;
  double? capitalMasInteres;
  List<Map<String, dynamic>> abonos; // Lista mutable
  double? saldoFavor; // Campo adicional para saldo a favor
  String? idfechaspagos; // Añadido el campo para idfechaspagos
  double? moratorio;
  double? saldoEnContra; // Añadir campo saldoEnContra

  // Constructor actualizado para incluir saldoFavor y saldoEnContra
  PagoSeleccionado({
    required this.semana,
    required this.tipoPago,
    required this.deposito,
    required this.idfechaspagos, // Añadido el campo en el constructor
    this.capitalMasInteres,
    required this.fechaPago,
    required this.saldoFavor, // Inicialización por defecto
    this.moratorio = 0.0, // Inicialización por defecto
    List<Map<String, dynamic>>? abonos,
    this.saldoEnContra = 0.0, // Inicialización por defecto
  }) : abonos = abonos ?? [];

  // Nuevo campo para monto a pagar
  double? montoAPagar;

  // Método toJson actualizado para incluir saldoFavor y saldoEnContra
  Map<String, dynamic> toJson() {
    return {
      'semana': semana,
      'tipoPago': tipoPago,
      'deposito': deposito,
      'fechaPago': fechaPago, // Convertir la fecha a ISO
      'abonos': abonos,
      'saldoFavor': saldoFavor, // Agregar saldoFavor al JSON
      'capitalMasInteres': capitalMasInteres,
      'moratorio': moratorio,
      'saldoEnContra': saldoEnContra, // Agregar saldoEnContra al JSON
    };
  }
}
