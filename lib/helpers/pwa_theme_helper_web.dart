import 'dart:html' as html; // Importamos la librería 'dart:html'
import 'package:flutter/material.dart';

/// Implementación para la web. Manipula el DOM directamente.
void updatePwaThemeColor(Color color) {
  // 1. Busca el meta tag del theme-color por su ID en el HTML.
  //    Asegúrate de que tu tag en `index.html` tenga `id="theme-color-meta"`.
  final metaElement = html.document.getElementById('theme-color-meta');

  if (metaElement != null) {
    // 2. Convierte el color de Dart a un string hexadecimal CSS (ej. #RRGGBB).
    //    El `substring(2)` quita el 'FF' del canal alfa.
    final hexColor = '#${color.value.toRadixString(16).substring(2)}';
    
    // 3. Actualiza el atributo 'content' del meta tag directamente desde Dart.
    metaElement.setAttribute('content', hexColor);
  }
}