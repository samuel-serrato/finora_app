import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importamos el paquete
//import 'package:flutter/foundation.dart';
//import 'dart:js' as js;

import 'package:finora_app/constants/colors.dart'; // Asegúrate que esta ruta es correcta
import 'package:finora_app/helpers/pwa_theme_helper.dart';

import '../utils/app_logger.dart'; // <-- AÑADE ESTA LÍNEA


/* ELIMINA ESTA FUNCIÓN DE AQUÍ
void _updatePwaThemeColor(Color color) {
  if (kIsWeb) {
    final hexColor = '#${color.value.toRadixString(16).substring(2)}';
    js.context.callMethod('updatePwaThemeColor', [hexColor]);
  }
}
*/

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final AppColors colors = AppColors();
  static const String _themePreferenceKey = 'isDarkMode';

  // 1. El constructor ahora está VACÍO.
  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // 2. Creamos este nuevo método público para la inicialización.
  Future<void> init() async {
    // 3. Movemos la llamada a la función de carga aquí.
    await _loadThemePreference();
  }

  // _loadThemePreference se mantiene igual, pero ahora se llama de forma segura.
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isDark = prefs.getBool(_themePreferenceKey) ?? false;
      
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      colors.setDarkMode(isDark);
      
      updatePwaThemeColor(colors.backgroundPrimary);

      // NO necesitamos notifyListeners() aquí porque la UI aún no se ha construido.
    } catch (e) {
      AppLogger.log('Error al cargar las preferencias del tema: $e');
      // Establecemos valores por defecto si algo falla.
      _themeMode = ThemeMode.light;
      colors.setDarkMode(false);
    }
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDark);
  }

  void toggleTheme(bool isDark) {
    if ((isDark && _themeMode == ThemeMode.dark) || (!isDark && _themeMode == ThemeMode.light)) {
      return;
    }

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    colors.setDarkMode(isDark);
    
    // Llama a la nueva función importada
    updatePwaThemeColor(colors.backgroundPrimary);
    
    _saveThemePreference(isDark);
    notifyListeners();
  }


  // --- TU CÓDIGO DE DATEPICKER NO NECESITA CAMBIOS ---
  ThemeData get datePickerTheme {
    // Si el tema actual es oscuro...
    if (isDarkMode) {
      return ThemeData.dark().copyWith(
        // Esquema de colores para el DatePicker en modo oscuro
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5162F6), // Color del header y del día seleccionado
          onPrimary: Colors.white,      // Color del texto sobre el primario (ej. en el header)
          surface: Color(0xFF2A2D3E), // Color de fondo del diálogo
          onSurface: Colors.white,      // Color del texto de los días del mes
        ),
        // Estilo para los botones "OK" y "CANCELAR"
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5162F6), // Color del texto de los botones
          ),
        ),
        dialogBackgroundColor: const Color(0xFF2B2B2B), // Fondo explícito del diálogo
      );
    } 
    // Si no, es modo claro...
    else {
      return ThemeData.light().copyWith(
        // Esquema de colores para el DatePicker en modo claro
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF5162F6), // Color del header y del día seleccionado
          onPrimary: Colors.white,      // Color del texto sobre el primario
          surface: Colors.white,        // Color de fondo del diálogo
          onSurface: Colors.black87,    // Color del texto de los días del mes
        ),
        // Estilo para los botones "OK" y "CANCELAR"
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5162F6), // Color del texto de los botones
          ),
        ),
        dialogBackgroundColor: Colors.white,
      );
    }
  }
}