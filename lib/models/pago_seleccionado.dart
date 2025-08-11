import 'package:finora_app/models/pago.dart';

class PagoSeleccionado {
  final int semana;
  final String tipoPago;
  double deposito;
  final String fechaPago;
  final String idfechaspagos;
  final String moratorioDesabilitado;
  double? capitalMasInteres;
  List<Map<String, dynamic>> abonos;
  double? saldoFavor;
  final double moratorio; // Ahora es final y se calcula en el constructor
  double? saldoEnContra;
  double? montoAPagar;

  // Nuevo campo: lista de pagos moratorios
  final List<Map<String, dynamic>> pagosMoratorios; // <--- AÑADIDO

  PagoSeleccionado({
    required this.semana,
    required this.tipoPago,
    required this.deposito,
    required this.fechaPago,
    required this.idfechaspagos,
    required this.moratorioDesabilitado,
    this.capitalMasInteres,
    this.saldoFavor = 0.0,
    double? moratorio,
    List<Map<String, dynamic>>? abonos,
    this.saldoEnContra = 0.0,
    this.montoAPagar,
    List<Map<String, dynamic>>? pagosMoratorios, // <--- AÑADIDO
  })  : abonos = abonos ?? [],
        // Forzar moratorio a 0 si está deshabilitado
        pagosMoratorios = pagosMoratorios ?? [], // <--- INICIALIZACIÓN
        moratorio = moratorioDesabilitado == "Si" ? 0.0 : (moratorio ?? 0.0);

  // Factory method para crear desde un Pago
  factory PagoSeleccionado.fromPago(Pago pago) {
    return PagoSeleccionado(
      semana: pago.semana,
      tipoPago: pago.tipoPago ?? '',
      deposito: pago.deposito ?? 0.0,
      fechaPago: pago.fechaPago ?? DateTime.now().toIso8601String(),
      idfechaspagos: pago.idfechaspagos ?? '',
      moratorioDesabilitado: pago.moratorioDesabilitado,
      capitalMasInteres: pago.capitalMasInteres,
      //saldoFavor: pago.saldoFavor ?? 0.0,
      moratorio: pago.moratorios?.moratorios ?? 0.0, // Fuente original
      abonos: pago.abonos,
      saldoEnContra: pago.saldoEnContra ?? 0.0,
      montoAPagar: pago.capitalMasInteres,
      // Carga los pagos moratorios desde el objeto Pago
      pagosMoratorios: pago.pagosMoratorios, // <--- AÑADIDO
    );
  }

  // Método para actualizar el depósito y recálculos relacionados
  void actualizarDeposito(double nuevoDeposito) {
    deposito = nuevoDeposito;
    _recalcularSaldos();
  }

  // Método privado para recálculo de saldos
  void _recalcularSaldos() {
    double totalPagado = deposito;
    double totalDeuda = (capitalMasInteres ?? 0.0) + moratorio;

    if (totalPagado > totalDeuda) {
      saldoFavor = totalPagado - totalDeuda;
      saldoEnContra = 0.0;
    } else {
      saldoFavor = 0.0;
      saldoEnContra = totalDeuda - totalPagado;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'semana': semana,
      'tipoPago': tipoPago,
      'deposito': deposito,
      'fechaPago': fechaPago,
      'idfechaspagos': idfechaspagos,
      'moratorioDesabilitado': moratorioDesabilitado,
      'capitalMasInteres': capitalMasInteres,
      'saldoFavor': saldoFavor,
      'moratorio': moratorio,
      'saldoEnContra': saldoEnContra,
      'abonos': abonos,
      'montoAPagar': montoAPagar,
    };
  }
}
