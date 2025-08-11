// lib/models/cliente_model.dart
import 'dart:convert';

// ========================================================================
// CLASE PRINCIPAL CORREGIDA
// ========================================================================

// Clase principal que agrupa toda la información de un cliente.
// Útil para cuando recibes toda la info junta desde la API.
class Cliente {
  final String idCliente;
  final ClienteInfo clienteInfo;
  final CuentaBanco? cuentaBanco; // Puede ser nulo
  final Domicilio? domicilio; // <-- CAMBIO 1: Hacemos el domicilio nulable
  final DatosAdicionales? datosAdicionales; // Puede ser nulo
  final List<IngresoEgreso> ingresosEgresos;
  final List<Referencia> referencias;
  // <-- CAMBIO 1: Se añade el campo 'cargo'
  final String? cargo;
  List<HistorialGrupo> historial; // <-- Cambia a `var` o `late final` y quítalo del constructor

  Cliente({
    required this.idCliente,
    required this.clienteInfo,
    this.cuentaBanco,
    this.domicilio, // <-- Puede ser nulo
    this.datosAdicionales,
    required this.ingresosEgresos,
    required this.referencias,
    this.cargo, // <-- CAMBIO 2: Se añade al constructor
    this.historial = const [], // <-- Inicialízalo como lista vacía
  });

  // ========================================================================
  // FACTORY CORREGIDO PARA COINCIDIR CON LA ESTRUCTURA REAL DE LA API
  // ========================================================================
  factory Cliente.fromJson(Map<String, dynamic> json) {
    // Extraemos las listas anidadas primero para manejarlas de forma segura,
    // usando '?? []' para evitar errores si las claves no existen.
    final List<dynamic> adicionalesList = json['adicionales'] ?? [];
    final List<dynamic> cuentaBancoList = json['cuentabanco'] ?? [];
    // --- CAMBIO 2: LEEMOS LA LISTA DE DOMICILIOS ---
    final List<dynamic> domicilioList = json['domicilios'] ?? [];
    final List<dynamic> ingresosList = json['ingresos_egresos'] ?? [];
    final List<dynamic> referenciasList = json['referencias'] ?? [];

    return Cliente(
      idCliente: json['idclientes'] as String,
      clienteInfo: ClienteInfo.fromJson(json),

      // <-- CAMBIO 3: Se lee el campo 'cargo' del JSON
      cargo: json['cargo'] as String?,

      // --- CAMBIO 3: ASIGNAMOS EL PRIMER DOMICILIO DE LA LISTA (SI EXISTE) ---
      domicilio:
          domicilioList.isNotEmpty
              ? Domicilio.fromJson(domicilioList.first as Map<String, dynamic>)
              : null, // Si no hay domicilios, será nulo

      datosAdicionales:
          adicionalesList.isNotEmpty
              ? DatosAdicionales.fromJson(
                adicionalesList.first as Map<String, dynamic>,
              )
              : null,

      cuentaBanco:
          cuentaBancoList.isNotEmpty
              ? CuentaBanco.fromJson(
                cuentaBancoList.first as Map<String, dynamic>,
              )
              : null,

      ingresosEgresos:
          ingresosList
              .map((e) => IngresoEgreso.fromJson(e as Map<String, dynamic>))
              .toList(),

      referencias:
          referenciasList
              .map((e) => Referencia.fromJson(e as Map<String, dynamic>))
              .toList(),

    
    );
  }
}

// 1. Modelo para la información básica del cliente (SIN CAMBIOS NECESARIOS)
// Ya que lee claves específicas, funciona correctamente cuando se le pasa el JSON completo.
class ClienteInfo {
  final String? idCliente;
  final String tipoCliente;
  final String ocupacion;
  final String nombres;
  final String apellidoP;
  final String apellidoM;
  final DateTime? fechaNac;
  final String sexo;
  final String telefono;
  final String eCivil;
  final String? email;
  final int dependientesEconomicos;
  final String? nombreConyuge;
  final String? telefonoConyuge;
  final String? ocupacionConyuge;
  final String fCreacion;
  final String estado;

