import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importamos el paquete
import 'package:flutter/foundation.dart';
import 'dart:js' as js;

import 'package:finora_app/constants/colors.dart'; // Asegúrate que esta ruta es correcta

// Tu función puente con JS no necesita cambios.
void _updatePwaThemeColor(Color color) {
  if (kIsWeb) {
    final hexColor = '#${color.value.toRadixString(16).substring(2)}';
    js.context.callMethod('updatePwaThemeColor', [hexColor]);
  }
}

class ThemeProvider with ChangeNotifier {
  // El estado por defecto es 'light'.
  ThemeMode _themeMode = ThemeMode.light;
  final AppColors colors = AppColors();

  // Clave que usaremos para guardar el valor en SharedPreferences.
  static const String _themePreferenceKey = 'isDarkMode';

  /// CONSTRUCTOR
  ThemeProvider() {
    // Cuando se crea el provider por primera vez (al iniciar la app),
    // inmediatamente intentamos cargar la preferencia guardada.
    _loadThemePreference();
  }

  // --- GETTERS ---
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // --- LÓGICA DE PERSISTENCIA ---

  /// Carga la preferencia de tema desde SharedPreferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Leemos el valor booleano. Si no existe ('??'), usamos 'false' como valor por defecto.
    final bool isDark = prefs.getBool(_themePreferenceKey) ?? false;
    
    // Actualizamos el estado interno con el valor cargado.
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    colors.setDarkMode(isDark);
    _updatePwaThemeColor(colors.backgroundPrimary);

    // Notificamos a los oyentes para que la UI se reconstruya con el tema correcto.
    notifyListeners();
  }

  /// Guarda la preferencia de tema en SharedPreferences.
  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, isDark);
  }

  // --- MÉTODO PÚBLICO PARA CAMBIAR EL TEMA ---

  /// Este es el método que la UI llama para cambiar el tema.
  void toggleTheme(bool isDark) {
    // Comprobamos si el tema realmente está cambiando para evitar trabajo innecesario.
    if ((isDark && _themeMode == ThemeMode.dark) || (!isDark && _themeMode == ThemeMode.light)) {
      return; // No hay cambios, no hacemos nada.
    }

    // 1. Actualizamos el estado en memoria.
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    colors.setDarkMode(isDark);
    _updatePwaThemeColor(colors.backgroundPrimary);
    
    // 2. Guardamos la nueva preferencia en el almacenamiento persistente.
    _saveThemePreference(isDark);

    // 3. Notificamos a la UI que debe reconstruirse.
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