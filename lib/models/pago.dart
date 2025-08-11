// lib/models/pago.dart

import 'package:finora_app/models/moratorios.dart';
import 'package:finora_app/models/renovacion_pendiente.dart';

class Pago {
  // --- CAMPOS ESENCIALES DEL JSON (LEÍDOS DIRECTAMENTE DEL SERVIDOR) ---
  final int semana;
  String fechaPago;
  final double capitalMasInteres;
  final String estado;
  final String? idfechaspagos;
  final Moratorios? moratorios;
  String moratorioDesabilitado;
  // <<< AÑADIR ESTA LÍNEA >>>
  String moratorioEditable; // Para saber si se puede editar manualmente
  final List<Map<String, dynamic>> abonos;
  final List<RenovacionPendiente> renovacionesPendientes;
  final double sumaDepositoMoratorisos;

  // <<< CAMPOS RESTAURADOS CORRECTAMENTE >>>
  final String idpagosdetalles;
  final String idpagos;
  final double? deposito; // Monto del primer abono (si existe)
  final List<Map<String, dynamic>> pagosMoratorios;

  // --- DATOS DE SALDO A FAVOR (LEÍDOS DIRECTAMENTE DEL SERVIDOR) ---
  final double saldoFavorOriginalGenerado;
  final double favorUtilizado;
  final double saldoRestante;
  final bool fueUtilizadoPorServidor;

  // --- CAMPOS DE ESTADO PARA LA UI (ASIGNADOS LOCALMENTE) ---
  String? tipoPago;

  // --- CONSTRUCTOR ---
  Pago({
    required this.semana,
    required this.fechaPago,
    required this.capitalMasInteres,
    required this.estado,
    required this.moratorioDesabilitado,
    // <<< AÑADIR ESTA LÍNEA >>>
    required this.moratorioEditable,
    required this.abonos,
    required this.renovacionesPendientes,
    required this.sumaDepositoMoratorisos,
    required this.saldoFavorOriginalGenerado,
    required this.favorUtilizado,
    required this.saldoRestante,
    required this.fueUtilizadoPorServidor,
    // Campos opcionales
    this.idfechaspagos,
    this.moratorios,
    required this.idpagosdetalles,
    required this.idpagos,
    this.deposito,
    required this.pagosMoratorios,
  });

  // ==========================================================
  // ▼▼▼ COPIA Y PEGA ESTE BLOQUE EXACTO DENTRO DE TU CLASE ▼▼▼
  // ==========================================================

  Pago copyWith({
    int? semana,
    String? fechaPago,
    double? capitalMasInteres,
    String? estado,
    String? idfechaspagos,
    Moratorios? moratorios,
    String? moratorioDesabilitado,
        String? moratorioEditable, // <<< AÑADE ESTA LÍNEA

    List<Map<String, dynamic>>? abonos,
    List<RenovacionPendiente>? renovacionesPendientes,
    double? sumaDepositoMoratorisos,
    String? idpagosdetalles,
    String? idpagos,
    double? deposito,
    List<Map<String, dynamic>>? pagosMoratorios,
    double? saldoFavorOriginalGenerado,
    double? favorUtilizado,
    double? saldoRestante,
    bool? fueUtilizadoPorServidor,
    String? tipoPago,
  }) {
    return Pago(
        semana: semana ?? this.semana,
        fechaPago: fechaPago ?? this.fechaPago,
        capitalMasInteres: capitalMasInteres ?? this.capitalMasInteres,
        estado: estado ?? this.estado,
        idfechaspagos: idfechaspagos ?? this.idfechaspagos,
        moratorios: moratorios ?? this.moratorios,
        moratorioDesabilitado:
            moratorioDesabilitado ?? this.moratorioDesabilitado,
                  moratorioEditable: moratorioEditable ?? this.moratorioEditable, // <<< AÑADE ESTA LÍNEA

        abonos: abonos ?? List<Map<String, dynamic>>.from(this.abonos),
        renovacionesPendientes:
            renovacionesPendientes ??
            List<RenovacionPendiente>.from(this.renovacionesPendientes),
        sumaDepositoMoratorisos:
            sumaDepositoMoratorisos ?? this.sumaDepositoMoratorisos,
        idpagosdetalles: idpagosdetalles ?? this.idpagosdetalles,
        idpagos: idpagos ?? this.idpagos,
        deposito: deposito ?? this.deposito,
        pagosMoratorios:
            pagosMoratorios ??
            List<Map<String, dynamic>>.from(this.pagosMoratorios),
        saldoFavorOriginalGenerado:
            saldoFavorOriginalGenerado ?? this.saldoFavorOriginalGenerado,
        favorUtilizado: favorUtilizado ?? this.favorUtilizado,
        saldoRestante: saldoRestante ?? this.saldoRestante,
        fueUtilizadoPorServidor:
            fueUtilizadoPorServidor ?? this.fueUtilizadoPorServidor,
      )
      ..tipoPago =
          tipoPago ?? this.tipoPago; // Mantenemos la asignación del tipoPago
  }

  Pago clone() {
    return this.copyWith();
  }

  // ==========================================================
  // ▲▲▲ FIN DEL CÓDIGO A PEGAR ▲▲▲
  // ==========================================================