  ClienteInfo({
    this.idCliente,
    required this.tipoCliente,
    required this.ocupacion,
    required this.nombres,
    required this.apellidoP,
    required this.apellidoM,
    this.fechaNac,
    required this.sexo,
    required this.telefono,
    required this.eCivil,
    this.email,
    required this.dependientesEconomicos,
    this.nombreConyuge,
    this.telefonoConyuge,
    this.ocupacionConyuge,
    this.fCreacion = '',
    this.estado = 'N/A', // Proveer un valor por defecto
  });

  factory ClienteInfo.fromJson(Map<String, dynamic> json) {
    return ClienteInfo(
      idCliente: json['idclientes'],
      tipoCliente: json['tipo_cliente'] ?? '',
      ocupacion: json['ocupacion'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidoP: json['apellidoP'] ?? '',
      apellidoM: json['apellidoM'] ?? '',
      fechaNac:
          json['fechaNac'] != null ? DateTime.tryParse(json['fechaNac']) : null,
      sexo: json['sexo'] ?? '',
      telefono: json['telefono'] ?? '',
      eCivil: json['eCivil'] ?? '',
      email: json['email'],
      dependientesEconomicos:
          int.tryParse(json['dependientes_economicos']?.toString() ?? '0') ?? 0,
      nombreConyuge: json['nombreConyuge'],
      telefonoConyuge: json['telefonoConyuge'],
      ocupacionConyuge: json['ocupacionConyuge'],
      fCreacion: json['fCreacion'] ?? '',
      estado: json['estado'] ?? 'N/A', // Proveer un valor por defecto
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tipo_cliente": tipoCliente,
      "ocupacion": ocupacion,
      "nombres": nombres,
      "apellidoP": apellidoP,
      "apellidoM": apellidoM,
      "fechaNac": fechaNac?.toIso8601String().split('T').first,
      "sexo": sexo,
      "telefono": telefono,
      "eCivil": eCivil,
      "email": email,
      "dependientes_economicos": dependientesEconomicos.toString(),
      "nombreConyuge": nombreConyuge,
      "telefonoConyuge": telefonoConyuge,
      "ocupacionConyuge": ocupacionConyuge,
    };
  }
}

// 2. Modelo para la cuenta bancaria (SIN CAMBIOS NECESARIOS)
class CuentaBanco {
  final String? idclientes;
  final String nombreBanco;
  final String numCuenta;
  final String numTarjeta;
  final String clbIntBanc;

  CuentaBanco({
    this.idclientes,
    required this.nombreBanco,
    required this.numCuenta,
    required this.numTarjeta,
    required this.clbIntBanc,
  });

  factory CuentaBanco.fromJson(Map<String, dynamic> json) {
    return CuentaBanco(
      idclientes: json['idclientes'],
      nombreBanco: json['nombreBanco'] ?? '',
      numCuenta: json['numCuenta'] ?? '',
      numTarjeta: json['numTarjeta'] ?? '',
      clbIntBanc: json['clbIntBanc'] ?? '',
    );
  }

  // El método toJson es el más importante de corregir
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombreBanco': nombreBanco,
      'numCuenta': numCuenta,
      'numTarjeta': numTarjeta,
      'clbIntBanc': clbIntBanc,
    };

    // Añade el idclientes al JSON si no es nulo
    if (idclientes != null) {
      data['idclientes'] = idclientes;
    }

    return data;
  }
}

// 3. Modelo para el domicilio (SIN CAMBIOS NECESARIOS)
class Domicilio {
  final String tipoDomicilio;
  final String? nombrePropietario;
  final String? parentesco;
  final String calle;
  final String nExt;
  final String? nInt;
  final String? entreCalle;
  final String colonia;
  final String cp;
  final String estado;
  final String municipio;
  final String tiempoViviendo;

