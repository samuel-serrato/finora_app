import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Importa tus modelos
import 'package:finora_app/models/image_data.dart';
import 'package:finora_app/models/userData.dart';
import 'package:finora_app/models/licencia.dart';

import '../utils/app_logger.dart';

class UserDataProvider extends ChangeNotifier {
  // --- ESTADO INTERNO ---
  UserData? _currentUser;
  bool _isInitialized = false;

  // --- GETTERS PÚBLICOS ---
  // Acceso seguro a los datos del usuario actual
  UserData? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;

  // Getters para acceso rápido a propiedades comunes (como los tenías antes)
  String get nombreNegocio => _currentUser?.nombreNegocio ?? '';
  List<ImageData> get imagenes => _currentUser?.imagenes ?? [];
  String get nombreUsuario => _currentUser?.nombreCompleto ?? '';
  String get tipoUsuario => _currentUser?.tipoUsuario ?? '';
  String get idnegocio => _currentUser?.idnegocio ?? '';
  String get idusuario => _currentUser?.idusuarios ?? '';
  double get redondeo => _currentUser?.redondeo ?? 0.0;
  Licencia? get licenciaActiva => _currentUser?.licenciaActiva;

  // --- MÉTODOS PRINCIPALES DE SESIÓN ---

  /// Guarda el objeto de usuario completo, lo persiste y notifica a los listeners.
  /// Este método ahora centraliza la lógica de guardado.
  /// Guarda el objeto de usuario completo, lo persiste y notifica a los listeners.
/// Este método ahora centraliza la lógica de guardado.
Future<void> setUserData(UserData user) async {
  _currentUser = user;
  _isInitialized = true;

  // --- AÑADIR ESTE AppLogger.log ---
  // Imprime las restricciones cargadas para verificar que están ahí.
  AppLogger.log("==========================================================");
  AppLogger.log("[UserDataProvider] Nuevos datos de usuario establecidos.");
  if (user.licenciaActiva != null && user.licenciaActiva!.restricciones.isNotEmpty) {
      AppLogger.log("🔍 Restricciones de licencia cargadas:");
      // Mapeamos cada restricción a su formato JSON para una lectura más fácil.
      user.licenciaActiva!.restricciones.forEach((r) {
          AppLogger.log("  - ${r.toJson()}");
      });
  } else {
      AppLogger.log("⚠️ No se encontraron restricciones en la licencia activa.");
  }
  AppLogger.log("==========================================================");
  // --- FIN DEL AppLogger.log ---

  final prefs = await SharedPreferences.getInstance();
  final String userJson = json.encode(user.toJson());
  await prefs.setString('userData', userJson);

  notifyListeners();
}

  /// Carga los datos del usuario desde SharedPreferences al iniciar la app.
  Future<bool> loadUserDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('userData');

    if (userJson != null) {
      _currentUser = UserData.fromJson(json.decode(userJson));
      _isInitialized = true;
      notifyListeners();
      return true;
    }

