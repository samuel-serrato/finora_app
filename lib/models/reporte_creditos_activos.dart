// models/reporte_creditos_activos.dart

class ReporteCreditosActivosResponse {
  final String accion;
  final List<ReporteCreditoActivo> data;

  ReporteCreditosActivosResponse({required this.accion, required this.data});

  factory ReporteCreditosActivosResponse.fromJson(Map<String, dynamic> json) {
    return ReporteCreditosActivosResponse(
      accion: json['accion'] ?? '',
      data:
          (json['outputPath'] as List<dynamic>?)
              ?.map((e) => ReporteCreditoActivo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ReporteCreditoActivo {
  final String idcredito;
  final String idgrupos;
  final String nombreGrupo;
  final String detalles; // Ciclo
  final String asesor;
  final String diaPago;
  final int plazo;
  final String tipoPlazo;
  final String tipo; // Individual / Grupal
  final String folio;

  // Datos financieros
  final double montoDesembolsado;
  final double montoGarantia; 
  final String porcentajeGarantia; 

  final double semanalCapital;
  final double semanalInteres;
  final double montoTotal;
  final double interesTotal;
  final double montoMasInteres;
  final double pagoCuota;
  final double totalPagos; 
  final double totalMora; // <--- NUEVO: Lo que se ha pagado de mora
  final double ti_mensual;

  // Estados
  final String numPago; 
  final String periodoPagoActual; 
  final String estadoPeriodo;
  final String estado; 
  final String fechasInicioFin;

  // Listas anidadas
  final List<FechaPagoCredito> fechas;
  final EstadoCredito? estadoCredito;
  final List<ClienteMontoInd> clientes;

  ReporteCreditoActivo({
    required this.idcredito,
    required this.idgrupos,
    required this.nombreGrupo,
    required this.detalles,
    required this.asesor,
    required this.diaPago,
    required this.plazo,
    required this.tipoPlazo,
    required this.tipo,
    required this.folio,
    required this.montoDesembolsado,
    required this.montoGarantia, 
    required this.porcentajeGarantia,
    required this.ti_mensual,

    required this.semanalCapital,
    required this.semanalInteres,
    required this.montoTotal,
    required this.interesTotal,
    required this.montoMasInteres,
    required this.pagoCuota,
    required this.totalPagos,
    required this.totalMora, // <--- NUEVO
    required this.numPago,
    required this.periodoPagoActual,
    required this.estadoPeriodo,
    required this.estado,
    required this.fechasInicioFin,
    required this.fechas,
    this.estadoCredito,
    required this.clientes,
  });

  factory ReporteCreditoActivo.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
      }
      return 0.0;
    }

    return ReporteCreditoActivo(
      idcredito: json['idcredito'] ?? '',
      idgrupos: json['idgrupos'] ?? '',
      nombreGrupo: json['nombreGrupo'] ?? 'Sin Nombre',
      detalles: json['detalles'] ?? '',
      asesor: json['asesor'] ?? '',
      diaPago: json['diaPago'] ?? '',
      plazo: json['plazo'] is int ? json['plazo'] : int.tryParse(json['plazo'].toString()) ?? 0,
      tipoPlazo: json['tipoPlazo'] ?? '',
      tipo: json['tipo'] ?? '',
      folio: json['folio'] ?? '',
      montoGarantia: parseDouble(json['montoGarantia']),
      porcentajeGarantia: json['garantia']?.toString() ?? '0%', 
      montoDesembolsado: parseDouble(json['montoDesembolsado']),
      ti_mensual: parseDouble(json['ti_mensual']),
      semanalCapital: parseDouble(json['semanalCapital']),
      semanalInteres: parseDouble(json['semanalInteres']),
      montoTotal: parseDouble(json['montoTotal']),
      interesTotal: parseDouble(json['interesTotal']),
      montoMasInteres: parseDouble(json['montoMasInteres']),
      pagoCuota: parseDouble(json['pagoCuota']),
      totalPagos: parseDouble(json['totalPagos']),
      totalMora: parseDouble(json['totalMora']), // <--- NUEVO
      numPago: json['numPago']?.toString() ?? '',
      periodoPagoActual: json['periodoPagoActual']?.toString() ?? '',
      estadoPeriodo: json['estadoPeriodo'] ?? '',
      estado: json['estado'] ?? '',
      fechasInicioFin: json['fechasIniciofin'] ?? '',
      fechas: (json['fechas'] as List<dynamic>?)?.map((e) => FechaPagoCredito.fromJson(e)).toList() ??[],
      estadoCredito: json['estado_credito'] != null ? EstadoCredito.fromJson(json['estado_credito']) : null,
      clientes: (json['clientesMontosInd'] as List<dynamic>?)?.map((e) => ClienteMontoInd.fromJson(e)).toList() ??[],
    );
  }
}

class FechaPagoCredito {
  final int numPago;
  final String fechaPago;
  final String estado;

  FechaPagoCredito({
    required this.numPago,
    required this.fechaPago,
    required this.estado,
  });

  factory FechaPagoCredito.fromJson(Map<String, dynamic> json) {
    return FechaPagoCredito(
      numPago: json['numPago'] is int ? json['numPago'] : 0,
      fechaPago: json['fechaPago'] ?? '',
      estado: json['estado'] ?? '',
    );
  }
}

class EstadoCredito {
  final double acumulado;
  final double montoTotal; // Lo que debe pagar actualmente
  final double moratorios;
  final int semanasDeRetraso;
  final String mensaje;
  final String estado;

  EstadoCredito({
    required this.acumulado,
    required this.montoTotal,
    required this.moratorios,
    required this.semanasDeRetraso,
    required this.mensaje,
    required this.estado,
  });

  factory EstadoCredito.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) => (val is num) ? val.toDouble() : 0.0;
    return EstadoCredito(
      acumulado: parse(json['acumulado']),
      montoTotal: parse(json['montoTotal']),
      moratorios: parse(json['moratorios']),
      semanasDeRetraso:
          json['semanasDeRetraso'] is int ? json['semanasDeRetraso'] : 0,
      mensaje: json['mensaje'] ?? '',
      estado: json['estado'] ?? '',
    );
  }
}

class ClienteMontoInd {
  final String idclientes;
  final String nombreCompleto;
  final String cargo;
  final double capitalIndividual;
  final double total; // Monto total a pagar individual

  ClienteMontoInd({
    required this.idclientes,
    required this.nombreCompleto,
    required this.cargo,
    required this.capitalIndividual,
    required this.total,
  });

  factory ClienteMontoInd.fromJson(Map<String, dynamic> json) {
    return ClienteMontoInd(
      idclientes: json['idclientes'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      cargo: json['cargo'] ?? '',
      capitalIndividual: (json['capitalIndividual'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
