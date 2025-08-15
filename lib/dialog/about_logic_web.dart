// Archivo: about_logic_web.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:js_util';
import 'dart:html' as html;

// Versión WEB para obtener la versión (¡AHORA ES MÁS FÁCIL!)
Future<String> getPlatformSpecificVersion() async {
  // package_info_plus se encarga de todo.
  // Lee el archivo version.json que Flutter crea automáticamente.
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

// La lógica para buscar actualizaciones sigue siendo específica de la web,
// así que la mantenemos como estaba.
Future<void> checkPlatformSpecificVersion(BuildContext context) async {
  final result = await callMethod<String>(html.window, 'checkForUpdates', []);

  if (!context.mounted) return;

  final SnackBar snackBar;
  switch (result) {
    case 'update-found':
      Navigator.pop(context); 
      return; 
    case 'no-update-available':
      snackBar = const SnackBar(content: Text('¡Estás al día! Ya tienes la última versión.'), backgroundColor: Colors.green);
      break;
    default:
      snackBar = const SnackBar(content: Text('Ocurrió un error al buscar actualizaciones.'), backgroundColor: Colors.red);
  }
  
  Navigator.pop(context);
  await Future.delayed(const Duration(milliseconds: 300));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}