import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Necesario para codificar/decodificar JSON

import 'package:finora_app/models/image_data.dart'; // Asegúrate de que la ruta sea correcta

class UserDataProvider extends ChangeNotifier {
  // --- ESTADO EN MEMORIA ---
  // Estos son los datos que el resto de la app usará.
  String _nombreNegocio = '';
  List<ImageData> _imagenes = [];
  String _nombreUsuario = '';
  String _tipoUsuario = '';
  String _idnegocio = '';
  String _idusuario = '';
  double _redondeo = 0;

  // NUEVO: Un flag para saber si ya intentamos cargar los datos del almacenamiento.
  // Esto evita que la UI intente mostrar datos antes de que estén listos.
  bool _isInitialized = false;

  // --- GETTERS PÚBLICOS ---
  // La UI accede a los datos a través de estos getters.
  String get nombreNegocio => _nombreNegocio;
  List<ImageData> get imagenes => _imagenes;
  String get nombreUsuario => _nombreUsuario;
  String get tipoUsuario => _tipoUsuario;
  String get idnegocio => _idnegocio;
  String get idusuario => _idusuario;
  double get redondeo => _redondeo;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _nombreUsuario.isNotEmpty && _idusuario.isNotEmpty;

  // --- MÉTODOS DE CICLO DE VIDA DE LA SESIÓN ---

  /// 1. MÉTODO PARA GUARDAR DATOS DESPUÉS DE UN LOGIN EXITOSO
  /// Se llama desde tu pantalla de Login.
  Future<void> saveUserDataOnLogin({
    required String nombreNegocio,
    required List<ImageData> imagenes,
    required String nombreUsuario,
    required String tipoUsuario,
    required String idnegocio,
    required String idusuario,
    required double redondeo,
  }) async {
    // Primero, actualizamos el estado en memoria.
    _nombreNegocio = nombreNegocio;
    _imagenes = imagenes;
    _nombreUsuario = nombreUsuario;
    _tipoUsuario = tipoUsuario;
    _idnegocio = idnegocio;
    _idusuario = idusuario;
    _redondeo = redondeo;
    _isInitialized = true;

    // Luego, guardamos los datos en el almacenamiento persistente.
    final prefs = await SharedPreferences.getInstance();
    
    // Guardamos los valores simples.
    await prefs.setString('nombreNegocio', nombreNegocio);
    await prefs.setString('nombreUsuario', nombreUsuario);
    await prefs.setString('tipoUsuario', tipoUsuario);
    await prefs.setString('idnegocio', idnegocio);
    await prefs.setString('idusuario', idusuario);
    await prefs.setDouble('redondeo', redondeo);

    // Para la lista de imágenes, la convertimos a un string en formato JSON.
    final List<Map<String, dynamic>> imagenesJson = imagenes.map((img) => img.toJson()).toList();
    await prefs.setString('imagenes', json.encode(imagenesJson));

    // Notificamos a los widgets que escuchan para que se reconstruyan con los nuevos datos.
    notifyListeners();
  }

  /// 2. MÉTODO PARA CARGAR DATOS AL INICIAR LA APP
  /// Se llama desde tu función `main()` antes de `runApp()`.
  Future<bool> loadUserDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Intentamos leer un dato clave (ej. id de usuario). Si no existe, no hay sesión.
    final storedUserId = prefs.getString('idusuario');
    if (storedUserId == null || storedUserId.isEmpty) {
      _isInitialized = true; // Marcamos como inicializado (aunque vacío).
      notifyListeners();
      return false; // Indicamos que no se encontró una sesión.
    }

    // Si encontramos una sesión, cargamos todos los datos.
    _nombreNegocio = prefs.getString('nombreNegocio') ?? '';
    _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
    _tipoUsuario = prefs.getString('tipoUsuario') ?? '';
    _idnegocio = prefs.getString('idnegocio') ?? '';
    _idusuario = storedUserId;
    _redondeo = prefs.getDouble('redondeo') ?? 0.0;

    // Cargamos y decodificamos la lista de imágenes desde el string JSON.
    final String? imagenesString = prefs.getString('imagenes');
    if (imagenesString != null) {
      final List<dynamic> imagenesJson = json.decode(imagenesString);
      _imagenes = imagenesJson.map((jsonItem) => ImageData.fromJson(jsonItem)).toList();
    } else {
      _imagenes = [];
    }

    _isInitialized = true;
    // Notificamos a los widgets que los datos de la sesión ya están listos.
    notifyListeners();
    return true; // Indicamos que la sesión se cargó exitosamente.
  }

  /// 3. MÉTODO PARA LIMPIAR DATOS AL CERRAR SESIÓN
  /// Se llama desde tu función de Logout.
  Future<void> clearUserData() async {
    // Primero, limpiamos el estado en memoria.
    _nombreNegocio = '';
    _imagenes = [];
    _nombreUsuario = '';
    _tipoUsuario = '';
    _idnegocio = '';
    _idusuario = '';
    _redondeo = 0.0;
    _isInitialized = false; // El estado ya no es válido hasta el próximo login.

    // Luego, borramos todo del almacenamiento persistente.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Notificamos para que la UI reaccione al estado de "sesión cerrada".
    notifyListeners();
  }

  // --- MÉTODOS AUXILIARES ---
  // (Estos no necesitan cambios, ya que operan sobre el estado en memoria)

  ImageData? getLogoForTheme(bool isDarkMode) {
    final String targetType = isDarkMode ? 'logoBlanco' : 'logoColor';
    try {
      return _imagenes.firstWhere((img) => img.tipoImagen == targetType);
    } catch (e) {
      // Si no encuentra el logo preferido, intenta usar el otro como fallback.
      final String fallbackType = isDarkMode ? 'logoColor' : 'logoBlanco';
      try {
        return _imagenes.firstWhere((img) => img.tipoImagen == fallbackType);
      } catch (e) {
        return null; // No se encontró ningún logo.
      }
    }
  }

  void actualizarLogo(String tipoImagen, String nuevaRuta) {
    final index = _imagenes.indexWhere((img) => img.tipoImagen == tipoImagen);
    if (index != -1) {
      _imagenes[index] =
          ImageData(tipoImagen: tipoImagen, rutaImagen: nuevaRuta);
    } else {
      _imagenes.add(ImageData(tipoImagen: tipoImagen, rutaImagen: nuevaRuta));
    }
    notifyListeners();
  }

  // Nuevo método para actualizar datos específicos
  void actualizarDatosUsuario({
    String? nombreCompleto,
    String? tipoUsuario,
    String? email,
  }) {
    if (nombreCompleto != null) {
      _nombreUsuario = nombreCompleto;
    }
    if (tipoUsuario != null) {
      _tipoUsuario = tipoUsuario;
    }
    // Puedes añadir más campos según sea necesario
    notifyListeners(); // Notifica a los listeners que los datos han cambiado
  }

  void actualizarRedondeo(double nuevoRedondeo) {
    _redondeo = nuevoRedondeo;
    notifyListeners();
  }
}
