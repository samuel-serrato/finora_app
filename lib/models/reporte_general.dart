import 'package:intl/intl.dart';

class ReporteGeneralData {
  final String fechaSemana;
  final String fechaActual;
  final double totalCapital;
  final double totalInteres;
  final double totalPagoficha;
  final double totalSaldoFavor;
  final double saldoMoratorio;
  final double totalTotal;
  final double restante;
  final double totalFicha;
  final List<ReporteGeneral> listaGrupos;

  ReporteGeneralData({
    required this.fechaSemana,
    required this.fechaActual,
    required this.totalCapital,
    required this.totalInteres,
    required this.totalPagoficha,
    required this.totalSaldoFavor,
    required this.saldoMoratorio,
    required this.totalTotal,
    required this.restante,
    required this.totalFicha,
    required this.listaGrupos,
  });

  factory ReporteGeneralData.fromJson(Map<String, dynamic> json) {
    double parseValor(String value) =>
        double.parse(value.replaceAll(RegExp(r'[^0-9.]'), ''));

    return ReporteGeneralData(
      fechaSemana: _formatearFechaSemana(json['fechaSemana']?? 'N/A'),
      fechaActual: json['fechaActual'] ?? 'N/A',
      totalCapital: parseValor(json['totalCapital']),
      totalInteres: parseValor(json['totalInteres']),
      totalPagoficha: parseValor(json['totalPagoficha']),
      totalSaldoFavor: parseValor(json['totalSaldoFavor']),
      saldoMoratorio: parseValor(json['saldoMoratorio']),
      totalTotal: parseValor(json['totalTotal']),
      restante: parseValor(json['restante']),
      totalFicha: parseValor(json['totalFicha']),
      listaGrupos: (json['listaGrupos'] as List)
          .map((item) => ReporteGeneral.fromJson(item))
          .toList(),
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


class ReporteGeneral {
  final int numero;
  final String tipoPago;
  final String folio;
  final String idficha;
  final String grupos;
  final double pagoficha;
  final String fechadeposito;
  final double montoficha;
  final double capitalsemanal;
  final double interessemanal;
  final double saldofavor;
  final double moratorios;
  final String garantia;

  ReporteGeneral(
      {required this.numero,
      required this.tipoPago,
      required this.folio,
      required this.idficha,
      required this.grupos,
      required this.pagoficha,
      required this.fechadeposito,
      required this.montoficha,
      required this.capitalsemanal,
      required this.interessemanal,
      required this.saldofavor,
      required this.moratorios,
      required this.garantia});

  factory ReporteGeneral.fromJson(Map<String, dynamic> json) {
    double parseValor(String value) =>
        double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    return ReporteGeneral(
        numero: json['num'] ?? 0,
        tipoPago: json['tipopago'] ?? 'N/A',
        folio: json['folio'] ?? 'N/A',
        idficha: json['idficha'] ?? 'N/A',
        grupos: json['grupos'] ?? 'N/A',
        pagoficha: parseValor(json['pagoficha']),
        fechadeposito: json['fechadeposito'] ?? 'Pendiente',
        montoficha: parseValor(json['montoficha']),
        capitalsemanal: parseValor(json['capitalsemanal']),
        interessemanal: parseValor(json['interessemanal']),
        saldofavor: parseValor(json['saldofavor']),
        moratorios: parseValor(json['moratorios']),
        garantia: json['garantia'] ?? 'N/A');
  }
}
