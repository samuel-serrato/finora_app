// lib/services/reportes_service.dart

import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/models/reporte_creditos_activos.dart'; // <--- IMPORTANTE: Importar el nuevo modelo
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

    final Map<String, String> params = {
      'inicio': fechaInicioStr,
      'final': fechaFinStr,
    };

    if (idUsuario != null && idUsuario.isNotEmpty) {
      params['idusuario'] = idUsuario;
    }

    return _apiService.get<ReporteGeneralData>(
      '/api/v1/formato/reporte/general/datos',
      queryParams: params,
      parser: (data) => ReporteGeneralData.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Obtiene los datos para un reporte de tipo 'Contable'
  Future<ApiResponse<ReporteContableData>> obtenerReporteContable({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? idUsuario,
  }) {
    final fechaInicioStr = DateFormat('yyyy-MM-dd').format(fechaInicio);
    final fechaFinStr = DateFormat('yyyy-MM-dd').format(fechaFin);

    final Map<String, String> params = {
      'inicio': fechaInicioStr,
      'final': fechaFinStr,
    };

    if (idUsuario != null && idUsuario.isNotEmpty) {
      params['idusuario'] = idUsuario;
    }

    return _apiService.get<ReporteContableData>(
      '/api/v1/formato/reporte/contable/datos',
      queryParams: params,
      parser: (data) => ReporteContableData.fromJson(data as Map<String, dynamic>),
    );
  }

  // --- NUEVO MÉTODO IMPLEMENTADO ---
  /// Obtiene la lista de créditos activos
  Future<ApiResponse<List<ReporteCreditoActivo>>> obtenerReporteCreditosActivos({
    String? idUsuario,
  }) {
    // Preparamos los parámetros (si aplica el filtro por usuario)
    final Map<String, String> params = {};

    if (idUsuario != null && idUsuario.isNotEmpty) {
      params['idusuario'] = idUsuario;
    }

    return _apiService.get<List<ReporteCreditoActivo>>(
      '/api/v1/formato/reporte/creditos/activos/',
      queryParams: params,
      parser: (data) {
        // Casteamos la respuesta a Map para acceder a 'outputPath'
        final responseMap = data as Map<String, dynamic>;
        
        // Extraemos la lista que está dentro de 'outputPath'
        final list = responseMap['outputPath'] as List<dynamic>? ?? [];
        
        // Mapeamos al modelo
        return list.map((e) => ReporteCreditoActivo.fromJson(e)).toList();
      },
    );
  }
}