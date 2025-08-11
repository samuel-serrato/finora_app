// Pega esta clase de widget en tu archivo.

import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HoverableActionButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const HoverableActionButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  _HoverableActionButtonState createState() => _HoverableActionButtonState();
}

class _HoverableActionButtonState extends State<HoverableActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    // Determinamos los colores basados en el estado de hover
    final Color backgroundColor = _isHovered
        ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200)
        : colors.backgroundCard;
    
    final Color borderColor = (isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3));
   /*  final Color borderColor = _isHovered
        ? Colors.blueAccent.withOpacity(0.5)
        : (isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3)); */

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      // Cuando el mouse entra, actualizamos el estado
      onEnter: (_) => setState(() => _isHovered = true),
      // Cuando el mouse sale, revertimos el estado
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // Usamos AnimatedContainer para una transición suave del color
        child: Container(
         
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor, // Color dinámico
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor, // Borde dinámico
              width: _isHovered ? 1.3 : 1.3, // Ancho de borde dinámico
            ),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(_isHovered ? 0.15 : 0.1),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}