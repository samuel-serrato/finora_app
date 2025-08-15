import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Versión IO para obtener la versión
Future<String> getPlatformSpecificVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

// Versión IO para buscar actualizaciones (no hace nada)
Future<void> checkPlatformSpecificVersion(BuildContext context) async {
  // En escritorio/móvil, esta función no está disponible.
  // Cerramos el diálogo y mostramos un mensaje informativo.
  if (!context.mounted) return;
  Navigator.pop(context);

  await Future.delayed(const Duration(milliseconds: 300));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('La búsqueda de actualizaciones solo está disponible en la versión web.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}