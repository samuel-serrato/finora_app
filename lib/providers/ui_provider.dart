import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiProvider with ChangeNotifier {
  // null = Automático
  // 1, 2, 3 = Columnas fijas
  int? _crossAxisCount;

  int? get crossAxisCount => _crossAxisCount;

  UiProvider() {
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos 0 para representar "Automático" en disco
    final int valorGuardado = prefs.getInt('layout_cross_axis_count') ?? 0;
    
    if (valorGuardado == 0) {
      _crossAxisCount = null;
    } else {
      _crossAxisCount = valorGuardado;
    }
    notifyListeners();
  }

  Future<void> setCrossAxisCount(int valor) async {
    // Si el valor es 0, lo interpretamos como Automático (null)
    if (valor == 0) {
      _crossAxisCount = null;
    } else {
      _crossAxisCount = valor;
    }
    
    // Actualizamos la UI inmediatamente
    notifyListeners();

    // Guardamos en disco
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('layout_cross_axis_count', valor);
  }
}