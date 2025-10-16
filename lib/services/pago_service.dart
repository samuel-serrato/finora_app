// Archivo: lib/services/pago_service.dart

import 'package:finora_app/models/calendario_response.dart';
import 'package:finora_app/models/pago.dart'; // Asegúrate que la ruta a tu modelo Pago sea correcta
import 'package:finora_app/models/saldo_global.dart';
import 'package:finora_app/services/api_service.dart'; // Asegúrate que la ruta a tu ApiService sea correcta

class PagoService {
  final ApiService _api = ApiService();

  /// Obtiene el calendario de pagos completo para un crédito específico.
  ///
  /// El endpoint devuelve una lista de objetos de pago, que este método parsea
  /// a una lista de objetos [Pago].
  /*  Future<ApiResponse<List<Pago>>> getCalendarioPagos(String idCredito) async {
    return await _api.get<List<Pago>>(
      '/api/v1/creditos/calendario/$idCredito',
      parser: (data) {
        if (data is List) {
          return data.map((item) => Pago.fromJson(item)).toList();
        }
        throw Exception('Formato de respuesta inesperado para el calendario de pagos.');
      },
    );
  } */

  // =========================================================================
  // <<< MÉTODO CORREGIDO PARA MANEJAR LA NUEVA ESTRUCTURA DE DATOS >>>
  // =========================================================================
  /// Obtiene el calendario de pagos y los saldos globales para un crédito.
  ///
  /// El endpoint ahora devuelve un array con dos arrays internos:
  /// 1. La lista de saldos globales.
  /// 2. La lista de detalles de pago.
  /// Este método parsea ambos y los devuelve en un objeto `CalendarioResponse`.
  Future<ApiResponse<CalendarioResponse>> getCalendarioPagos(
    String idCredito,
  ) async {
    // El tipo de dato esperado ahora es CalendarioResponse
    return await _api.get<CalendarioResponse>(
      '/api/v1/creditos/calendario/$idCredito',
      parser: (data) {
        // 1. Validamos que la respuesta sea una lista con dos elementos.
        if (data is List && data.length == 2) {
          // 2. Parseamos el primer elemento como la lista de Saldos Globales.
          final List<dynamic> saldosGlobalesJson = data[0];
          final List<SaldoGlobal> saldosGlobales =
              saldosGlobalesJson
                  .map((item) => SaldoGlobal.fromJson(item))
                  .toList();

          // 3. Parseamos el segundo elemento como la lista de Pagos.
          final List<dynamic> pagosJson = data[1];
          final List<Pago> pagos =
              pagosJson.map((item) => Pago.fromJson(item)).toList();

          // 4. Devolvemos el objeto contenedor con ambas listas.
          return CalendarioResponse(
            saldosGlobales: saldosGlobales,
            pagos: pagos,
          );
        }

        // Si el formato no es el esperado, lanzamos una excepción clara.
        throw Exception(
          'Formato de respuesta inesperado. Se esperaba una lista con dos listas internas.',
        );
      },
    );
  }
  // =========================================================================
  // <<< FIN DEL MÉTODO CORREGIDO >>>
  // =========================================================================

  /// Elimina un abono específico de un pago.
  ///
  /// Requiere el ID del abono (`idpagos`) y el ID de la fecha de pago a la que pertenece (`idfechaspagos`).
  Future<ApiResponse<void>> eliminarAbono({
    required String idAbono,
    required String idFechasPago,
  }) async {
    // Nota: El tipo <void> indica que no esperamos datos en la respuesta de éxito, solo un código 2xx.
    return await _api.delete<void>('/api/v1/pagos/$idAbono/$idFechasPago');
  }

