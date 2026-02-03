// reporte_general.dart

import 'package:intl/intl.dart';
import '../utils/app_logger.dart';

// --- CLASE MODIFICADA: Deposito ---
// Se añaden los nuevos campos para el saldo global.
class Deposito {
  final double monto;
  final String fecha;
  final String garantia;
  final double favorUtilizado;
  final double saldofavor;
  final double saldoUtilizado;
  final double saldoDisponible;
  final String utilizadoPago;
  // --- CAMBIO 1: AÑADIR NUEVOS CAMPOS ---
  final String esSaldoGlobal;
  final double saldoGlobal;

  Deposito({
    required this.monto,
    required this.fecha,
    required this.garantia,
    required this.favorUtilizado,
    required this.saldofavor,
    required this.saldoUtilizado,
    required this.saldoDisponible,
    required this.utilizadoPago,
    // --- CAMBIO 2: AÑADIR AL CONSTRUCTOR ---
    required this.esSaldoGlobal,
    required this.saldoGlobal,
  });

  factory Deposito.fromJson(Map<String, dynamic> json) {
    return Deposito(
      monto: (json['deposito'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fechaDeposito']?.toString() ?? 'Sin fecha',
      garantia: json['garantia']?.toString() ?? 'No',
      favorUtilizado: (json['favorUtilizado'] as num?)?.toDouble() ?? 0.0,
      saldofavor: (json['saldofavor'] as num?)?.toDouble() ?? 0.0,
      saldoUtilizado: (json['saldoUtilizado'] as num?)?.toDouble() ?? 0.0,
      saldoDisponible: (json['saldoDisponible'] as num?)?.toDouble() ?? 0.0,
      utilizadoPago: json['utilizadoPago']?.toString() ?? 'No',
      // --- CAMBIO 3: LEER LOS NUEVOS VALORES DEL JSON ---
      esSaldoGlobal: json['esSaldoGlobal']?.toString() ?? 'No',
      saldoGlobal: (json['saldoGlobal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- El resto de las clases (ReporteGeneral, ReporteGeneralData) no necesitan cambios ---
// Ya que el cambio se propaga automáticamente a través de la factoría Deposito.fromJson.

// ... (El resto del archivo permanece igual)
class ReporteGeneral {
  final int numero;
  final String tipoPago;
  final String folio;
  final String idficha;
  final String grupos; // <--- CAMPO AÑADIDO QUE FALTABA
  final double pagoficha;
  final double montoficha;
  final double capitalsemanal;
  final double interessemanal;
  final double saldofavor;
  final double moratorios;
  final double moratoriosAPagar;
  final double sumaMoratorio;
  final double depositoCompleto;

  final double favorUtilizado;
  final double saldoUtilizado;
  final double saldoDisponible;
  final String utilizadoPago;

  final List<Deposito> depositos;
   // === NUEVO CAMPO AÑADIDO ===
  final double restanteFicha;

  ReporteGeneral({
    required this.numero,
    required this.tipoPago,
    required this.folio,
    required this.idficha,
    required this.grupos, // <--- AHORA ESTE TIENE UN CAMPO CORRESPONDIENTE
    required this.pagoficha,
    required this.montoficha,
    required this.capitalsemanal,
    required this.interessemanal,
    required this.saldofavor,
    required this.moratorios,
    required this.moratoriosAPagar,
    required this.sumaMoratorio,
    required this.depositoCompleto,
    required this.depositos,
    required this.favorUtilizado,
    required this.saldoUtilizado,
    required this.saldoDisponible,
    required this.utilizadoPago,
     // === AÑADIDO AL CONSTRUCTOR ===
    required this.restanteFicha,
  });

  // El método factory ReporteGeneral.fromJson() ya estaba correcto y no necesita cambios.
  factory ReporteGeneral.fromJson(Map<String, dynamic> json) {
    double parseValor(String value) =>
        double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    final moratoriosData = json['Moratorios'] as Map<String, dynamic>?;
    final pagofichaData = json['pagoficha'] as Map<String, dynamic>?;

    List<Deposito> listaDepositos = [];
    if (pagofichaData != null && pagofichaData['depositos'] is List) {
      listaDepositos =
          (pagofichaData['depositos'] as List)
              .map((depositoJson) => Deposito.fromJson(depositoJson))
              .toList();
    }

    final double sumaDepositos =
        (pagofichaData?['sumaDeposito'] as num?)?.toDouble() ?? 0.0;
    final double favorUsado =
        (pagofichaData?['favorUtilizado'] as num?)?.toDouble() ?? 0.0;
    final double pagoTotalReal = sumaDepositos + favorUsado;

    return ReporteGeneral(
      numero: json['num'] ?? 0,
      tipoPago: json['tipopago'] ?? 'N/A',
      folio: json['folio'] ?? 'N/A',
      idficha: json['idficha'] ?? 'N/A',
      grupos:
          json['grupos'] ??
          'N/A', // <-- Esta línea ya leía el dato correctamente
      montoficha: parseValor(json['montoficha'] ?? '0.0'),
      capitalsemanal: parseValor(json['capitalsemanal'] ?? '0.0'),
      interessemanal: parseValor(json['interessemanal'] ?? '0.0'),
      //saldofavor: parseValor(json['saldofavor'] ?? '0.0'),
      saldofavor: (pagofichaData?['saldofavor'] as num?)?.toDouble() ?? 0.0,
      moratorios: parseValor(json['moratoriosPagados'] ?? '0.0'),
      pagoficha: pagoTotalReal,
      moratoriosAPagar:
          (moratoriosData?['moratoriosAPagar'] as num?)?.toDouble() ?? 0.0,
      sumaMoratorio:
          (pagofichaData?['sumaMoratorio'] as num?)?.toDouble() ?? 0.0,
      depositoCompleto:
          parseValor(json['depositoCompleto'] ?? '0.0') != 0.0
              ? parseValor(json['depositoCompleto'] ?? '0.0')
              : (pagofichaData?['depositoCompleto'] as num?)?.toDouble() ?? 0.0,
      depositos: listaDepositos,
      favorUtilizado: favorUsado,
      saldoUtilizado:
          (pagofichaData?['saldoUtilizado'] as num?)?.toDouble() ?? 0.0,
      saldoDisponible:
          (pagofichaData?['saldoDisponible'] as num?)?.toDouble() ?? 0.0,
      utilizadoPago: pagofichaData?['utilizadoPago']?.toString() ?? 'No',
       // === LEER EL NUEVO VALOR DEL JSON ===
      restanteFicha: (json['restanteFicha'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReporteGeneralData {
  final String fechaSemana;
  final String fechaActual;
  final double totalCapital;
  final double totalInteres;
  final double totalPagoficha;
  final double totalSaldoFavor;
  final double totalSaldoDisponible;
  final double saldoMoratorio;
  final double totalTotal;
  final double restante;
  final double totalFicha;
  final double sumaTotalCapMoraFav;
  final List<ReporteGeneral> listaGrupos;

  ReporteGeneralData({
    required this.fechaSemana,
    required this.fechaActual,
    required this.totalCapital,
    required this.totalInteres,
    required this.totalPagoficha,
    required this.totalSaldoFavor,
    required this.totalSaldoDisponible, // --- NUEVO: Añadido al constructor ---
    required this.saldoMoratorio,
    required this.totalTotal,
    required this.restante,
    required this.totalFicha,
    required this.sumaTotalCapMoraFav,
    required this.listaGrupos,
  });

  factory ReporteGeneralData.fromJson(Map<String, dynamic> json) {
    double parseValor(String value) =>
        double.parse(value.replaceAll(RegExp(r'[^0-9.]'), ''));

    var rawListaGrupos = json['listaGrupos'] as List? ?? [];
    List<ReporteGeneral> reportesProcesados = [];
    if (rawListaGrupos.isNotEmpty && rawListaGrupos.first['pagoficha'] is Map) {
      reportesProcesados =
          rawListaGrupos.map((item) => ReporteGeneral.fromJson(item)).toList();
    } else {
      AppLogger.log("Formato de listaGrupos no reconocido o vacío.");
    }

    return ReporteGeneralData(
      fechaSemana: _formatearFechaSemana(json['fechaSemana'] ?? 'N/A'),
      fechaActual: json['fechaActual'] ?? 'N/A',
      totalCapital: parseValor(json['totalCapital']),
      totalInteres: parseValor(json['totalInteres']),
      totalPagoficha: parseValor(json['totalPagoficha']),
      totalSaldoFavor: parseValor(json['totalSaldoFavor']),
      totalSaldoDisponible: parseValor(json['totalSaldoDisponible'] ?? '0.0'),
      saldoMoratorio: parseValor(json['saldoMoratorio']),
      totalTotal: parseValor(json['totalTotal']),
      restante: parseValor(json['restante']),
      totalFicha: parseValor(json['totalFicha']),
      sumaTotalCapMoraFav: parseValor(json['sumaTotalCapMoraFav']),
      listaGrupos: reportesProcesados,
    );
  }
}

String _formatearFechaSemana(String fechaOriginal) {
  try {
    final partes = fechaOriginal.split(' - ');
    final fechaInicio = partes[0].split(' ')[0];
    final fechaFin = partes[1].split(' ')[0];

    final formateador = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es');

    final inicio = formateador.format(DateTime.parse(fechaInicio));
    final fin = formateador.format(DateTime.parse(fechaFin));

    return '$inicio - $fin';
  } catch (e) {
    return fechaOriginal; // En caso de error, devolver original
  }
}
