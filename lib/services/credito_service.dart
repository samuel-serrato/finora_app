import 'package:finora_app/forms/ncredito_form.dart';
import 'package:finora_app/models/creditos.dart'; // Asegúrate de que los modelos estén accesibles
import 'package:finora_app/services/api_service.dart';

import '../models/grupos.dart';


class CreditoService {
  final ApiService _api = ApiService();

  /// <<< --- NUEVA FUNCIÓN --- >>>
  /// Obtiene la lista de grupos disponibles para crear un crédito.
  Future<ApiResponse<List<Grupo>>> getGruposDisponibles() async {
    return await _api.get<List<Grupo>>(
      '/api/v1/grupodetalles',
      parser: (data) {
        if (data is List) {
          return data
              .map((item) => Grupo.fromJson(item))
              .where((grupo) => grupo.estado == "Disponible") // Filtramos aquí
              .toList();
        }
        throw Exception('Formato de respuesta inesperado para grupos.');
      },
      showErrorDialog: true, // Es data esencial, mostramos error si falla.
    );
  }

  /// <<< --- NUEVA FUNCIÓN --- >>>
  /// Obtiene la lista de todas las tasas de interés disponibles.
  Future<ApiResponse<List<TasaInteres>>> getTasasDeInteres() async {
    return await _api.get<List<TasaInteres>>(
      '/api/v1/tazainteres/',
      parser: (data) {
        if (data is List) {
          return data.map((item) => TasaInteres.fromJson(item)).toList();
        }
        throw Exception('Formato de respuesta inesperado para tasas de interés.');
      },
      showErrorDialog: true,
    );
  }

  /// <<< --- NUEVA FUNCIÓN --- >>>
  /// Obtiene la lista de todas las duraciones (plazos) disponibles.
  Future<ApiResponse<List<Duracion>>> getDuraciones() async {
    return await _api.get<List<Duracion>>(
      '/api/v1/duracion',
      parser: (data) {
        if (data is List) {
          return data.map((item) => Duracion.fromJson(item)).toList();
        }
        throw Exception('Formato de respuesta inesperado para duraciones.');
      },
      showErrorDialog: true,
    );
  }

  /// Envía los datos de un nuevo crédito al servidor para su creación.
  /// (Esta función ya la tenías y está perfecta).
  Future<ApiResponse<Map<String, dynamic>>> crearCredito(Map<String, dynamic> creditoData) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/v1/creditos',
      body: creditoData,
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return {};
      },
      showErrorDialog: true,
    );
    return response;
  }

  /// Obtiene los detalles completos de un crédito específico usando su ID.
  /// (Esta función ya la tenías y está perfecta).
  Future<ApiResponse<Credito>> getCreditoDetalles(String folio, {bool showErrorDialog = true}) async {
    final ApiResponse<Credito> response = await _api.get<Credito>(
      '/api/v1/creditos/$folio',
      parser: (data) {
        if (data is List && data.isNotEmpty) {
          return Credito.fromJson(data[0]);
        }
        throw Exception('Formato de respuesta inesperado o lista de créditos vacía.');
      },
      showErrorDialog: showErrorDialog,
    );
    return response;
  }

  /// Obtiene los descuentos por renovación para un grupo específico.
  /// (Esta función ya la tenías, la mantenemos igual).
  Future<ApiResponse<Map<String, double>>> getDescuentosRenovacion(String idGrupo) async {
    final response = await _api.get<Map<String, double>>(
      '/api/v1/grupodetalles/renovacion/$idGrupo',
      showErrorDialog: false, 
      parser: (data) {
        if (data is List) {
          final Map<String, double> descuentos = {};
          for (var item in data) {
            if (item['idclientes'] != null && item['descuento'] != null && idGrupo != item['idgrupos']) {
              final idCliente = item['idclientes'] as String;
              final descuento = (item['descuento'] as num).toDouble();
              // Acumulamos descuentos por si un cliente tiene más de uno
              descuentos[idCliente] = (descuentos[idCliente] ?? 0.0) + descuento;
            }
          }
          return descuentos;
        }
        return {}; 
      },
    );
    return response;
  }

  /// Envía una petición para eliminar un crédito específico por su folio/ID.
  /// (Esta función ya la tenías y está perfecta).
  Future<ApiResponse<void>> eliminarCredito(String idCredito) async {
    final response = await _api.delete<void>(
      '/api/v1/creditos/$idCredito',
      parser: (data) {
        return;
      },
      showErrorDialog: true, 
    );
    return response;
  }


  // ========================================================================
  // =====> NUEVO MÉTODO PARA ACTUALIZAR ESTADO <======
  // ========================================================================

  /// Actualiza el estado de un crédito específico a través de su id de grupo.
  Future<ApiResponse<dynamic>> actualizarEstadoCredito(String idGrupo, String nuevoEstado) {
    return _api.put(
      '/api/v1/creditos/estado/$idGrupo', 
      body: {
        'estado': nuevoEstado,
      },
    );
  }
}