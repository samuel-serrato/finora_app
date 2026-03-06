// ignore_for_file: avoid_web_libraries_in_flutter
// Archivo: about_logic_web.dart

// ignore_for_file: avoid_web_libraries_in_flutter
// ignore_for_file: uri_does_not_exist  <-- ¡AÑADE ESTA LÍNEA!

// Archivo: about_logic_web.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

// ... resto de tu código

// Versión WEB para obtener la versión
Future<String> getPlatformSpecificVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<void> checkPlatformSpecificVersion(BuildContext context) async {
  final jsPromise = js_util.callMethod(html.window, 'checkForUpdates', []);
  final result = await js_util.promiseToFuture<String>(jsPromise);

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