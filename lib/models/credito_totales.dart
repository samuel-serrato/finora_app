// lib/models/credito_totales.dart
class CreditoTotales {
  // Conceptos de la tabla de totales de Desktop
  final double totalMonto; // Col 1: Total a Pagar
  final double totalPagoActual; // Col 2: Total Monto (Aplicado)
  final double totalSaldoFavor; // Col 3: Saldo a Favor (Disponible)
  final double totalSaldoContraActivo; // Col 4: Saldo en Contra (Activo)
  // ▼▼▼ REEMPLAZA TU CAMPO 'totalMoratorios' CON ESTOS TRES ▼▼▼
  final double
  totalMoratoriosGenerados; // Total de moratorios que se han creado.
  final double
  totalMoratoriosPagados; // Total de moratorios que ya se han cubierto.
  final double totalMoratorios; // Este representará los moratorios PENDIENTES.
  // Conceptos de los tooltips (ⓘ) de Desktop
  final double totalRealIngresado; // Detalle de Col 2
  final double saldoFavorHistoricoTotal; // Detalle de Col 3
  final double totalSaldoContraPotencial; // Detalle de Col 4

  // Concepto útil solo para la UI de móvil
  final double totalDeudaPendiente;

  // Flag útil
  final bool hayGarantiaAplicada;

  CreditoTotales({
    required this.totalMonto,
    required this.totalPagoActual,
    required this.totalSaldoFavor,
    required this.totalSaldoContraActivo,
    // ▼▼▼ AÑADE ESTOS PARÁMETROS AL CONSTRUCTOR ▼▼▼
    required this.totalMoratoriosGenerados,
    required this.totalMoratoriosPagados,
    required this.totalMoratorios,
    required this.totalRealIngresado,
    required this.saldoFavorHistoricoTotal,
    required this.totalSaldoContraPotencial,
    required this.totalDeudaPendiente,
    required this.hayGarantiaAplicada,
  });
}