  // --- FACTORY FROMJSON ---
  // En: lib/models/pago.dart

// Reemplaza tu factory Pago.fromJson completo con este:
factory Pago.fromJson(Map<String, dynamic> json) {
  // Función de ayuda interna para parsear números de forma segura.
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Lógica para extraer datos del primer abono, si existe.
  final List<dynamic>? pagosList = json['pagos'] as List?;
  final String? idPagoPrincipal = (pagosList != null && pagosList.isNotEmpty)
      ? pagosList[0]['idpagos']
      : null;
  final double? depositoPrincipal = (pagosList != null && pagosList.isNotEmpty)
      ? parseDouble(pagosList[0]['deposito'])
      : null;
  
  // Lógica de parseo para las renovaciones.
  List<RenovacionPendiente> pendientes = [];
  if (json['RenovacionPendientes'] != null && json['RenovacionPendientes'] is List) {
    pendientes = (json['RenovacionPendientes'] as List)
        .map((i) => RenovacionPendiente.fromJson(i))
        .toList();
  }

  // <<< INICIO DE LA CORRECCIÓN CLAVE >>>
  // Lógica para leer el valor de `moratorioEditable` desde la lista anidada.
  String moratorioEditableValue = "No"; // Valor por defecto.
  
  // 1. Verificamos si 'pagosMoratorios' existe, es una lista y no está vacía.
  if (json['pagosMoratorios'] != null && json['pagosMoratorios'] is List && (json['pagosMoratorios'] as List).isNotEmpty) {
    // 2. Tomamos el primer objeto de la lista.
    final moratorioData = (json['pagosMoratorios'] as List).first;
    // 3. Verificamos que sea un mapa y leemos el valor, si no existe, se queda "No".
    if (moratorioData is Map<String, dynamic>) {
      moratorioEditableValue = moratorioData['moratorioEditable'] ?? "No";
    }
  }
  // <<< FIN DE LA CORRECCIÓN CLAVE >>>

  return Pago(
    semana: json['semana'] ?? 0,
    fechaPago: json['fechaPago'] ?? '',
    capitalMasInteres: parseDouble(json['capitalMasInteres']),
    estado: json['estado'] ?? '',
    moratorioDesabilitado: json['moratorioDesabilitado'] ?? "No",
    
    // Usamos el valor que acabamos de parsear de forma segura.
    moratorioEditable: moratorioEditableValue,
    
    idfechaspagos: json['idfechaspagos'],
    abonos: (json['pagos'] as List<dynamic>? ?? [])
        .map((pago) => Map<String, dynamic>.from(pago))
        .toList(),
    renovacionesPendientes: pendientes,
    sumaDepositoMoratorisos: parseDouble(json['sumaDepositoMoratorisos']),
    moratorios: json['moratorios'] is Map<String, dynamic>
        ? Moratorios.fromJson(Map<String, dynamic>.from(json['moratorios']))
        : null,
    
    // Mapeo de campos restaurados
    idpagosdetalles: json['idpagosdetalles'],
    idpagos: idPagoPrincipal ?? '',
    deposito: depositoPrincipal,
    pagosMoratorios: (json['pagosMoratorios'] as List<dynamic>? ?? [])
        .map((moratorio) => Map<String, dynamic>.from(moratorio))
        .toList(),

    // Mapeo directo de los campos de saldo a favor desde el JSON
    saldoFavorOriginalGenerado: parseDouble(json['saldoFavor']),
    favorUtilizado: parseDouble(json['favorUtilizado']),
    saldoRestante: parseDouble(json['saldoRestante']),
    fueUtilizadoPorServidor: json['saldoFavorUtilizado'] == 'Si',
    
  )..tipoPago = json['tipoPagos'] == 'sin asignar' ? null : json['tipoPagos'];
}

  // +++ AÑADE ESTE NUEVO GETTER AQUÍ +++
  double get moratoriosPagados {
    if (pagosMoratorios.isEmpty) {
      return 0.0;
    }
    // Asumimos que la información relevante está en el primer elemento de la lista.
    // Usamos 'num?' para un casteo seguro antes de convertir a double.
    return (pagosMoratorios[0]['sumaMoratorios'] as num?)?.toDouble() ?? 0.0;
  }
  // +++ FIN DEL CÓDIGO A AÑADIR +++

  // --- GETTERS PARA LÓGICA DE UI ---

  bool get estaFinalizado =>
      estado.toLowerCase().contains('pagado') ||
      estado.toLowerCase().contains('garantia pagada');

  double get saldoEnContra {
    final double totalAPagar =
        capitalMasInteres + (moratorios?.moratorios ?? 0.0);
    final double montoTotalCubierto = sumaDepositoMoratorisos + favorUtilizado;
    final double deuda = totalAPagar - montoTotalCubierto;
    return deuda > 0.01 ? deuda : 0.0;
  }

  bool get tieneMoratoriosActivos {
    return (moratorios?.moratorios ?? 0) > 0 && moratorioDesabilitado != "Si";
  }

  bool get tieneRenovacionesPendientes {
    return renovacionesPendientes.isNotEmpty;
  }

  bool tieneOpcionSaldoFavor(double saldoFavorTotalAcumulado) {
    final bool tieneDeuda = this.saldoEnContra > 0.01;
    return saldoFavorTotalAcumulado > 0.01 && tieneDeuda && !estaFinalizado;
  }
}