  // =========================================================================
  // <<< MÉTODO CORREGIDO: GUARDAR MÚLTIPLES PAGOS >>>
  // =========================================================================
  /// Envía una lista de pagos modificados al backend para ser procesados en lote.
  ///
  /// Este método es utilizado por la pantalla de control de pagos para guardar
  /// todos los cambios pendientes (diferentes tipos de pago, abonos, etc.)
  /// con una sola llamada a la API.
  ///
  /// El `payload` es una lista de mapas, donde cada mapa representa un pago
  /// y sus cambios.
  ///
  /// [idCredito]: El ID del crédito. Aunque no se usa en el endpoint, se mantiene
  /// por si se necesita en el futuro o para lógica interna.
  /// [pagosModificados]: La lista de pagos con sus modificaciones.
  Future<ApiResponse<void>> guardarPagosMultiples({
    required String
    idCredito, // Lo mantenemos por consistencia, aunque no se use en la URL
    required List<Map<String, dynamic>> pagosModificados,
  }) async {
    // ▼▼▼ CAMBIO CLAVE (1/2): El endpoint correcto es genérico.
    // La API identifica los pagos por los IDs que van DENTRO del body.
    final String endpoint = '/api/v1/pagos';

    // ▼▼▼ CAMBIO CLAVE (2/2): El cuerpo de la petición es LA LISTA directamente.
    // No un mapa como {"pagos": [...]}.
    final body = pagosModificados;

    // Usamos el método post de nuestro ApiService.
    // Esperamos una respuesta vacía (void) en caso de éxito.
    return await _api.post<void>(endpoint, body: body);
  }
  // =========================================================================
  // <<< FIN DEL MÉTODO CORREGIDO >>>
  // =========================================================================

  // ▼▼▼ MÉTODO NUEVO AÑADIDO ▼▼▼
  /// Elimina TODOS los depósitos/pagos asociados a una fecha de pago específica (semana).
  ///
  /// Este método es una acción destructiva que borra todos los registros de pago
  /// para un `idFechasPago` dado.
  Future<ApiResponse<void>> eliminarPagosDeSemana({
    required String idFechasPago,
  }) async {
    // Asumimos que el endpoint para borrar todos los pagos de una semana
    // es una petición DELETE al ID de la fecha de pago.
    // ¡Asegúrate de que este endpoint coincida con tu backend!
    return await _api.delete<void>('/api/v1/pagos/$idFechasPago');
  }
  // ▲▲▲ FIN DEL MÉTODO NUEVO ▲▲▲

  // ▼▼▼ ¡AÑADE ESTE NUEVO MÉTODO! ▼▼▼
  /// Actualiza el permiso de moratorio para un pago específico.
  ///
  /// Utiliza el ApiService para realizar una petición PUT al endpoint correspondiente.
  ///
  /// [idFechasPago]: El ID único del registro de pago.
  /// [moratorioDesabilitado]: El nuevo estado ("Si" o "No").
  ///
  /// Devuelve un `ApiResponse<void>` para indicar el éxito o fracaso de la operación.
  Future<ApiResponse<void>> actualizarPermisoMoratorio({
    required String idFechasPago,
    required String moratorioDesabilitado,
  }) async {
    // 1. Definir el endpoint dinámico.
    final String endpoint = '/api/v1/pagos/permiso/moratorio/$idFechasPago';

    // 2. Preparar el cuerpo (payload) de la petición.
    final Map<String, dynamic> body = {
      'moratorioDesabilitado': moratorioDesabilitado,
    };

    // 3. Realizar la llamada PUT usando el método genérico de tu ApiService,
    //    igual que haces con get, post y delete.
    return await _api.put<void>(endpoint, body: body);
  }
  // ▲▲▲ FIN DEL MÉTODO AÑADIDO ▲▲▲

  // ▼▼▼ AÑADE ESTOS DOS NUEVOS MÉTODOS ▼▼▼

  /// Guarda la selección de clientes que entrarán en proceso de renovación para un pago.
  ///
  /// Envía una petición POST con el ID del pago y la lista de clientes seleccionados
  /// con sus respectivos montos a descontar.
  Future<ApiResponse<void>> guardarSeleccionRenovacion({
    required String idFechasPago,
    required List<Map<String, dynamic>> clientes,
  }) async {
    final body = {"pagadoParaRenovacion": idFechasPago, "clientes": clientes};
    // Usamos el método post de nuestro ApiService.
    return await _api.post<void>(
      '/api/v1/pagos/permiso/renovacion/pendientes',
      body: body,
    );
  }

  /// Elimina TODAS las selecciones de renovación asociadas a una fecha de pago.
  ///
  /// Envía una petición DELETE al endpoint especificando el ID del pago.
  Future<ApiResponse<void>> eliminarSeleccionRenovacion({
    required String idFechasPago,
  }) async {
    // Usamos el método delete de nuestro ApiService.
    return await _api.delete<void>(
      '/api/v1/pagos/permiso/renovacion/pendientes/$idFechasPago',
    );
  }
  // ▲▲▲ FIN DE LOS MÉTODOS AÑADIDOS ▲▲▲

