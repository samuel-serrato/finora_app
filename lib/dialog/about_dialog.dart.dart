import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';


// --- Funciones de Ayuda ---

// Obtiene la versión local de la app desde el pubspec.yaml
Future<String> getLocalVersion() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  } catch (e) {
    AppLogger.log("Error al obtener la versión: $e");
    return 'N/A';
  }
}

// Lógica para buscar actualizaciones (aquí puedes poner tu implementación real)
Future<void> checkAppVersion(BuildContext context) async {
  // Simula una llamada de red
  await Future.delayed(const Duration(seconds: 2));

  // Muestra un resultado
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Tu aplicación está actualizada!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}

// --- El Widget del Diálogo ---

void showCustomAboutDialog(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final colors = themeProvider.colors;
  final isDarkMode = themeProvider.isDarkMode;

  // Hacemos el tamaño responsivo
  final screenWidth = MediaQuery.of(context).size.width;
  final bool isMobile = screenWidth < 600;
  final dialogWidth = isMobile ? screenWidth * 0.90 : 400.0;

  showDialog(
    context: context,
    builder: (context) {
      // StatefulBuilder nos permite manejar el estado del botón de carga
      // sin necesidad de un StatefulWidget completo.
      bool isCheckingForUpdate = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: colors.backgroundPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(24.0),
              // Dejamos que el contenido defina la altura
              child: Column(
                mainAxisSize: MainAxisSize.min, // <-- Clave para la altura automática
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    // Asegúrate de que tienes ambos assets en tu carpeta 'assets/'
                    isDarkMode
                        ? 'assets/finora_blanco.png'
                        : 'assets/finora.png', // Usando el asset que ya tenías
                    width: 150,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Desarrollado por CODX',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: colors.bottomNavBorder, height: 1),
                  const SizedBox(height: 20),
                  FutureBuilder<String>(
                    future: getLocalVersion(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(color: colors.brandPrimary);
                      } else if (snapshot.hasError) {
                        return Text(
                          'Versión N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.brandPrimary,
                          ),
                        );
                      } else {
                        final version = snapshot.data ?? 'N/A';
                        return Column(
                          children: [
                            Text(
                              'Versión $version',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.brandPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botón para buscar actualizaciones con estado de carga
                            SizedBox(
                              height: 36, // Damos una altura fija para evitar saltos
                              child: isCheckingForUpdate
                                  ? CircularProgressIndicator(color: colors.brandPrimary)
                                  : TextButton.icon(
                                      onPressed: () async {
                                        setState(() => isCheckingForUpdate = true);
                                        await checkAppVersion(context);
                                        // Solo actualiza si el widget todavía está montado
                                        if(context.mounted) {
                                          setState(() => isCheckingForUpdate = false);
                                        }
                                      },
                                      icon: Icon(Icons.system_update_alt_rounded, color: colors.brandPrimary),
                                      label: Text(
                                        'Buscar actualizaciones',
                                        style: TextStyle(
                                          color: colors.brandPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  //const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}