    _isInitialized = true;
    notifyListeners();
    return false;
  }

  /// Limpia todos los datos de la sesión.
  Future<void> clearUserData() async {
    _currentUser = null;
    _isInitialized = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await prefs.remove('rememberedUser');

    notifyListeners();
  }


  // --- MÉTODOS ESPECÍFICOS DE ACTUALIZACIÓN (REINCORPORADOS) ---
  // Estas son las funciones que faltaban, ahora adaptadas.

  /// Obtiene el logo correcto según el tema (oscuro/claro).
  ImageData? getLogoForTheme(bool isDarkMode) {
    if (!isLoggedIn) return null;
    final String targetType = isDarkMode ? 'logoBlanco' : 'logoColor';
    try {
      // Intenta encontrar el logo preferido
      return _currentUser!.imagenes.firstWhere((img) => img.tipoImagen == targetType);
    } catch (e) {
      // Si falla, intenta devolver cualquier otro logo como fallback
      try {
        final String fallbackType = isDarkMode ? 'logoColor' : 'logoBlanco';
        return _currentUser!.imagenes.firstWhere((img) => img.tipoImagen == fallbackType);
      } catch (e) {
        return null; // No hay logos disponibles
      }
    }
  }

  /// Actualiza la ruta de un logo específico o lo añade si no existe.
  Future<void> actualizarLogo(String tipoImagen, String nuevaRuta) async {
    if (!isLoggedIn) return;

    // Hacemos una copia mutable de la lista de imágenes
    List<ImageData> updatedImages = List.from(_currentUser!.imagenes);
    final index = updatedImages.indexWhere((img) => img.tipoImagen == tipoImagen);

    if (index != -1) {
      // Si existe, lo actualizamos
      updatedImages[index] = ImageData(tipoImagen: tipoImagen, rutaImagen: nuevaRuta);
    } else {
      // Si no existe, lo añadimos
      updatedImages.add(ImageData(tipoImagen: tipoImagen, rutaImagen: nuevaRuta));
    }
    
    // Creamos un nuevo objeto UserData con la lista de imágenes actualizada
    // Es una buena práctica crear un nuevo objeto en lugar de mutar el existente
    final updatedUser = UserData(
      imagenes: updatedImages,
      // Copiamos el resto de las propiedades del usuario actual
      idusuarios: _currentUser!.idusuarios,
      usuario: _currentUser!.usuario,
      tipoUsuario: _currentUser!.tipoUsuario,
      nombreCompleto: _currentUser!.nombreCompleto,
      email: _currentUser!.email,
      roles: _currentUser!.roles,
      dbName: _currentUser!.dbName,
      nombreNegocio: _currentUser!.nombreNegocio,
      idnegocio: _currentUser!.idnegocio,
      redondeo: _currentUser!.redondeo,
      licencia: _currentUser!.licencia,
    );

    // Usamos nuestro método centralizado para guardar y notificar
    await setUserData(updatedUser);
  }

  /// Actualiza datos específicos del perfil del usuario.
  Future<void> actualizarDatosUsuario({
    String? nombreCompleto,
    String? tipoUsuario,
    String? email,
  }) async {
    if (!isLoggedIn) return;

    final updatedUser = UserData(
      // Usamos los nuevos valores si se proporcionan, si no, mantenemos los antiguos
      nombreCompleto: nombreCompleto ?? _currentUser!.nombreCompleto,
      tipoUsuario: tipoUsuario ?? _currentUser!.tipoUsuario,
      email: email ?? _currentUser!.email,
      // Copiamos el resto de las propiedades
      idusuarios: _currentUser!.idusuarios,
      usuario: _currentUser!.usuario,
      roles: _currentUser!.roles,
      dbName: _currentUser!.dbName,
      nombreNegocio: _currentUser!.nombreNegocio,
      imagenes: _currentUser!.imagenes,
      idnegocio: _currentUser!.idnegocio,
      redondeo: _currentUser!.redondeo,
      licencia: _currentUser!.licencia,
    );

    await setUserData(updatedUser);
  }

  /// Actualiza el valor de redondeo.
  Future<void> actualizarRedondeo(double nuevoRedondeo) async {
    if (!isLoggedIn) return;
    
    final updatedUser = UserData(
      redondeo: nuevoRedondeo,
      // Copiamos el resto de las propiedades
      idusuarios: _currentUser!.idusuarios,
      usuario: _currentUser!.usuario,
      tipoUsuario: _currentUser!.tipoUsuario,
      nombreCompleto: _currentUser!.nombreCompleto,
      email: _currentUser!.email,
      roles: _currentUser!.roles,
      dbName: _currentUser!.dbName,
      nombreNegocio: _currentUser!.nombreNegocio,
      imagenes: _currentUser!.imagenes,
      idnegocio: _currentUser!.idnegocio,
      licencia: _currentUser!.licencia,
    );
    
    await setUserData(updatedUser);
  }


   // --- MÉTODOS GENÉRICOS DE VALIDACIÓN DE RESTRICCIONES ---

  /// Busca una restricción por su `tipoARestringir` y devuelve su valor ('0', '5', 'Ilimitado', etc.).
  /// Devuelve `null` si el usuario no está logueado, no tiene licencia o la restricción no se encuentra.
  
String? getValorRestriccion(String tipoARestringir) {
  if (!isLoggedIn || licenciaActiva == null) {
    return null; // No hay AppLogger.logs aquí porque la siguiente función ya lo indica.
  }

  try {
    // Este AppLogger.log nos dice qué estamos buscando
    AppLogger.log("  -> [getValorRestriccion] Buscando restricción para: '$tipoARestringir'");

    final restriccion = licenciaActiva!.restricciones.firstWhere(
      (r) => r.tipoARestringir == tipoARestringir,
    );
    
    // Este AppLogger.log nos dice qué encontró y qué valor tiene
    AppLogger.log("  -> [getValorRestriccion] ✅ Encontrada. Valor: '${restriccion.restriccion}'");
    return restriccion.restriccion;

  } catch (e) {
    // Este AppLogger.log es crucial, nos dice si NO encontró la restricción
    AppLogger.log("  -> [getValorRestriccion] ❌ No se encontró una restricción para '$tipoARestringir'.");
    return null;
  }
}

// --- MÉTODO DE ACCESO ÚNICO Y SIMPLIFICADO ---

  /// Valida si una funcionalidad está incluida en el plan del usuario,
  /// basándose únicamente en la existencia de su 'tipoARestringir' en la lista de restricciones.
  /// Devuelve `true` si la restricción se encuentra, sin importar el valor que contenga.
  ///
  /// Ejemplo de uso:
  /// `userData.tieneAccesoA('bitacora')` -> true (si existe) / false (si no existe)
  /// `userData.tieneAccesoA('clientes')` -> true (si existe) / false (si no existe)
  bool tieneAccesoA(String tipoARestringir) {
    AppLogger.log("\n--- 🕵️ Validando acceso para: '$tipoARestringir' (solo por existencia) ---");

    if (!isLoggedIn || licenciaActiva == null) {
      AppLogger.log("  -> Decisión: No logueado o sin licencia. ACCESO DENEGADO.");
      AppLogger.log("------------------------------------------------------------------");
      return false;
    }

    try {
      // Intentamos encontrar el elemento. Si `firstWhere` tiene éxito, existe.
      licenciaActiva!.restricciones.firstWhere(
        (r) => r.tipoARestringir == tipoARestringir,
      );
      // Si la línea anterior no lanzó una excepción, significa que lo encontró.
      AppLogger.log("  -> Decisión: La restricción fue encontrada. ACCESO CONCEDIDO.");
      AppLogger.log("------------------------------------------------------------------");
      return true;
    } catch (e) {
      // Si `firstWhere` lanza una excepción, es porque no lo encontró.
      AppLogger.log("  -> Decisión: La restricción NO fue encontrada. ACCESO DENEGADO.");
      AppLogger.log("------------------------------------------------------------------");
      return false;
    }
  }

}