// lib/services/agenda_service.dart

import 'package:finora_app/services/api_service.dart';

import '../models/agenda_item.dart';

class AgendaService {
  final ApiService _apiService = ApiService();

  Future<List<AgendaItem>> getAgendaDelMes(int anio, int mes) async {
    const String endpoint = '/api/v1/home/agenda';

    final Map<String, String> queryParams = {
      'año': anio.toString(),
      'mes': mes.toString(),
    };

    // <<< CAMBIO CLAVE AQUÍ: Ahora esperamos directamente List<AgendaItem> >>>
    final response = await _apiService.get<List<AgendaItem>>(
      endpoint,
      queryParams: queryParams,
      parser: (data) {
        // El 'data' que llega aquí es el JSON decodificado, que será List<dynamic>
        if (data is List) {
          // Y aquí es donde se convierte a List<AgendaItem>
          return data.map((item) => AgendaItem.fromJson(item)).toList();
        }
        throw Exception("Formato de respuesta inesperado: no es una lista JSON.");
      },
      handle404AsSuccess: true,
    );

    if (response.success && response.data != null) {
      // Como el tipo 'T' ahora es List<AgendaItem> y el parser lo genera,
      // 'response.data' ya será del tipo correcto.
      return response.data!; // Usamos '!' porque ya comprobamos que no es null
    } else {
      // Si la petición falló por otra razón (ej. 500, sin conexión), lanzamos un error.
      throw Exception(response.error ?? 'Error al obtener los datos de la agenda');
    }
  }
}