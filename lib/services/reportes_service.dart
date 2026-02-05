// lib/services/reportes_service.dart

import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/models/reporte_general.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:intl/intl.dart';

class ReportesService {
  final ApiService _apiService = ApiService();

  /// Obtiene la lista de usuarios tipo 'campo' para los filtros
  Future<ApiResponse<List<Usuario>>> obtenerUsuariosCampo() {
    return _apiService.get<List<Usuario>>(
      '/api/v1/usuarios/tipo/campo',
      parser: (json) => (json as List).map((e) => Usuario.fromJson(e)).toList(),
      showErrorDialog: false,
    );
  }

/// Obtiene los datos para un reporte de tipo 'General'
  Future<ApiResponse<ReporteGeneralData>> obtenerReporteGeneral({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? idUsuario,
  }) {
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
    final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);

    // CORRECCIÓN: Definimos explícitamente el mapa como String, String
    final Map<String, String> params = {
      'inicio': fechaInicioStr,
      'final': fechaFinStr,
    };

    // Si hay un usuario seleccionado, lo agregamos
    if (idUsuario != null && idUsuario.isNotEmpty) {
      params['idusuario'] = idUsuario;
    }

    return _apiService.get<ReporteGeneralData>(
      '/api/v1/formato/reporte/general/datos',
      queryParams: params, // Ahora sí coincide el tipo
      parser: (data) => ReporteGeneralData.fromJson(data as Map<String, dynamic>),
    );
  }

  // ... (obtenerReporteContable queda igual o similar si aplica el filtro también)
/// Obtiene los datos para un reporte de tipo 'Contable'
  Future<ApiResponse<ReporteContableData>> obtenerReporteContable({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? idUsuario, // <--- 1. Nuevo parámetro opcional
  }) {
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
    final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);

    // <--- 2. Usamos Map<String, String> y lógica condicional
    final Map<String, String> params = {
      'inicio': fechaInicioStr,
      'final': fechaFinStr,
    };

    if (idUsuario != null && idUsuario.isNotEmpty) {
      params['idusuario'] = idUsuario;
    }

    return _apiService.get<ReporteContableData>(
      '/api/v1/formato/reporte/contable/datos',
      queryParams: params, // Pasamos los parámetros dinámicos
      parser: (data) => ReporteContableData.fromJson(data as Map<String, dynamic>),
    );
  }
}