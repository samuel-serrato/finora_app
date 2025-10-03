// lib/services/grupo_service.dart

import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/services/api_service.dart';
import '../../utils/app_logger.dart';


class GrupoService {
  final ApiService _apiService = ApiService();

  // ========================================================================
  // MÉTODOS PARA OBTENER DATOS (YA EXISTENTES)
  // ========================================================================

  /// Obtiene los detalles completos de un grupo específico por su ID.
  Future<ApiResponse<Grupo>> getGrupoDetalles(String idGrupo) {
    return _apiService.get<Grupo>(
      '/api/v1/grupodetalles/$idGrupo',
      parser: (data) {
        if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
          return Grupo.fromJson(data.first);
        }
        if (data is Map<String, dynamic>) {
          return Grupo.fromJson(data);
        }
        throw Exception('Formato de respuesta inesperado para los detalles del grupo.');
      },
    );
  }

  /// Obtiene el historial de renovaciones de un grupo.
  Future<ApiResponse<List<dynamic>>> getGrupoHistorial(String nombreGrupo, {bool showErrorDialog = true}) {
    final encodedNombreGrupo = Uri.encodeComponent(nombreGrupo);
    return _apiService.get<List<dynamic>>(
      '/api/v1/grupodetalles/historial/$encodedNombreGrupo',
      parser: (data) {
        if (data is List) return data;
        throw Exception('Formato de respuesta inesperado para el historial del grupo.');
      },
      showErrorDialog: showErrorDialog,
    );
  }

  /// Busca clientes por nombre para agregarlos a un grupo.
  Future<ApiResponse<List<Map<String, dynamic>>>> buscarClientes(String query) {
    return _apiService.get<List<Map<String, dynamic>>>(
      '/api/v1/clientes/$query',
      parser: (data) {
        if (data is List) return List<Map<String, dynamic>>.from(data);
        throw Exception('Formato de respuesta inesperado al buscar clientes.');
      },
      showErrorDialog: false,
    );
  }

  /// Obtiene la lista de usuarios con rol de "campo" (Asesores).
  Future<ApiResponse<List<Usuario>>> getAsesores({bool showErrorDialog = true}) {
  return _apiService.get<List<Usuario>>(
    '/api/v1/usuarios/tipo/campo',
    parser: (data) {
      if (data is List) return data.map((item) => Usuario.fromJson(item)).toList();
      throw Exception('Formato de respuesta inesperado al obtener asesores.');
    },
    showErrorDialog: showErrorDialog, // <--- Y pásalo aquí a la llamada interna
  );
}

  /// Obtiene los datos de un grupo específico (usado por los formularios de edición/renovación).
  Future<ApiResponse<Grupo>> getGrupo(String idGrupo) {
    return getGrupoDetalles(idGrupo); // Reutiliza la lógica de getGrupoDetalles
  }
  
  // ========================================================================
  // =====> MÉTODOS NUEVOS PARA RENOVACIÓN <======
  // ========================================================================

  /// Obtiene los descuentos/adeudos de los miembros de un grupo para su renovación.
  Future<ApiResponse<Map<String, double>>> getDescuentosRenovacion(String idGrupo) {
    return _apiService.get<Map<String, double>>(
      '/api/v1/grupodetalles/renovacion/$idGrupo',
      parser: (data) {
        if (data is! List) {
          AppLogger.log("Respuesta de descuentos no es una lista, se devuelve mapa vacío.");
          return {}; // Devuelve mapa vacío si la respuesta no es una lista
        }
        
        final Map<String, double> descuentos = {};
        for (var item in data) {
          final String? idCliente = item['idclientes'];
          final num? descuento = item['descuento'];
          
          if (idCliente != null && descuento != null) {
            // Acumula el descuento por cliente
            descuentos[idCliente] = (descuentos[idCliente] ?? 0.0) + descuento.toDouble();
          }
        }
        return descuentos;
      },
      // No mostramos un diálogo de error si falla, el form puede seguir funcionando.
      showErrorDialog: false, 
    );
  }

  /// Envía la solicitud para renovar un grupo con su nueva configuración.
  Future<ApiResponse<dynamic>> renovarGrupo(Map<String, dynamic> datosRenovacion) {
    return _apiService.post(
      '/api/v1/grupodetalles/renovacion', // Endpoint unificado de renovación
      body: datosRenovacion,
      // Esperamos un código 201 Created para una renovación exitosa
    );
  }
  
  
  // ========================================================================
  // MÉTODOS PARA CREAR, EDITAR Y ELIMINAR (YA EXISTENTES)
  // ========================================================================

  /// Crea un nuevo grupo y sus miembros en una sola transacción.
  Future<ApiResponse<dynamic>> crearGrupoConMiembros(Map<String, dynamic> data) {
    return _apiService.post(
      '/api/v1/grupodetalles',
      body: data,
    );
  }

  /// Actualiza un grupo con toda su información y lista de miembros.
  Future<ApiResponse<dynamic>> actualizarGrupoCompleto(String idGrupo, Map<String, dynamic> data) {
    return _apiService.put(
      '/api/v1/grupodetalles/$idGrupo',
      body: data,
    );
  }
  
  /// Elimina un grupo y todos sus miembros asociados.
  Future<ApiResponse<void>> eliminarGrupoCompleto(String idGrupo) {
    return _apiService.delete(
      '/api/v1/grupos/$idGrupo',
    );
  }
  
  // --- Métodos de compatibilidad o menos usados, se mantienen por si acaso ---
  
  Future<ApiResponse<dynamic>> actualizarAsesorGrupo(String idGrupo, String idAsesor) {
    return _apiService.put('/api/v1/grupodetalles/$idGrupo', body: {"idusuarios": idAsesor});
  }

    /// Verifica si un cliente específico tiene adeudos de renovaciones anteriores.
  /// Devuelve el monto total del adeudo, o null si no hay adeudo o hay un error.
  Future<ApiResponse<double?>> verificarAdeudoCliente(String idCliente) {
    return _apiService.get<double?>(
      '/api/v1/grupodetalles/renovacion/clientes/$idCliente',
      parser: (data) {
        // La API puede devolver una lista vacía si no hay adeudos.
        if (data is! List || data.isEmpty) {
          return null; // No hay adeudos.
        }

        // Usamos fold para sumar todos los valores de 'descuento' (adeudo).
        // Esto es robusto por si un cliente tuviera múltiples entradas de adeudo.
        final double totalAdeudo = data.fold<double>(0.0, (sum, item) {
          final descuento = item['descuento'];
          if (descuento != null && descuento is num) {
            return sum + descuento.toDouble();
          }
          return sum;
        });

        // Solo devolvemos un monto si es significativamente mayor que cero.
        return totalAdeudo > 0.01 ? totalAdeudo : null;
      },
      // No mostramos un diálogo de error genérico si la petición falla (ej. 404),
      // ya que un 404 aquí puede significar "no se encontró adeudo".
      // La UI manejará el caso de éxito/fallo.
      showErrorDialog: false,
    );
  }

    /// ========================================================================
  /// =====> NUEVO MÉTODO PARA ACTUALIZAR ESTADO <======
  /// ========================================================================

  /// Actualiza el estado de un crédito/grupo específico.
  Future<ApiResponse<dynamic>> actualizarEstadoGrupo(String idGrupo, String nuevoEstado) {
    return _apiService.put(
      // Usamos el endpoint que especificaste
      '/api/v1/grupos/estado/$idGrupo', 
      body: {
        'estado': nuevoEstado,
      },
      // No necesitamos un parser complejo, solo saber si la operación fue exitosa.
    );
  }


  // ========================================================================
  // MÉTODOS PARA CREAR, EDITAR Y ELIMINAR (YA EXISTENTES)
  // ========================================================================
}