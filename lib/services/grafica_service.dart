import 'package:finora_app/services/api_service.dart';

import '../models/grafica_data.dart';

// Enum para manejar las vistas de forma segura
enum GraficaView { semanal, mensual, anual }

class GraficaService {
  final ApiService _apiService = ApiService();

  Future<GraficaResponse> getGraficaData(
    GraficaView view,
    DateTime date,
  ) async {
    // Construimos el endpoint dinámicamente
    final String endpoint = '/api/v1/home/grafica/${view.name}';

    // Preparamos los parámetros de la consulta.
    final Map<String, String> queryParams = {
      'año': date.year.toString(),
      'mes': date.month.toString(),
    };

    // <<< CAMBIO AÑADIDO AQUÍ >>>
    // Si la vista es semanal, añadimos el día.
    if (view == GraficaView.semanal) {
      queryParams['dia'] = date.day.toString();
    }
    // <<< FIN DEL CAMBIO AÑADIDO >>>

    final response = await _apiService.get<GraficaResponse>(
      endpoint,
      queryParams: queryParams,
      parser: (data) {
        if (data is List) {
          return GraficaResponse.fromJson(data);
        }
        throw Exception('Formato de respuesta inesperado para la gráfica.');
      },
      handle404AsSuccess: true,
    );

    if (response.success) {
      return response.data ?? GraficaResponse(puntos: [], sumaTotal: 0.0, sumaTotalIdeal: 0.0);
    } else {
      throw Exception(
        response.error ?? 'Error al obtener los datos de la gráfica',
      );
    }
  }
}
