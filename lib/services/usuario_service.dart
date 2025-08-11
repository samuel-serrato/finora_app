// lib/services/usuario_service.dart

import 'package:finora_app/models/usuarios.dart'; // Asegúrate que la ruta a tu modelo Usuario es correcta
import 'package:finora_app/services/api_service.dart';

class UsuarioService {
  final ApiService _apiService = ApiService();

  // ========================================================================
  // MÉTODOS DE LECTURA (GET)
  // ========================================================================

  /// Obtiene la información detallada de un solo usuario por su ID.
  Future<ApiResponse<Usuario>> getUsuarioPorId(String idUsuario) {
    return _apiService.get<Usuario>(
      '/api/v1/usuarios/$idUsuario',
      parser: (data) {
        // La API puede devolver una lista con un solo elemento
        if (data is List && data.isNotEmpty) {
          return Usuario.fromJson(data.first as Map<String, dynamic>);
        }
        // O un solo objeto
        if (data is Map<String, dynamic>) {
          return Usuario.fromJson(data);
        }
        throw Exception('Formato de respuesta inesperado para getUsuarioPorId.');
      },
    );
  }

  // ========================================================================
  // MÉTODO DE CREACIÓN (POST)
  // ========================================================================

  /// Crea un nuevo usuario.
  /// El cuerpo (`body`) debe ser un Map<String, dynamic> con los datos del usuario.
  Future<ApiResponse<Usuario>> crearUsuario(Map<String, dynamic> body) {
    return _apiService.post<Usuario>(
      '/api/v1/usuarios',
      body: body,
      // Suponemos que la API devuelve el usuario recién creado
      parser: (data) => Usuario.fromJson(data as Map<String, dynamic>),
    );
  }

  // ========================================================================
  // MÉTODO DE ACTUALIZACIÓN (PUT)
  // ========================================================================

  /// Actualiza un usuario existente por su ID.
  /// El cuerpo (`body`) debe ser un Map<String, dynamic> con los datos a actualizar.
  Future<ApiResponse<dynamic>> actualizarUsuario(String idUsuario, Map<String, dynamic> body) {
    return _apiService.put(
      '/api/v1/usuarios/$idUsuario',
      body: body,
    );
  }

  // ========================================================================
  // MÉTODO DE ELIMINACIÓN (DELETE)
  // ========================================================================

  /// Elimina un usuario por su ID.
  /// Permite controlar si se muestra un diálogo de error desde el ApiService.
  Future<ApiResponse<dynamic>> eliminarUsuario(String idUsuario, {bool showErrorDialog = true}) {
    return _apiService.delete(
      '/api/v1/usuarios/$idUsuario',
      showErrorDialog: showErrorDialog,
    );
  }



  // ========================================================================
  // MÉTODO PARA CAMBIAR CONTRASEÑA (PUT)
  // ========================================================================

  Future<ApiResponse<dynamic>> cambiarPassword({
    required String idUsuario,
    required String nuevaPassword,
  }) {
    return _apiService.put(
      // Endpoint exacto de tu API
      '/api/v1/usuarios/recuperar/password/$idUsuario',
      body: {'password': nuevaPassword},
    );
  }
}