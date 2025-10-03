import 'package:finora_app/models/restriccion.dart'; // Importa el modelo de restricción

class Licencia {
  final String idplan;
  final String idlicencia;
  final String idnegocio;
  final String nombre;
  final String descripcion;
  final int duracionMesesPlan;
  final double precioUnitario;
  final double impuestosUnitario;
  final double totalUnitario;

  final double precioMeses;
  final double descuento;
  final double impuestos;
  final double precioTotal;
  final String metodoPago;
  final String observaciones;

  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int duracionMeses;
  final String tipoSoftware;
  final String estadoLicencia;
  final String estadoPlan;
  final List<Restriccion> restricciones;
  // <<< CAMBIO 1: AÑADE LA NUEVA PROPIEDAD PARA LA LICENCIA ENCRIPTADA >>>
  // Le damos un nombre distinto para evitar confusión con el nombre de la clase.
  final String licenciaString;

  Licencia({
    required this.idplan,
    required this.idlicencia,
    required this.idnegocio,
    required this.nombre,
    required this.descripcion,
    required this.duracionMesesPlan,
    required this.precioUnitario,
    required this.impuestosUnitario,
    required this.totalUnitario,
    required this.precioMeses,
    required this.descuento,
    required this.impuestos,
    required this.precioTotal,
    required this.metodoPago,
    required this.observaciones,
    required this.fechaInicio,
    required this.fechaFin,
    required this.duracionMeses,
    required this.tipoSoftware,
    required this.estadoLicencia,
    required this.estadoPlan,
    required this.restricciones,
    // <<< CAMBIO 2: AÑADE EL PARÁMETRO AL CONSTRUCTOR >>>
    required this.licenciaString,
  });

  factory Licencia.fromJson(Map<String, dynamic> json) {
    var restriccionesList = json['restricciones'] as List? ?? [];
    List<Restriccion> restriccionesData =
        restriccionesList.map((i) => Restriccion.fromJson(i)).toList();

    return Licencia(
      idplan: json['idplan'] ?? '',
      idlicencia: json['idlicencia'] ?? '',
      idnegocio: json['idnegocio'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      duracionMesesPlan: json['duracion_meses_plan'] ?? 0,
      precioUnitario: double.tryParse(json['precio_unitario'] ?? '0.0') ?? 0.0,
      impuestosUnitario:
          double.tryParse(json['impuestos_unitario'] ?? '0.0') ?? 0.0,
      totalUnitario: double.tryParse(json['total_unitario'] ?? '0.0') ?? 0.0,

      precioMeses: double.tryParse(json['precio_meses'] ?? '0.0') ?? 0.0,
      descuento: double.tryParse(json['descuento'] ?? '0.0') ?? 0.0,
      impuestos: double.tryParse(json['impuestos'] ?? '0.0') ?? 0.0,
      precioTotal: double.tryParse(json['precio_total'] ?? '0.0') ?? 0.0,
      metodoPago: json['metodo_pago'] ?? '',
      observaciones: json['observaciones'] ?? '',

      fechaInicio:
          DateTime.tryParse(json['fecha_inicio'] ?? '') ?? DateTime.now(),
      fechaFin: DateTime.tryParse(json['fecha_fin'] ?? '') ?? DateTime.now(),
      duracionMeses: json['duracion_meses'] ?? 0,
      tipoSoftware: json['tipoSoftware'] ?? '',
      estadoLicencia: json['estado_licencia'] ?? 'Desconocido',
      estadoPlan: json['estado_plan'] ?? 'Desconocido',
      restricciones: restriccionesData,
      // <<< CAMBIO 3: EXTRAE EL VALOR DEL JSON >>>
      // Aquí leemos el campo "licencia" y lo guardamos en nuestra nueva propiedad.
      licenciaString: json['licencia'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idplan': idplan,
      'idlicencia': idlicencia,
      'idnegocio': idnegocio,
      'nombre': nombre,
      'descripcion': descripcion,
      'duracion_meses_plan': duracionMesesPlan,
      'precio_unitario': precioUnitario.toString(),
      'impuestos_unitario': impuestosUnitario.toString(),
      'total_unitario': totalUnitario.toString(),

      'precio_meses': precioMeses.toString(),
      'descuento': descuento.toString(),
      'impuestos': impuestos.toString(),
      'precio_total': precioTotal.toString(),
      'metodo_pago': metodoPago,
      'observaciones': observaciones,

      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'duracion_meses': duracionMeses,
      'tipoSoftware': tipoSoftware,
      'estado_licencia': estadoLicencia,
      'estado_plan': estadoPlan,
      'restricciones': restricciones.map((r) => r.toJson()).toList(),
      // <<< CAMBIO 4: AÑADE EL CAMPO AL MÉTODO toJson >>>
      'licencia': licenciaString,
    };
  }
}
