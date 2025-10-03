// Archivo: lib/utils/dialog_helper.dart (o donde lo hayas puesto)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Añade esta importación si no la tienes
import 'package:finora_app/providers/theme_provider.dart'; // <-- Y esta también

/// Muestra un diálogo de confirmación basado en el diseño específico de la app.
Future<bool?> showCustomDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Aceptar',
  String cancelText = 'Cancelar',
  // El parámetro isDestructive ya no es necesario para el estilo,
  // pero lo mantenemos por si lo usas en otro lado.
  bool isDestructive = false, 
}) {
  // Obtenemos el theme provider directamente del contexto principal,
  // ya que el dialogContext no siempre lo tiene.
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDarkMode = themeProvider.isDarkMode;

  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        // 1. Título con icono
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Usamos el título que llega por parámetro
          ],
        ),
        // 2. Contenido del mensaje
        content: Text(
          content, // Usamos el contenido que llega por parámetro
          style: const TextStyle(fontSize: 14),
        ),
        // 3. Botones de acción
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false), // Devuelve false
            child: Text(
              cancelText, // Usamos el texto de cancelar del parámetro
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true), // Devuelve true
            child: Text(confirmText), // Usamos el texto de confirmar del parámetro
          ),
        ],
      );
    },
  );
}