  Domicilio({
    required this.tipoDomicilio,
    this.nombrePropietario,
    this.parentesco,
    required this.calle,
    required this.nExt,
    this.nInt,
    this.entreCalle,
    required this.colonia,
    required this.cp,
    required this.estado,
    required this.municipio,
    required this.tiempoViviendo,
  });

  factory Domicilio.fromJson(Map<String, dynamic> json) {
    // NOTA: Como no vemos los campos de domicilio en el JSON de ejemplo,
    // se asume que también están en la raíz. Si estuvieran en otra sub-clave,
    // habría que ajustarlo aquí.
    return Domicilio(
      tipoDomicilio: json['tipo_domicilio'] ?? '',
      nombrePropietario: json['nombre_propietario'],
      parentesco: json['parentesco'],
      calle: json['calle'] ?? '',
      nExt: json['nExt'] ?? '',
      nInt: json['nInt'],
      entreCalle: json['entreCalle'],
      colonia: json['colonia'] ?? '',
      cp: json['cp'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      tiempoViviendo: json['tiempoViviendo'] ?? '',
    );
  }

  // CORREGIDO: Sin parámetros y más flexible para PUT
  Map<String, dynamic> toJson({int? iddomicilios}) {
    final Map<String, dynamic> data = {
      "tipo_domicilio": tipoDomicilio,
      "nombre_propietario": nombrePropietario,
      "parentesco": parentesco,
      "calle": calle,
      "nExt": nExt,
      "nInt": nInt,
      "entreCalle": entreCalle,
      "colonia": colonia,
      "cp": cp,
      "estado": estado,
      "municipio": municipio,
      "tiempoViviendo": tiempoViviendo,
    };
    if (iddomicilios != null) {
      data['iddomicilios'] = iddomicilios;
    }
    return data;
  }
}

// 4. Modelo para datos adicionales (CORRECCIÓN EN FACTORY)
class DatosAdicionales {
  final String curp;
  final String rfc;
  final String clvElector;

  DatosAdicionales({
    required this.curp,
    required this.rfc,
    required this.clvElector,
  });

  factory DatosAdicionales.fromJson(Map<String, dynamic> json) {
    return DatosAdicionales(
      curp: json['curp'] ?? '',
      rfc: json['rfc'] ?? '',
      // CORRECCIÓN: La clave en el JSON real es 'clvElector', no 'clvElector'.
      clvElector: json['clvElector'] ?? '',
    );
  }
  // CORREGIDO: Sin parámetros.
  Map<String, dynamic> toJson() {
    return {"curp": curp, "rfc": rfc, "clvElector": clvElector};
  }
}

// 5. Modelo para Ingresos/Egresos (SIN CAMBIOS NECESARIOS)
class IngresoEgreso {
  final int idinfo;
  final String tipo_info;
  final String aniosActividad;
  final String descripcion;
  final String montoSemanal;

  IngresoEgreso({
    required this.idinfo,
    required this.tipo_info,
    required this.aniosActividad,
    required this.descripcion,
    required this.montoSemanal,
  });

  factory IngresoEgreso.fromJson(Map<String, dynamic> json) {
    return IngresoEgreso(
      idinfo:
          json['idinfo'] ??
          (json['idingegr'] ??
              0), // Añado fallback por si el nombre de la clave varía
      tipo_info: json['tipo_info'] ?? '', // Añado valor por defecto
      aniosActividad: (json['años_actividad'] ?? 0).toString(),
      descripcion: json['descripcion'] ?? '',
      montoSemanal: (json['monto_semanal'] ?? 0).toString(),
    );
  }

