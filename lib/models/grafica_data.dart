// lib/models/grafica_data.dart

import 'dart:convert';

/// Clase contenedora para la respuesta completa de la API de la gráfica.
/// Contiene la lista de puntos y los totales calculados.
class GraficaResponse {
  final List<GraficaPunto> puntos;
  final double sumaTotal;
  final double sumaTotalIdeal; // Campo añadido para el total ideal

  GraficaResponse({
    required this.puntos,
    required this.sumaTotal,
    required this.sumaTotalIdeal, // Añadido al constructor
  });

  /// Constructor factory para crear una instancia de GraficaResponse desde un JSON.
  /// También se encarga de ordenar los puntos por fecha.
  factory GraficaResponse.fromJson(List<dynamic> json) {
    // Valida que la respuesta tenga el formato esperado (lista con al menos 2 elementos)
    if (json.length < 2) {
      throw const FormatException("La respuesta JSON de la gráfica es inválida.");
    }
    
    // El primer elemento es la lista de puntos
    final List<dynamic> puntosJson = json[0] as List<dynamic>;
    final List<GraficaPunto> puntos = puntosJson.map((p) => GraficaPunto.fromJson(p)).toList();

    // ---- LÓGICA DE ORDENAMIENTO ----
    // Ordena la lista de puntos por fecha para asegurar que la gráfica se dibuje
    // en el orden cronológico correcto, independientemente de cómo lo envíe el servidor.
    puntos.sort((a, b) {
      try {
        // Se usa la primera parte del string 'periodo' que contiene la fecha de inicio
        final dateStringA = a.periodo.split(' - ')[0];
        final dateStringB = b.periodo.split(' - ')[0];
        
        final dateA = DateTime.parse(dateStringA);
        final dateB = DateTime.parse(dateStringB);
        
        // Compara las fechas para ordenar de la más antigua a la más reciente
        return dateA.compareTo(dateB);
      } catch (e) {
        // En caso de error de formato, no se altera el orden para evitar un crash.
        print('Error al parsear fecha para ordenar: $e. Períodos: ${a.periodo}, ${b.periodo}');
        return 0;
      }
    });

    // El segundo elemento es el mapa con las sumas totales
    final Map<String, dynamic> sumaJson = json[1] as Map<String, dynamic>;
    
    // Lee el total recaudado del JSON
    final sumaTotal = (sumaJson['suma_total'] as num?)?.toDouble() ?? 0.0;
    
    // Lee el total ideal del JSON
    final sumaTotalIdeal = (sumaJson['suma_total_ideal'] as num?)?.toDouble() ?? 0.0;
    
    return GraficaResponse(
      puntos: puntos,          // Lista de puntos ya ordenada
      sumaTotal: sumaTotal,
      sumaTotalIdeal: sumaTotalIdeal,
    );
  }
}

/// Clase que representa un único punto de datos en la gráfica.
class GraficaPunto {
  final String nombrePeriodo; // Ej: "Thursday", "1", "January"
  final String periodo;       // Ej: "2025-08-28" o "2025-08-26 - 2025-09-01"
  final double totalPago;
  final double? sumaIdeal;

  GraficaPunto({
    required this.nombrePeriodo,
    required this.periodo,
    required this.totalPago,
    required this.sumaIdeal,
  });

  /// Constructor factory para crear una instancia de GraficaPunto desde un JSON.
  factory GraficaPunto.fromJson(Map<String, dynamic> json) {
    return GraficaPunto(
      // nombrePeriodo puede ser int o String, se convierte a String por seguridad.
      nombrePeriodo: json['nombrePeriodo']?.toString() ?? '',
      periodo: json['periodo'] ?? '',
      // El total puede ser int o double, se maneja como 'num' y luego se convierte.
      totalPago: (json['totalPago'] as num?)?.toDouble() ?? 0.0,
      sumaIdeal: (json['sumaIdeal'] as num?)?.toDouble(),
    );
  }
}