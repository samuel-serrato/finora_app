// apiservice.dart

import 'dart:async';
import 'dart:convert';
import 'package:finora_app/ip.dart'; // Asegúrate que esta importación es correcta para tu proyecto
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
// import 'package:finora_app/screens/login.dart';


// Enum para tipos de petición
enum HttpMethod { get, post, put, delete }

// Clase para manejar respuestas de la API
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final Map<String, String>? headers;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.headers,
  });
}

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 15);

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  // <<< AÑADIDO: Función privada para el logging
  // Dentro de la clase ApiService

  void _logRequestDetails({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
    http.Response? response,
    Object? error,
    StackTrace? stackTrace, // <-- Nuevo para más detalle
  }) {
    AppLogger.log('\n===================== 🚀 API LOG 🚀 =====================');
    AppLogger.log('➡️  $method: $url');

    // Imprime el token de forma segura
    if (headers != null && headers.containsKey('tokenauth')) {
      final token = headers['tokenauth']!;
      final displayToken =
          token.length > 6 ? '...${token.substring(token.length - 6)}' : token;
      AppLogger.log('🔑  Token: Bearer $displayToken');
    }

    // Imprime el cuerpo de la petición (payload)
    if (body != null) {
      try {
        // Usa un encoder con indentación para que el JSON sea legible
        const encoder = JsonEncoder.withIndent('  ');
        AppLogger.log('📦  Body:\n${encoder.convert(body)}');
      } catch (e) {
        // Si no es un JSON válido, lo imprime tal cual
        AppLogger.log('📦  Body (no-JSON);: $body');
      }
    }

    // Imprime la respuesta del servidor si existe
    if (response != null) {
      AppLogger.log('-------------------- 📥 RESPONSE 📥 ---------------------');
      final statusIcon =
          response.statusCode >= 200 && response.statusCode < 300 ? '✅' : '❌';
      AppLogger.log('$statusIcon Status Code: ${response.statusCode}');
      // Intenta formatear la respuesta también
      try {
        final decodedBody = jsonDecode(response.body);
        const encoder = JsonEncoder.withIndent('  ');
        AppLogger.log('📄  Response Body:\n${encoder.convert(decodedBody)}');
      } catch (e) {
        AppLogger.log('📄  Response Body (raw);:\n${response.body}');
      }
    }

    // Imprime cualquier error de conexión o de otro tipo
    if (error != null) {
      AppLogger.log('---------------------- 🔥 ERROR 🔥 ----------------------');
      AppLogger.log('🐞  Exception: $error');
      if (stackTrace != null) {
        AppLogger.log('ιχ  Stack Trace:\n$stackTrace');
      }
    }
    AppLogger.log('=========================================================\n');
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('tokenauth');
    } catch (e) {
      AppLogger.log('❌ Error obteniendo token: $e');
      return null;
    }
  }

  Future<void> _removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tokenauth');
    } catch (e) {
      AppLogger.log('❌ Error removiendo token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tokenauth', token);
    } catch (e) {
      AppLogger.log('❌ Error guardando token: $e');
    }
  }

  Map<String, String> _getHeaders({
    String? token,
    bool includeContentType = true,
  }) {
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['tokenauth'] = token;
    }
    return headers;
  }

  // Dentro de la clase ApiService

  // Reemplaza tu método _makeRequest completo con este
  Future<ApiResponse<T>> _makeRequest<T>({
    required HttpMethod method,
    required String endpoint,
    Map<String, String>? queryParams, // <<< PASO 1: AÑADE ESTE PARÁMETRO
    dynamic body,
    bool requiresAuth = true,
    bool showErrorDialog = true,
    T Function(dynamic)? parser,
    bool handle404AsSuccess = false,
  }) async {
    // <<< PASO 2: CONSTRUYE LA URI ANTES DEL TRY-CATCH >>>
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response? response;
    Map<String, String>? headers;

    // El resto de la función se mantiene casi igual, solo cambia el uso de 'uri'
    try {
      String? token;
      if (requiresAuth) {
        token = await _getToken();
        if (token == null || token.isEmpty) {
          final error =
              'Token de autenticación no encontrado. Por favor, inicia sesión.';
          _logRequestDetails(
            method: method.name.toUpperCase(),
            url: uri.toString(), // Usa la uri ya construida
            error: error,
          );
          if (showErrorDialog) handleAuthError(error, redirectToLogin: true);
          return ApiResponse<T>(
            success: false,
            error: error,
            statusCode: 401,
            headers: {},
          );
        }
      }

      headers = _getHeaders(token: token);

      _logRequestDetails(
        method: method.name.toUpperCase(),
        url: uri.toString(), // Usa la uri ya construida
        headers: headers,
        body: body,
      );

      switch (method) {
        case HttpMethod.get:
          response = await http
              .get(uri, headers: headers)
              .timeout(timeoutDuration);
          break;
        case HttpMethod.post:
          response = await http
              .post(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(timeoutDuration);
          break;
        case HttpMethod.put:
          response = await http
              .put(
                uri,
                headers: headers,
                body: body != null ? json.encode(body) : null,
              )
              .timeout(timeoutDuration);
          break;
        case HttpMethod.delete:
          response = await http
              .delete(uri, headers: headers)
              .timeout(timeoutDuration);
          break;
      }

      _logRequestDetails(
        method: method.name.toUpperCase(),
        url: uri.toString(), // Usa la uri ya construida
        response: response,
      );

      // <<< CORRECCIÓN EN _handleResponse >>>
      // Asegúrate de pasar 'handle404AsSuccess' aquí, que faltaba en tu código original.
      return _handleResponse<T>(
        response,
        parser: parser,
        showErrorDialog: showErrorDialog,
        handle404AsSuccess: handle404AsSuccess, // <-- Añade esto
      );
    } catch (e, stackTrace) {
      _logRequestDetails(
        method: method.name.toUpperCase(),
        url: uri.toString(), // Usa la uri ya construida
        headers: headers,
        response: response,
        error: e,
        stackTrace: stackTrace,
      );
      // ... el resto del catch sin cambios ...
      String errorMsg;
      int statusCode = 500;
      if (e is http.ClientException) {
        errorMsg = 'Error de conexión: ${e.message}';
        statusCode = 0;
      } else if (e is TimeoutException) {
        errorMsg =
            'Tiempo de espera agotado. Verifica tu conexión e intenta de nuevo.';
        statusCode = 408;
      } else {
        errorMsg = 'Error inesperado: ${e.toString()}';
      }

      if (showErrorDialog) this.showErrorDialog(errorMsg);
      return ApiResponse<T>(
        success: false,
        error: errorMsg,
        statusCode: statusCode,
        headers: {},
      );
    }
  }

  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response, {
    T Function(dynamic)? parser,
    bool showErrorDialog = true,
    bool handle404AsSuccess = false, // <-- AÑADE ESTO
  }) async {
    final responseHeaders = response.headers;

     // <<< AÑADE ESTA LÓGICA AQUÍ >>>
  // Si es un 404 y queremos tratarlo como éxito (lista vacía)
  if (response.statusCode == 404 && handle404AsSuccess) {
    AppLogger.log('ℹ️  Status 404 manejado como éxito (lista vacía);.');
    T? parsedData;
    // Intenta crear una lista vacía si el tipo esperado es una lista
    if (<T>[] is List<dynamic>) {
      try {
        parsedData = [] as T;
      } catch (e) {
        // si no, null
        parsedData = null;
      }
    }
    return ApiResponse<T>(
      success: true,
      data: parsedData,
      statusCode: response.statusCode,
      headers: responseHeaders,
    );
  }

  
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final dynamic responseData =
            response.body.isNotEmpty ? json.decode(response.body) : null;
        T? parsedData;
        if (parser != null && responseData != null) {
          parsedData = parser(responseData);
        } else if (responseData != null) {
          try {
            parsedData = responseData as T;
          } catch (e) {
            AppLogger.log(
              '⚠️ No se pudo castear responseData a T directamente sin parser: $e.',
            );
            if (null is T) {
              parsedData = null;
            } else if (responseData is T) {
              parsedData = responseData;
            } else {
              if (showErrorDialog) {
                this.showErrorDialog(
                  'Error al procesar los datos recibidos del servidor (tipo inesperado).',
                ); // <--- CAMBIO
              }
              return ApiResponse<T>(
                success: false,
                error: 'Error al procesar los datos recibidos (tipo).',
                statusCode: response.statusCode,
                headers: responseHeaders,
              );
            }
          }
        } else if (parser == null && responseData == null && null is T) {
          parsedData = null;
        }
        return ApiResponse<T>(
          success: true,
          data: parsedData,
          statusCode: response.statusCode,
          headers: responseHeaders,
        );
      } catch (e) {
        AppLogger.log('❌ Error parseando respuesta JSON: $e. Cuerpo: ${response.body}');
        const error =
            'Error en el formato de los datos recibidos del servidor.';
        if (showErrorDialog) {
          this.showErrorDialog(error); // <--- CAMBIO
        }
        return ApiResponse<T>(
          success: false,
          error: error,
          statusCode: response.statusCode,
          headers: responseHeaders,
        );
      }
    } else {
      return _handleHttpError(
        response,
        showErrorDialog: showErrorDialog,
        headers: responseHeaders,
      );
    }
  }

  Future<ApiResponse<T>> _handleHttpError<T>(
    http.Response response, {
    bool showErrorDialog = true,
    required Map<String, String> headers,
  }) async {
    String errorMessage = 'Error del servidor: ${response.statusCode}.';
    try {
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body);

        if (errorData is Map &&
            errorData.containsKey("Error") &&
            errorData["Error"] is Map &&
            errorData["Error"].containsKey("Message")) {
          errorMessage = errorData["Error"]["Message"];
        } else if (errorData is Map && errorData.containsKey("message")) {
          errorMessage = errorData["message"];
        } else if (errorData is String) {
          errorMessage = errorData;
        }

        if (response.statusCode == 401 ||
            errorMessage.toLowerCase().contains("sesión ha cambiado") ||
            errorMessage.toLowerCase().contains("jwt expired") ||
            errorMessage.toLowerCase().contains("token inválido") ||
            errorMessage.toLowerCase().contains("no autorizado")) {
          await _removeToken();

          final authErrorMessage =
              errorMessage.toLowerCase().contains("jwt expired")
                  ? 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'
                  : (errorMessage.toLowerCase().contains("sesión ha cambiado")
                      ? 'La sesión ha cambiado. Por favor, inicia sesión nuevamente.'
                      : 'No autorizado. Por favor, inicia sesión.');

          if (showErrorDialog) {
            handleAuthError(
              authErrorMessage,
              redirectToLogin: true,
            ); // <--- CAMBIO
          }

          return ApiResponse<T>(
            success: false,
            error: authErrorMessage,
            statusCode: response.statusCode,
            headers: headers,
          );
        }
      }
    } catch (e) {
      AppLogger.log(
        '❌ Error procesando cuerpo de respuesta de error: $e. Cuerpo original: ${response.body}',
      );
    }

    if (showErrorDialog) {
      this.showErrorDialog(
        errorMessage,
      ); // <--- CAMBIO (this. es opcional pero ayuda a la claridad)
    }

    return ApiResponse<T>(
      success: false,
      error: errorMessage,
      statusCode: response.statusCode,
      headers: headers,
    );
  }

  // <--- CAMBIO: MÉTODO AHORA PÚBLICO
  // Mostrar diálogo de error de autenticación
  void handleAuthError(String message, {bool redirectToLogin = false}) {
    if (_context == null || !(_context?.mounted ?? false)) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isDarkMode =
            Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: EdgeInsets.only(top: 25, bottom: 10),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 50,
                color: Colors.orangeAccent,
              ),
              SizedBox(height: 15),
              Text(
                'Acceso Requerido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
          actionsPadding: EdgeInsets.only(
            bottom: 15,
            right: 20,
            left: 20,
            top: 10,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(150, 44),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (redirectToLogin &&
                    _context != null &&
                    (_context?.mounted ?? false)) {
                  Navigator.pushNamedAndRemoveUntil(
                    _context!,
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // <--- CAMBIO: MÉTODO AHORA PÚBLICO y con parámetro de título opcional
  // Mostrar diálogo de error genérico
  void showErrorDialog(String message, {String title = 'Error'}) {
    if (_context == null || !(_context?.mounted ?? false)) return;

    showDialog(
      context: _context!,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final isDarkMode =
            Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ), // Usa el parámetro title
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Aceptar',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // === MÉTODOS PÚBLICOS PARA USAR EN LA APP ===

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams, // <-- Añádelo aquí
    bool requiresAuth = true,
    bool showErrorDialog = true,
    T Function(dynamic)? parser,
    bool handle404AsSuccess = false, // <-- AÑADE ESTE PARÁMETRO AQUÍ TAMBIÉN
  }) {
    return _makeRequest<T>(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParams: queryParams, // <-- Y pásalo aquí
      requiresAuth: requiresAuth,
      showErrorDialog: showErrorDialog,
      parser: parser,
      handle404AsSuccess: handle404AsSuccess, // <-- Y PÁSALO AQUÍ
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    bool showErrorDialog = true,
    T Function(dynamic)? parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      showErrorDialog: showErrorDialog,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
    bool showErrorDialog = true,
    T Function(dynamic)? parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
      showErrorDialog: showErrorDialog,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    bool showErrorDialog = true,
    T Function(dynamic)? parser,
  }) {
    return _makeRequest<T>(
      method: HttpMethod.delete,
      endpoint: endpoint,
      requiresAuth: requiresAuth,
      showErrorDialog: showErrorDialog,
      parser: parser,
    );
  }

  // Método para Login (ejemplo, se mantiene igual ya que usa http directamente)
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String usuario,
    required String password,
  }) async {
    try {
      AppLogger.log('🔄 Iniciando login para usuario: $usuario');
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: _getHeaders(includeContentType: true, token: null),
            body: json.encode({'usuario': usuario, 'password': password}),
          )
          .timeout(timeoutDuration);
      final responseHeaders = response.headers;

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['code'] == 200 ||
            responseBody['success'] == true ||
            responseBody.containsKey('token')) {
          final token = response.headers['tokenauth'] ?? responseBody['token'];
          if (token != null && token is String && token.isNotEmpty) {
            await _saveToken(token);
            AppLogger.log('🔑 Token guardado exitosamente');
            return ApiResponse<Map<String, dynamic>>(
              success: true,
              data: responseBody,
              statusCode: response.statusCode,
              headers: responseHeaders,
            );
          } else {
            const error = 'Token no encontrado en la respuesta del login.';
            if (_context != null) showErrorDialog(error); // <--- CAMBIO
            return ApiResponse<Map<String, dynamic>>(
              success: false,
              error: error,
              statusCode: response.statusCode,
              headers: responseHeaders,
            );
          }
        } else {
          final errorMessage =
              responseBody['Error']?['Message'] ??
              responseBody['message'] ??
              'Respuesta de login inesperada.';
          if (_context != null) showErrorDialog(errorMessage); // <--- CAMBIO
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            error: errorMessage,
            statusCode: response.statusCode,
            headers: responseHeaders,
          );
        }
      }
      return _handleHttpError(
        response,
        showErrorDialog: true,
        headers: responseHeaders,
      );
    } on http.ClientException catch (e) {
      AppLogger.log('❌ Error de conexión en login: $e');
      final error = 'Error de conexión: ${e.message}';
      showErrorDialog(error); // <--- CAMBIO
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 0,
        headers: {},
      );
    } on TimeoutException {
      AppLogger.log('⌛ Tiempo de espera agotado en login');
      const error = 'Tiempo de espera agotado al intentar iniciar sesión.';
      showErrorDialog(error); // <--- CAMBIO
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 408,
        headers: {},
      );
    } catch (e) {
      AppLogger.log('❌ Error inesperado en login: $e');
      final error = 'Error inesperado durante el login: ${e.toString()}';
      showErrorDialog(error); // <--- CAMBIO
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 500,
        headers: {},
      );
    }
  }

  // Método para cerrar sesión con llamada al endpoint (no necesita cambios)
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    // ... (Tu código de logout no necesita cambios)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/logout'),
            headers: {'tokenauth': token, 'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      final responseHeaders = response.headers;

      if (response.statusCode == 200) {
        await _removeToken();
        AppLogger.log('🔑 Token removido exitosamente');

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.body.isNotEmpty ? json.decode(response.body) : {},
          statusCode: response.statusCode,
          headers: responseHeaders,
        );
      } else {
        String errorMessage = 'Error al cerrar sesión: ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final errorData = json.decode(response.body);
            if (errorData is Map &&
                errorData.containsKey("Error") &&
                errorData["Error"] is Map) {
              errorMessage = errorData["Error"]["Message"] ?? errorMessage;
            } else if (errorData is Map && errorData.containsKey("message")) {
              errorMessage = errorData["message"];
            }
          }
        } catch (e) {
          AppLogger.log('❌ Error parseando respuesta de error de logout: $e');
        }

        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: errorMessage,
          statusCode: response.statusCode,
          headers: responseHeaders,
        );
      }
    } on http.ClientException catch (e) {
      final error = 'Error de conexión: ${e.message}';
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 0,
        headers: {},
      );
    } on TimeoutException {
      const error = 'Tiempo de espera agotado al cerrar sesión.';
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 408,
        headers: {},
      );
    } catch (e) {
      final error = 'Error inesperado durante el logout: ${e.toString()}';
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: error,
        statusCode: 500,
        headers: {},
      );
    }
  }
}
