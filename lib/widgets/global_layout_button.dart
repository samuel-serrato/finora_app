import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/ui_provider.dart';

class GlobalLayoutButton extends StatefulWidget {
  const GlobalLayoutButton({super.key});

  @override
  State<GlobalLayoutButton> createState() => _GlobalLayoutButtonState();
}

class _GlobalLayoutButtonState extends State<GlobalLayoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final uiProvider = Provider.of<UiProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    final currentCount = uiProvider.crossAxisCount;

    // Determinar ícono
    IconData iconData;
    if (currentCount == null || currentCount > 1) {
      iconData = Icons.grid_view_rounded;
    } else {
      iconData = Icons.view_list_rounded;
    }

    // Estilos Hover
    final Color backgroundColor = _isHovered
        ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200)
        : colors.backgroundCard;

    return PopupMenuButton<int>(
      tooltip: 'Cambiar vista',
      offset: const Offset(0, 35),
      onSelected: (int value) {
        uiProvider.setCrossAxisCount(value);
      },
      color: colors.backgroundPrimary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      
      // Botón con Hover
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(_isHovered ? 0.15 : 0.1),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Icon(
            iconData,
            size: 20,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
      
      // Items del menú
      itemBuilder: (context) => [
        _buildItem(1, '1 Columna', Icons.view_list_rounded, colors, currentCount),
        _buildItem(2, '2 Columnas', Icons.grid_view_rounded, colors, currentCount),
        _buildItem(3, '3 Columnas', Icons.view_quilt_rounded, colors, currentCount),
        const PopupMenuDivider(),
        _buildItem(0, 'Automático', Icons.dynamic_feed_rounded, colors, currentCount),
      ],
    );
  }

  PopupMenuItem<int> _buildItem(
    int value,
    String text,
    IconData icon,
    dynamic colors,
    int? currentCount,
  ) {
    final bool isSelected = (currentCount == value) || (currentCount == null && value == 0);
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}