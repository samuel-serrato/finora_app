import 'package:finora_app/models/clientes.dart';

class Grupo {
  final String idgrupos;
  final String tipoGrupo;
  final String nombreGrupo;
  final String detalles;
  String asesor;
  final String? idusuario; // <<< CAMBIO 1: AÑADIR EL CAMPO DEL ID DEL ASESOR
  final String fCreacion;
  final String estado;
  final String folio;
  final List<ClienteResumenGrupo> clientes; 

  Grupo({
    required this.idgrupos,
    required this.tipoGrupo,
    required this.nombreGrupo,
    required this.detalles,
    required this.asesor,
    this.idusuario, // <<< CAMBIO 2: AÑADIR AL CONSTRUCTOR
    required this.fCreacion,
    required this.estado,
    required this.folio,
    required this.clientes,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    final clientesList = json['clientes'] as List? ?? [];

    return Grupo(
      idgrupos: json['idgrupos'] as String? ?? '',
      tipoGrupo: json['tipoGrupo'] as String? ?? 'N/A',
      nombreGrupo: json['nombreGrupo'] as String? ?? 'Sin Nombre',
      detalles: json['detalles'] as String? ?? '',
      asesor: json['asesor'] as String? ?? 'N/A',
      idusuario: json['idusuario'] as String?, // <<< CAMBIO 3: CAPTURAR EL VALOR DESDE EL JSON
      fCreacion: json['fCreacion'] as String? ?? DateTime.now().toIso8601String(),
      estado: json['estado'] as String? ?? 'Desconocido',
      folio: json['folio'] as String? ?? 'N/A',
      clientes: clientesList
          .map((cliente) => ClienteResumenGrupo.fromJson(cliente))
          .toList(),
    );
  }
}

// NUEVO MODELO para la CUENTA dentro del resumen de cliente
class CuentaResumen {
  final String idcuantabank;
  final String nombreBanco;
  final String numCuenta;
  final String numTarjeta;
  final String clbIntBanc;
  final String idclientes;

  CuentaResumen({
    required this.idcuantabank,
    required this.nombreBanco,
    required this.numCuenta,
    required this.numTarjeta,
    required this.clbIntBanc,
    required this.idclientes,
  });

  factory CuentaResumen.fromJson(Map<String, dynamic> json) {
    return CuentaResumen(
      idcuantabank: json['idcuantabank'] as String? ?? '',
      nombreBanco: json['nombreBanco'] as String? ?? '',
      numCuenta: json['numCuenta'] as String? ?? '',
      numTarjeta: json['numTarjeta'] as String? ?? '',
      clbIntBanc: json['clbIntBanc'] as String? ?? '',
      idclientes: json['idclientes'] as String? ?? '',
    );
  }
}

// NUEVO MODELO para el CLIENTE dentro de un GRUPO
class ClienteResumenGrupo {
  final String iddetallegrupos;
  final String idclientes;
  final String nombres;
  final String telefono;
  final String fechaNacimiento;
  final String cargo;
  final String estado;
  final CuentaResumen? cuenta; // Puede ser nulo si la API no lo envía

  ClienteResumenGrupo({
    required this.iddetallegrupos,
    required this.idclientes,
    required this.nombres,
    required this.telefono,
    required this.fechaNacimiento,
    required this.cargo,
    required this.estado,
    this.cuenta,
  });

  factory ClienteResumenGrupo.fromJson(Map<String, dynamic> json) {
    // Manejo seguro del objeto 'cuenta'
    final cuentaJson = json['cuenta'] as Map<String, dynamic>?;

    return ClienteResumenGrupo(
      iddetallegrupos: json['iddetallegrupos'] as String? ?? '',
      idclientes: json['idclientes'] as String? ?? '',
      nombres: json['nombres'] as String? ?? 'Sin Nombre',
      telefono: json['telefono'] as String? ?? 'N/A',
      // NOTA: El JSON que me pasaste tiene 'fechaNacimiento', pero tu modelo original tiene 'fechaNac'.
      // Usa el que sea correcto en tu API. Asumo 'fechaNacimiento'.
      fechaNacimiento: json['fechaNacimiento'] as String? ?? '', 
      cargo: json['cargo'] as String? ?? 'Miembro',
      estado: json['estado'] as String? ?? 'Desconocido',
      cuenta: cuentaJson != null ? CuentaResumen.fromJson(cuentaJson) : null,
    );
  }
}
