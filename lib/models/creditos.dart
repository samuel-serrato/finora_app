import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/estado_credito.dart';
import 'package:finora_app/models/fecha_pago.dart';
import 'package:finora_app/screens/creditos.dart';

class Credito {
  final String idcredito;
  final String idgrupos;
  final String nombreGrupo;
  final String detalles;
  final String asesor;
  final String diaPago;
  final int plazo;
  final String tipoPlazo;
  final String tipo;
  final double ti_mensual;
  final String ti_semanal;
  final String folio;
  final String garantia;
  final double montoGarantia;
  final double montoDesembolsado;
  final double interesGlobal;
  final double semanalCapital;
  final double semanalInteres;
  final double montoTotal;
  final double interesTotal;
  final double montoMasInteres;
  final double pagoCuota;
  final String numPago;
  final String fechasIniciofin;
  String estado; // para json['estado'] (ej. "Finalizado")
  final String fCreacion;
  final String estadoInterno; // para estado_credito['esatado'] (ej. "Pagado")
  final List<ClienteMonto> clientesMontosInd;
  final EstadoCredito estadoCredito;

  // ---> AÑADE ESTOS DOS CAMPOS <---
  final String? periodoPagoActual; // Este es el pago actual, ej: "5 / 20"
  final List<FechaPago> fechas;   // Esta es la lista para el cronograma


  Credito({
    required this.idcredito,
    required this.idgrupos,
    required this.nombreGrupo,
    required this.detalles,
    required this.asesor,
    required this.diaPago,
    required this.plazo,
    required this.tipoPlazo,
    required this.tipo,
    required this.ti_mensual,
    required this.ti_semanal,
    required this.folio,
    required this.garantia,
    required this.montoGarantia,
    required this.montoDesembolsado,
    required this.interesGlobal,
    required this.semanalCapital,
    required this.semanalInteres,
    required this.montoTotal,
    required this.interesTotal,
    required this.montoMasInteres,
    required this.pagoCuota,
    required this.numPago,
    required this.fechasIniciofin,
    required this.estado,
    required this.fCreacion,
    required this.estadoInterno,
    required this.clientesMontosInd,
    required this.estadoCredito,
      // ---> AÑADE ESTOS DOS CAMPOS AL CONSTRUCTOR <---
    this.periodoPagoActual,
    required this.fechas,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
  return Credito(
    idcredito: json['idcredito'] ?? '',
    idgrupos: json['idgrupos'] ?? '',
    nombreGrupo: json['nombreGrupo'] ?? '',
    detalles: json['detalles'] ?? '',
    asesor: json['asesor'] ?? '',
    diaPago: json['diaPago'] ?? '',
    plazo: json['plazo'] is String
        ? int.tryParse(json['plazo']) ?? 0
        : (json['plazo'] ?? 0),
    tipoPlazo: json['tipoPlazo'] ?? '',
    tipo: json['tipo'] ?? '',
    ti_mensual: (json['ti_mensual'] as num?)?.toDouble() ?? 0.0,
    ti_semanal: json['ti_semanal'] ?? '',
    folio: json['folio'] ?? '',
    garantia: json['garantia'] ?? '',
    montoGarantia: (json['montoGarantia'] as num?)?.toDouble() ?? 0.0,
    montoDesembolsado: (json['montoDesembolsado'] as num?)?.toDouble() ?? 0.0,
    interesGlobal: (json['interesGlobal'] as num?)?.toDouble() ?? 0.0,
    semanalCapital: (json['semanalCapital'] as num?)?.toDouble() ?? 0.0,
    semanalInteres: (json['semanalInteres'] as num?)?.toDouble() ?? 0.0,
    montoTotal: (json['montoTotal'] as num?)?.toDouble() ?? 0.0,
    interesTotal: (json['interesTotal'] as num?)?.toDouble() ?? 0.0,
    montoMasInteres: (json['montoMasInteres'] as num?)?.toDouble() ?? 0.0,
    pagoCuota: (json['pagoCuota'] as num?)?.toDouble() ?? 0.0,
    numPago: json['numPago'] ?? '',
    fechasIniciofin: json['fechasIniciofin'] ?? '',
    estado: json['estado'] ?? '',
    fCreacion: (json['fCreacion'] ?? '') ?? DateTime.now(),
    estadoInterno: json['estado_credito']?['estado'] ??
        json['estado_credito']?['esatado'] ??
        '',
    clientesMontosInd: (json['clientesMontosInd'] as List? ?? [])
        .map((e) => ClienteMonto.fromJson(e))
        .toList(),
    estadoCredito: EstadoCredito.fromJson(json['estado_credito'] ?? {}),
        // ---> AÑADE ESTA LÓGICA PARA LOS NUEVOS CAMPOS <---
      periodoPagoActual: json['periodoPagoActual'] as String?,
      fechas: (json['fechas'] as List<dynamic>?)
              ?.map((f) => FechaPago.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
  );
}
}





