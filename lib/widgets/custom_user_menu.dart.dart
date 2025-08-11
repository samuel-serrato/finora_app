// Archivo: lib/widgets/custom_user_menu.dart
import 'package:finora_app/constants/routes.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importa tus providers y rutas aquí
// import 'package:tu_app/providers/user_data_provider.dart';
// import 'package:tu_app/routes/app_routes.dart';

class CustomUserMenu extends StatelessWidget {
  final UserDataProvider userData;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final Function(BuildContext) showCustomAboutDialog; // Función que viene de tu AppBar

  const CustomUserMenu({
    Key? key,
    required this.userData,
    required this.onLogout,
    required this.isDarkMode,
    required this.showCustomAboutDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // Cursor de click al hacer hover
      child: GestureDetector(
        onTap: () async {
        // Obtener la posición del widget para posicionar el menú
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final Offset offset = renderBox.localToGlobal(Offset.zero);
        final Size size = renderBox.size;

        // Mostrar el menú personalizado
        final String? selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy + size.height + 8, // 8px de separación
            offset.dx + 220, // ancho mínimo
            offset.dy + size.height + 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          elevation: 10,
          items: [
            PopupMenuItem(
              value: 'configuracion',
              child: Row(
                children: [
                  Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
                  const SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.grey[800]
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'acerca_de',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: isDarkMode ? Colors.blue[200] : Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Acerca de',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.grey[800]
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app, color: isDarkMode ? Colors.redAccent[200] : Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.grey[800]
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        // Manejar la selección
        if (selected != null) {
          if (selected == 'logout') {
            bool confirm = await _showLogoutDialog(context);
            if (confirm) {
              onLogout();
            }
          } else if (selected == 'configuracion') {
            Navigator.pushNamed(context, AppRoutes.configuracion);
          } else if (selected == 'acerca_de') {
            showCustomAboutDialog(context);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF5162F6),
              radius: 18,
              child: Icon(
                _getIconForUserType(userData.tipoUsuario),
                color: Colors.white,
                size: 22
              ),
            ),
            SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData.nombreUsuario,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    userData.tipoUsuario,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey.shade900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white : Colors.black),
          ],
        ),
        ),
      ),
    );
  }

  // Función para mostrar el diálogo de logout
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        contentPadding: EdgeInsets.only(top: 25, bottom: 10),
        title: Column(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              size: 60,
              color: Color(0xFF5162F6),
            ),
            SizedBox(height: 15),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            '¿Estás seguro de que quieres salir de tu cuenta?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
        actionsPadding: EdgeInsets.only(bottom: 20, right: 25, left: 25),
        actions: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white : Colors.grey[700],
                    side: BorderSide(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Cancelar'),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5162F6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Cerrar Sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  // Función helper para obtener el ícono según el tipo de usuario
  IconData _getIconForUserType(String tipoUsuario) {
    switch (tipoUsuario.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'usuario':
        return Icons.person;
      case 'supervisor':
        return Icons.supervisor_account;
      default:
        return Icons.person;
    }
  }
}