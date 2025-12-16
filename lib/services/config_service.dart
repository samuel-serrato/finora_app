// lib/services/config_service.dart

import 'package:finora_app/services/api_service.dart';

class ConfigService {
  final ApiService _apiService = ApiService();

  /// Obtiene el día de corte configurado para la financiera.
  /// Devuelve el nombre del día en minúsculas (ej: "martes").
  Future<ApiResponse<String?>> getDiaCorte() {
    return _apiService.get<String?>(
      '/api/v1/configuracion/dia/corte',
      parser: (data) {
        // La API devuelve: {"message": "martes"}
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return data['message'] as String?;
        }
        // Si la respuesta no tiene el formato esperado, devolvemos null.
        return null;
      },
      // No mostramos un diálogo de error si falla, el calendario usará un valor por defecto.
      showErrorDialog: false,
    );
  }
}