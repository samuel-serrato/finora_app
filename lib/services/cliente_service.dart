// lib/services/cliente_service.dart

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/services/api_service.dart';

class ClienteService {
  final ApiService _apiService = ApiService();

  // ========================================================================
  // MÉTODOS DE CREACIÓN (POST)
  // ========================================================================

  Future<ApiResponse<Map<String, dynamic>>> crearCliente(ClienteInfo clienteInfo) {
    return _apiService.post<Map<String, dynamic>>(
      '/api/v1/clientes',
      body: clienteInfo.toJson(),
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<dynamic>> crearCuentaBanco(CuentaBanco cuenta, String idCliente) {
    final payload = {
      "idclientes": idCliente,
      ...cuenta.toJson() // Ya no necesita parámetros
    };
    return _apiService.post('/api/v1/cuentabanco', body: payload);
  }

  Future<ApiResponse<dynamic>> crearDomicilio(Domicilio domicilio, String idCliente) {
    final payload = [{ "idclientes": idCliente, ...domicilio.toJson() }];
    return _apiService.post('/api/v1/domicilios', body: payload);
  }

  Future<ApiResponse<dynamic>> crearDatosAdicionales(DatosAdicionales datos, String idCliente) {
    final payload = {
      "idclientes": idCliente,
      ...datos.toJson() // Ya no necesita parámetros
    };
    return _apiService.post('/api/v1/datosadicionales', body: payload);
  }

  Future<ApiResponse<dynamic>> crearIngresos(List<IngresoEgreso> ingresos, String idCliente) {
    final payload = ingresos.map((ingreso) => {
      "idclientes": idCliente,
      ...ingreso.toJson() // Ya no necesita parámetros
    }).toList();
    return _apiService.post('/api/v1/ingresos', body: payload);
  }

  Future<ApiResponse<dynamic>> crearReferencias(List<Referencia> referencias, String idCliente) {
    final payload = referencias.map((ref) => {
      "idclientes": idCliente,
      ...ref.toJson()
    }).toList();
    return _apiService.post('/api/v1/referencia', body: payload);
  }
  
  // ========================================================================
  // MÉTODO DE LECTURA (GET)
  // ========================================================================

  Future<ApiResponse<Map<String, dynamic>>> getCliente(String clienteId) {
    return _apiService.get<Map<String, dynamic>>(
      '/api/v1/clientes/$clienteId',
      parser: (data) {
        if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
          return data.first as Map<String, dynamic>;
        }
        if (data is Map<String, dynamic>) { return data; }
        throw Exception('Formato de respuesta inesperado del servidor o cliente no encontrado.');
      },
    );
  }
    
  // ========================================================================
  // MÉTODOS DE ACTUALIZACIÓN (PUT)
  // ========================================================================

  Future<ApiResponse<dynamic>> actualizarClienteInfo(String idCliente, ClienteInfo clienteInfo) {
    return _apiService.put('/api/v1/clientes/$idCliente', body: clienteInfo.toJson());
  }

  Future<ApiResponse<dynamic>> crearOActualizarCuentaBanco(String idCliente, String? idcuantabank, CuentaBanco cuenta) {
    if (idcuantabank != null && idcuantabank.isNotEmpty) {
      return _apiService.put('/api/v1/cuentabanco/$idcuantabank', body: cuenta.toJson());
    } else {
      return crearCuentaBanco(cuenta, idCliente);
    }
  }

 // CORRECCIÓN: Aceptamos el idCliente y lo usamos en la URL
Future<ApiResponse<dynamic>> actualizarDomicilio(String idCliente, int iddomicilios, Domicilio domicilio) {
  // El payload ya se arma correctamente en el modelo
  final payload = [domicilio.toJson(iddomicilios: iddomicilios)];
  
  // Usamos el idCliente en la URL, como en tu código original que funcionaba
  return _apiService.put('/api/v1/domicilios/$idCliente', body: payload);
}

  Future<ApiResponse<dynamic>> actualizarDatosAdicionales(String idCliente, DatosAdicionales datos) {
    return _apiService.put(
        '/api/v1/datosadicionales/$idCliente',
        body: datos.toJson() // Ya no necesita parámetros
    );
  }

  Future<ApiResponse<dynamic>> actualizarIngresos(String idCliente, List<Map<String, dynamic>> ingresos) {
    return _apiService.put('/api/v1/ingresos/$idCliente', body: ingresos);
  }

  Future<ApiResponse<dynamic>> actualizarReferencias(String idCliente, List<Map<String, dynamic>> referencias) {
    return _apiService.put('/api/v1/referencia/$idCliente', body: referencias);
  }


  // ========================================================================
  // MÉTODO DE ELIMINACIÓN (DELETE)
  // ========================================================================

  // CAMBIO AQUÍ: Añadimos el parámetro opcional {bool showErrorDialog = true}
  Future<ApiResponse<dynamic>> eliminarCliente(String idCliente, {bool showErrorDialog = true}) {
    // Y lo pasamos al método del ApiService
    return _apiService.delete(
      '/api/v1/clientes/$idCliente',
      showErrorDialog: showErrorDialog,
    );
  }

  // ========================================================================
  // MÉTODO PARA EL HISTORIAL DEL CLIENTE (GET)
  // ========================================================================

  Future<ApiResponse<List<HistorialGrupo>>> getHistorialCliente(String clienteId) {
    return _apiService.get<List<HistorialGrupo>>(
      // Endpoint exacto de tu versión de escritorio
      '/api/v1/grupodetalles/historial/clientes/$clienteId',
      parser: (data) {
        // El API devuelve una lista directamente
        if (data is List) {
          return data
              .map((item) => HistorialGrupo.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        // Si no es una lista, es un error de formato
        throw Exception('Formato de respuesta inesperado para el historial.');
      },
      // Le decimos al ApiService que un 404 NO es un error, es una lista vacía.
      // Esto imita el comportamiento de tu código de escritorio.
      handle404AsSuccess: true, 
    );
  }


  
  /// Actualiza el estado de un cliente para permitirle unirse a un nuevo grupo.
  /// Esto corresponde a la funcionalidad "Habilitar Multigrupo".
  Future<ApiResponse<dynamic>> habilitarMultigrupo(String idCliente) {
    // Este endpoint no requiere un cuerpo (body), solo el ID en la URL.
    return _apiService.put(
      '/api/v1/clientes/estado/creditonuevo/$idCliente',
      // No es necesario pasar un body, el ApiService lo manejará como nulo.
    );
  }
}