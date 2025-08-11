import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoProvider with ChangeNotifier {
  String? _colorLogoPath;
  String? _whiteLogoPath;
  
  LogoProvider() {
    _loadSavedPaths();
  }
  
  // Getters
  String? get colorLogoPath => _colorLogoPath;
  String? get whiteLogoPath => _whiteLogoPath;
  
  // Setters
  Future<void> setColorLogoPath(String? path) async {
    _colorLogoPath = path;
    await _savePath('color_logo_path', path);
    notifyListeners();
  }
  
  Future<void> setWhiteLogoPath(String? path) async {
    _whiteLogoPath = path;
    await _savePath('white_logo_path', path);
    notifyListeners();
  }
  
  // Cargar rutas guardadas
  Future<void> _loadSavedPaths() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _colorLogoPath = prefs.getString('color_logo_path');
    _whiteLogoPath = prefs.getString('white_logo_path');
    notifyListeners();
  }
  
  // Guardar ruta
  Future<void> _savePath(String key, String? value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
  
}