// lib/services/reportes_service.dart

import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/models/reporte_general.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:intl/intl.dart';

class ReportesService {
  final ApiService _apiService = ApiService();

  /// Obtiene los datos para un reporte de tipo 'General' dentro de un rango de fechas.
  ///
  /// Devuelve un [ApiResponse] que contiene un [ReporteGeneralData] en caso de éxito.
  Future<ApiResponse<ReporteGeneralData>> obtenerReporteGeneral({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    // Formateamos las fechas al formato que espera la API (yyyy-MM-dd)
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
    final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);

    return _apiService.get<ReporteGeneralData>(
      '/api/v1/formato/reporte/general/datos',
      queryParams: {
        'inicio': fechaInicioStr,
        'final': fechaFinStr,
      },
      // Le pasamos la función que sabe cómo convertir el JSON en nuestro objeto
      parser: (data) => ReporteGeneralData.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Obtiene los datos para un reporte de tipo 'Contable' dentro de un rango de fechas.
  ///
  /// Devuelve un [ApiResponse] que contiene un [ReporteContableData] en caso de éxito.
  Future<ApiResponse<ReporteContableData>> obtenerReporteContable({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    // Formateamos las fechas
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
    final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);

    return _apiService.get<ReporteContableData>(
      '/api/v1/formato/reporte/contable/datos',
      queryParams: {
        'inicio': fechaInicioStr,
        'final': fechaFinStr,
      },
      // El parser específico para el reporte contable
      parser: (data) => ReporteContableData.fromJson(data as Map<String, dynamic>),
    );
  }
}