  // CORREGIDO: Sin parámetros.
  Map<String, dynamic> toJson() {
    return {
      "idinfo": idinfo,
      "años_actividad": aniosActividad,
      "descripcion": descripcion,
      "monto_semanal": montoSemanal,
    };
  }
}

// 6. Modelo para Referencias (SIN CAMBIOS NECESARIOS)
class Referencia {
  // Datos Personales
  final String nombres;
  final String apellidoP;
  final String? apellidoM;
  final String parentesco;
  final String telefono;
  final String tiempoConocer;
  // Domicilio de la Referencia
  final String? tipoDomicilio;
  final String? nombrePropietario;
  final String? parentescoRefProp;
  final String? calle;
  final String? nExt;
  final String? nInt;
  final String? entreCalle;
  final String? colonia;
  final String? cp;
  final String? estado;
  final String? municipio;
  final String? tiempoViviendo;

  Referencia({
    required this.nombres,
    required this.apellidoP,
    this.apellidoM,
    required this.parentesco,
    required this.telefono,
    required this.tiempoConocer,
    this.tipoDomicilio,
    this.nombrePropietario,
    this.parentescoRefProp,
    this.calle,
    this.nExt,
    this.nInt,
    this.entreCalle,
    this.colonia,
    this.cp,
    this.estado,
    this.municipio,
    this.tiempoViviendo,
  });

  factory Referencia.fromJson(Map<String, dynamic> json) {
    return Referencia(
      nombres: json['nombres'] ?? '',
      apellidoP: json['apellidoP'] ?? '',
      apellidoM: json['apellidoM'],
      parentesco:
          json['parentesco'] ??
          json['parentescoRefProp'] ??
          '', // Añado fallback
      telefono: json['telefono'] ?? '',
      tiempoConocer:
          json['tiempoConocer'] ??
          (json['tiempoCo'] ?? '').toString(), // Añado fallback
      tipoDomicilio: json['tipo_domicilio'],
      nombrePropietario: json['nombre_propietario'],
      parentescoRefProp: json['parentescoRefProp'],
      calle: json['calle'],
      nExt: json['nExt'],
      nInt: json['nInt'],
      entreCalle: json['entreCalle'],
      colonia: json['colonia'],
      cp: json['cp'],
      estado: json['estado'],
      municipio: json['municipio'],
      tiempoViviendo: json['tiempoViviendo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "nombres": nombres,
      "apellidoP": apellidoP,
      "apellidoM": apellidoM,
      "parentesco": parentesco,
      "telefono": telefono,
      "tiempoConocer": tiempoConocer,
      "tipo_domicilio": tipoDomicilio,
      "nombre_propietario": nombrePropietario,
      "parentescoRefProp": parentescoRefProp,
      "calle": calle,
      "nExt": nExt,
      "nInt": nInt,
      "entreCalle": entreCalle,
      "colonia": colonia,
      "cp": cp,
      "estado": estado,
      "municipio": municipio,
      "tiempoViviendo": tiempoViviendo,
    };
  }
}

// En lib/models/clientes.dart (o donde tengas tus modelos)

class HistorialGrupo {
  final String nombreGrupo;
  final String detalles;
  final String estado;
  final String folio;
  final String tipoGrupo;
  final String isAdicional;
  final DateTime? fCreacion;

  HistorialGrupo({
    required this.nombreGrupo,
    required this.detalles,
    required this.estado,
    required this.folio,
    required this.tipoGrupo,
    required this.isAdicional,
    this.fCreacion,
  });

  factory HistorialGrupo.fromJson(Map<String, dynamic> json) {
    return HistorialGrupo(
      nombreGrupo: json['nombreGrupo'] ?? 'N/A',
      detalles: json['detalles'] ?? 'N/A',
      estado: json['estado'] ?? 'Desconocido',
      folio: json['folio'] ?? 'N/A',
      tipoGrupo: json['tipoGrupo'] ?? 'N/A',
      isAdicional: json['isAdicional']?.toString() ?? 'No',
      fCreacion:
          json['fCreacion'] != null
              ? DateTime.tryParse(json['fCreacion'])
              : null,
    );
  }
}