  /// Aplica el saldo a favor disponible a la deuda de un pago específico.
  Future<ApiResponse<void>> aplicarSaldoAFavor({
    required String idCredito,
    required String idPagosDetalles,
    required String idFechasPago,
    required double monto,
    // === PARÁMETROS ADICIONALES AÑADIDOS ===
    required String idPagos,
    required double montoADepositar,
    required String fechaPago, // <-- Añadir este parámetro
  }) async {
    // El payload ahora incluye todos los campos requeridos por tu backend.
    final List<Map<String, dynamic>> payload = [
      {
        "idcredito": idCredito,
        "idpagos": idPagos, // <-- CAMPO AÑADIDO
        "montoAdepositar": montoADepositar, // <-- CAMPO AÑADIDO
        "idpagosdetalles": idPagosDetalles,
        "idfechaspagos": idFechasPago,
        "saldofavor": double.parse(monto.toStringAsFixed(2)),
        'fechaPago': fechaPago, // <-- Añadirlo al cuerpo de la petición
      },
    ];

    return await _api.post<void>(
      '/api/v1/pagos/utilizar/saldofavor',
      body: payload,
    );
  }

  // <<< NUEVO (1/2): MÉTODO PARA PERMITIR EDICIÓN DE MORATORIO >>>
  /// Habilita o deshabilita la capacidad de editar manualmente los moratorios para un pago.
  ///
  /// Corresponde al endpoint: PUT /api/v1/pagos/permiso/editable/moratorio/:idFechasPagos
  Future<ApiResponse<void>> actualizarPermisoMoratorioEditable({
    required String idFechasPagos,
    required bool habilitar,
  }) async {
    final String endpoint =
        '/api/v1/pagos/permiso/editable/moratorio/$idFechasPagos';
    final Map<String, dynamic> body = {
      // Tu API espera "Si" o "No" como strings
      'moratorioEditable': habilitar ? 'Si' : 'No',
    };
    // Usamos el método PUT de tu ApiService
    return await _api.put<void>(endpoint, body: body);
  }
  // <<< FIN DEL MÉTODO NUEVO (1/2) >>>

  // <<< NUEVO (2/2): MÉTODO PARA GUARDAR MORATORIO EDITADO >>>
  /// Registra un pago de moratorio manual para una semana específica.
  ///
  /// Corresponde al endpoint: POST /api/v1/pagos/moratorio/editable/
  /// Corresponde al endpoint: POST /api/v1/pagos/moratorio/editable/
  Future<ApiResponse<void>> guardarMoratorioEditable({
    required String idFechasPagos,
    required String fechaPago, // Debe estar en formato ISO 8601 (YYYY-MM-DD)
    required double montoMoratorio,
    required double montoAPagar, // <<< PARÁMETRO AÑADIDO >>>
  }) async {
    final String endpoint = '/api/v1/pagos/moratorio/editable/';
    final List<Map<String, dynamic>> payload = [
      {
        "idfechaspagos": idFechasPagos,
        "fechaPago": fechaPago,
        "tipoPago": "Moratorio Editable",
        "montoaPagar": montoAPagar, // <<< AHORA USA EL VALOR RECIBIDO >>>
        "deposito": 0,
        "moratorio": montoMoratorio,
        "saldofavor": 0,
      },
    ];
    // Usamos el método POST de tu ApiService
    return await _api.post<void>(endpoint, body: payload);
  }
  // <<< FIN DEL MÉTODO NUEVO (2/2) >>>

  // ▼▼▼ AÑADE ESTE NUEVO MÉTODO AL FINAL DE LA CLASE ▼▼▼
  /// Elimina un registro de saldo global (abono global) por su ID.
  ///
  /// Corresponde al endpoint: DELETE /api/v1/pagos/saldoglobal/:idfechaspagos
  Future<ApiResponse<void>> eliminarSaldoGlobal({
    required String idSaldoglobal,
  }) async {
    // Usamos el método delete de nuestro ApiService, apuntando al endpoint correcto.
    return await _api.delete<void>('/api/v1/pagos/saldoglobal/$idSaldoglobal');
  }

  // ▲▲▲ FIN DEL MÉTODO AÑADIDO ▲▲▲
}

/*

final url = '$baseUrl/api/v1/pagos/$idAbono/${pago.idfechaspagos}';


*/
