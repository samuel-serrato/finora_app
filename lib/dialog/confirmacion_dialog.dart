// Archivo: lib/dialogs/confirmacion_dialog.dart

import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Un diálogo genérico y reutilizable para confirmaciones
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = "Confirmar",
  String cancelText = "Cancelar",
}) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final colors = themeProvider.colors;

  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: colors.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: colors.textPrimary)),
        content: Text(content, style: TextStyle(color: colors.textSecondary)),
        actions: <Widget>[
          TextButton(
            child: Text(cancelText, style: TextStyle(color: colors.textSecondary)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.brandPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
  return result ?? false; // Devuelve false si el diálogo se cierra sin seleccionar opción
}