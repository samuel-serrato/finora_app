import 'package:intl/intl.dart';

class ParseHelpers {
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Eliminar comas y símbolos de moneda
      String cleanedValue =
          value.replaceAll(RegExp(r'[^0-9.]'), '').replaceAll(',', '');
      return double.tryParse(cleanedValue) ?? 0.0;
    }
    return 0.0;
  }

  static List<T> parseList<T>(dynamic data, T Function(dynamic) converter) {
    if (data == null) return [];
    if (data is! List) return [];
    try {
      return data.map((item) => converter(item)).toList();
    } catch (e) {
      return [];
    }
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

class ReporteContableData {
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
  final List<ReporteContableGrupo> listaGrupos;

  ReporteContableData({
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

  factory ReporteContableData.fromJson(Map<String, dynamic> json) {
    print('JSON recibido en fromJson:');
    print('Keys disponibles: ${json.keys}');
    print('¿Existe fechaSemana? ${json.containsKey('fechaSemana')}');
    print('¿Existe listaGrupos? ${json.containsKey('listaGrupos')}');
    return ReporteContableData(
      fechaSemana: _formatearFechaSemana(json['fechaSemana'] ?? 'N/A'),
      fechaActual: json['fechaActual'] ?? '',
      totalCapital: ParseHelpers.parseDouble(json['totalCapital']),
      totalInteres: ParseHelpers.parseDouble(json['totalInteres']),
      totalPagoficha: ParseHelpers.parseDouble(json['totalPagoficha']),
      totalSaldoFavor: ParseHelpers.parseDouble(json['totalSaldoFavor']),
      saldoMoratorio: ParseHelpers.parseDouble(json['saldoMoratorio']),
      totalTotal: ParseHelpers.parseDouble(json['totalTotal']),
      restante: ParseHelpers.parseDouble(json['restante']),
      totalFicha: ParseHelpers.parseDouble(json['totalFicha']),
      listaGrupos: ParseHelpers.parseList(
        json['listaGrupos'],
        (item) => ReporteContableGrupo.fromJson(item),
      ),
    );
  }
}

class ReporteContableGrupo {
  final int num;
  final String tipopago;
  final int plazo;
  final double tazaInteres;
  final String folio;
  final int pagoPeriodo;
  final String grupos;
  final String estado;
  final Pagoficha pagoficha;
  final String garantia;
  final double montoDesembolsado;
  final double montoSolicitado;
  final double interesCredito;
  final double montoARecuperar;
  final double restanteGlobal;
  final double montoficha;
  final double restanteFicha;
  final double capitalsemanal;
  final double interessemanal;
  final double saldoGlobal;
  final List<Cliente> clientes;

  ReporteContableGrupo({
    required this.num,
    required this.tipopago,
    required this.plazo,
    required this.tazaInteres,
    required this.folio,
    required this.pagoPeriodo,
    required this.grupos,
    required this.estado,
    required this.pagoficha,
    required this.garantia,
    required this.montoDesembolsado,
    required this.montoSolicitado,
    required this.interesCredito,
    required this.montoARecuperar,
    required this.restanteGlobal,
    required this.montoficha,
    required this.restanteFicha,
    required this.capitalsemanal,
    required this.interessemanal,
    required this.saldoGlobal,
    required this.clientes,
  });

  factory ReporteContableGrupo.fromJson(Map<String, dynamic> json) {
    return ReporteContableGrupo(
      num: json['num'] ?? 0,
      tipopago: json['tipopago'] ?? '',
      plazo: json['plazo'] ?? 0,
      tazaInteres: ParseHelpers.parseDouble(json['taza_interes']),
      folio: json['folio'] ?? '',
      pagoPeriodo: json['pagoPeriodo'] ?? 0,
      grupos: json['grupos'] ?? '',
      estado: json['estado'] ?? '',
      pagoficha: Pagoficha.fromJson(json['pagoficha'] ?? {}),
      garantia: json['garantia'] ?? '',
      montoDesembolsado: ParseHelpers.parseDouble(json['montoDesembolsado']),
      montoSolicitado: ParseHelpers.parseDouble(json['montoSolicitado']),
      interesCredito: ParseHelpers.parseDouble(json['interesCredito']),
      montoARecuperar: ParseHelpers.parseDouble(json['montoARecuperar']),
      restanteGlobal: ParseHelpers.parseDouble(json['restanteGlobal']),
      montoficha: ParseHelpers.parseDouble(json['montoficha']),
      restanteFicha: ParseHelpers.parseDouble(json['restanteFicha']),
      capitalsemanal: ParseHelpers.parseDouble(json['capitalsemanal']),
      interessemanal: ParseHelpers.parseDouble(json['interessemanal']),
      saldoGlobal: ParseHelpers.parseDouble(json['saldoGlobal']),
      clientes: ParseHelpers.parseList(
        json['clientes'],
        (item) => Cliente.fromJson(item),
      ),
    );
  }
}

class Pagoficha {
  final String idpagosdetalles;
  final String idgrupos;
  final int semanaPago;
  final String fechasPago;
  final double sumaDeposito;
  final List<Deposito> depositos;

  Pagoficha({
    required this.idpagosdetalles,
    required this.idgrupos,
    required this.semanaPago,
    required this.fechasPago,
    required this.sumaDeposito,
    required this.depositos,
  });

  factory Pagoficha.fromJson(Map<String, dynamic> json) {
    return Pagoficha(
      idpagosdetalles: json['idpagosdetalles']?.toString() ?? '',
      idgrupos: json['idgrupos']?.toString() ?? '',
      semanaPago: json['semanaPago'] ?? 0,
      fechasPago: json['fechasPago']?.toString() ?? '',
      sumaDeposito: ParseHelpers.parseDouble(json['sumaDeposito']),
      depositos: ParseHelpers.parseList(
        json['depositos'],
        (item) => Deposito.fromJson(item),
      ),
    );
  }
}

class Deposito {
  final double deposito;
  final double saldofavor;
  final double pagoMoratorio;
  final String garantia;
  final String fechaDeposito;

  Deposito({
    required this.deposito,
    required this.saldofavor,
    required this.pagoMoratorio,
    required this.garantia,
    required this.fechaDeposito,
  });

  factory Deposito.fromJson(Map<String, dynamic> json) {
    return Deposito(
      deposito: ParseHelpers.parseDouble(json['deposito']),
      saldofavor: ParseHelpers.parseDouble(json['saldofavor']),
      pagoMoratorio: ParseHelpers.parseDouble(json['pagoMoratorio']),
      garantia: json['garantia'] ?? 'No',
      fechaDeposito: json['fechaDeposito'] ?? '', // Parse the new field
    );
  }
}

class Cliente {
  final String nombreCompleto;
  final double montoIndividual;
  final double periodoCapital;
  final double periodoInteres;
  final double totalCapital;
  final double interesTotal;
  final double capitalMasInteres;
  final double totalFicha;

  Cliente({
    required this.nombreCompleto,
    required this.montoIndividual,
    required this.periodoCapital,
    required this.periodoInteres,
    required this.totalCapital,
    required this.interesTotal,
    required this.capitalMasInteres,
    required this.totalFicha,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      nombreCompleto: json['nombreCompleto'] ?? '',
      montoIndividual: ParseHelpers.parseDouble(json['montoIndividual']),
      periodoCapital: ParseHelpers.parseDouble(json['periodoCapital']),
      periodoInteres: ParseHelpers.parseDouble(json['periodoInteres']),
      totalCapital: ParseHelpers.parseDouble(json['totalCapital']),
      interesTotal: ParseHelpers.parseDouble(json['interesTotal']),
      capitalMasInteres: ParseHelpers.parseDouble(json['capitalMasInteres']),
      totalFicha: ParseHelpers.parseDouble(json['totalFicha']),
    );
  }
}
