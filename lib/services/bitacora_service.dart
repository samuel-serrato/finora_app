import 'package:finora_app/models/bitacora.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:intl/intl.dart';

class BitacoraService {
  final ApiService _apiService = ApiService();

  /// Obtiene la lista de usuarios para poblar el dropdown de filtros.
  Future<ApiResponse<List<Usuario>>> getUsuarios() {
    return _apiService.get<List<Usuario>>(
      '/api/v1/usuarios',
      parser: (data) {
        if (data is List) {
          return data
              .map((userJson) => Usuario.fromJson(userJson as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Formato de respuesta inesperado para la lista de usuarios.');
      },
    );
  }

  /// Obtiene los registros de la bitácora para una fecha y un usuario opcional.
  Future<ApiResponse<List<Bitacora>>> getBitacora({
    required DateTime fecha,
    Usuario? usuario,
  }) {
    final fechaFormateada = DateFormat('yyyy-MM-dd').format(fecha);
    String endpoint = '/api/v1/bitacora/$fechaFormateada';
    
    Map<String, String>? queryParams;

    if (usuario != null) {
      // Prepara los query parameters si se seleccionó un usuario
      queryParams = {
        'nombre': Uri.encodeComponent(usuario.nombreCompleto),
      };
    }

    return _apiService.get<List<Bitacora>>(
      endpoint,
      queryParams: queryParams, // Pasa los parámetros aquí
      parser: (data) {
        if (data is List) {
          return data
              .map((entryJson) => Bitacora.fromJson(entryJson as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Formato de respuesta inesperado para la bitácora.');
      },
      // Si el API devuelve 404 (no hay registros), lo tratamos como éxito con lista vacía.
      handle404AsSuccess: true, 
    );
  }
}