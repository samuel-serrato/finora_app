import 'package:finora_app/dialog/about_dialog.dart.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/user_data_provider.dart'; // <-- CAMBIO 1: Importar el provider
import 'package:finora_app/screens/clientes.dart';
import 'package:finora_app/screens/creditos.dart';
import 'package:finora_app/screens/grupos.dart';
import 'package:finora_app/screens/reportes.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/routes.dart';
import 'providers/theme_provider.dart';
import 'package:finora_app/screens/home.dart';

import 'utils/app_logger.dart';

// CAMBIO 2: Constructor modificado para no recibir argumentos
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  // La lista se inicializará en el build, ya que depende de los datos del provider
  late List<NavigationItem> _navigationItems;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Ya no necesitamos initState para inicializar los items
  // porque necesitan datos del provider que no están disponibles aquí.

  void _initNavigationItems(UserDataProvider userData) {
    // CAMBIO 3: La inicialización ahora recibe los datos del usuario
    final username = userData.nombreUsuario;
    final userType = userData.tipoUsuario;

    _navigationItems = [
      NavigationItem(
        title: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: HomeScreen(username: username, tipoUsuario: userType),
      ),
      NavigationItem(
        title: 'Créditos',
        icon: Icons.wallet_outlined,
        selectedIcon: Icons.wallet,
        screen: SeguimientoScreenMobile(
          username: username,
          tipoUsuario: userType,
        ),
      ),
      NavigationItem(
        title: 'Grupos',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
        screen: GruposScreenMobile(username: username, tipoUsuario: userType),
      ),
      NavigationItem(
        title: 'Clientes',
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        screen: ClientesScreenMobile(username: username, tipoUsuario: userType),
      ),
      NavigationItem(
        title: 'Reportes',
        icon: Icons.insert_chart_outlined_rounded,
        selectedIcon: Icons.insert_chart_rounded,
        screen: ReportesScreenMobile(username: username, tipoUsuario: userType),
      ),
    ];
  }

  // ... (El resto de tus funciones como _buildPlaceholderScreen, _logout, _handleMenuOption no cambian)
  Future<void> _logout() async {
    final apiService = ApiService();
    apiService.setContext(context);

    // Diálogo de loading más bonito
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final colors = themeProvider.colors;

        return AlertDialog(
          backgroundColor: colors.backgroundPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colors.brandPrimary,
                  /*  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ), */
                ),
                SizedBox(height: 20),
                Text(
                  'Cerrando sesión...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await Future.delayed(Duration(milliseconds: 500)); // Delay más visible
      // Llamar al método logout() del ApiService
      final response = await apiService.logout();

      if (mounted) Navigator.of(context).pop();

      if (response.success) {
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text('Sesión cerrada correctamente'),
              duration: Duration(seconds: 2),
            ),
          );

          // Navegar a la pantalla de login
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      } else {
        // Error del servidor
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              content: Text(
                'Error al cerrar sesión: ${response.error ?? 'Error desconocido'}',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Error inesperado
      AppLogger.log('Error inesperado al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
            content: Text('Error inesperado: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // En tu archivo NavigationScreen.dart

  void _handleMenuOption(String value) {
    // Es una buena práctica cerrar el drawer antes de navegar.
   // Navigator.pop(context); 

    switch (value) {
      case 'profile':
        // Navegar a perfil
        break;

      // --- MODIFICACIÓN AQUÍ ---
      case 'gestionar_usuarios':
        // Navegar a gestión de usuarios usando la ruta nombrada
        Navigator.pushNamed(context, AppRoutes.gestionarUsuarios);
        break;

      // --- MODIFICACIÓN AQUÍ ---
      case 'configuracion':
        // Navegar a configuración
        Navigator.pushNamed(context, AppRoutes.configuracion);
        break;

       // --- 3. MODIFICA LA LLAMADA AQUÍ ---
      case 'about':
        // Llama a la función global que creaste, pasándole el context actual.
        showCustomAboutDialog(context);
        break;
      
      case 'theme':
        // El toggle del tema no necesita cerrar el drawer, así que lo manejamos sin el pop inicial.
        // Pero como ya lo pusimos arriba, para este caso no afecta mucho.
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.toggleTheme(!themeProvider.isDarkMode);
        break;
      case 'logout':
        _logout();
        break;
    }
  }

    Widget _buildEndDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final username = userData.nombreUsuario;
    final userType = userData.tipoUsuario;

    return Drawer(
      child: Container(
        color: colors.backgroundSideMenu,
        child: Column(
          children: [
            // Header (sin cambios)
            SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  top: 50,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.brandPrimary.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: colors.brandPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Información del usuario
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            userType,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Línea divisoria sutil (sin cambios)
            Container(
              height: 1,
              margin: EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 20),
              color: colors.textSecondary?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            ),

            // Opciones del menú
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 20,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMinimalDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Configuración',
                      onTap: () => _handleMenuOption('configuracion'),
                      colors: colors,
                    ),

                    // =====================>> INICIO DEL CAMBIO <<=====================
                    // Condición para mostrar la opción solo si el usuario es Admin
                    if (userType == 'Admin')
                      _buildMinimalDrawerItem(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Gestionar Usuarios',
                        onTap: () => _handleMenuOption('gestionar_usuarios'),
                        colors: colors,
                      ),
                    // =====================>> FIN DEL CAMBIO <<=====================
                    
                    _buildThemeToggleItem(colors, themeProvider),
                    _buildMinimalDrawerItem(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
                      onTap: () => _handleMenuOption('about'),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),

            // Línea divisoria sutil (sin cambios)
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: 24),
              color: colors.textSecondary?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
            ),

            // Botón de cerrar sesión minimalista (sin cambios)
            Container(
              padding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 50),
              child: _buildMinimalDrawerItem(
                icon: Icons.logout_outlined,
                title: 'Cerrar Sesión',
                onTap: () => _handleMenuOption('logout'),
                colors: colors,
                isDestructive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Widget especial para el toggle del tema
  Widget _buildThemeToggleItem(dynamic colors, ThemeProvider themeProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleMenuOption('theme'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: colors.textPrimary?.withOpacity(0.7) ?? Colors.grey,
                size: 22,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  themeProvider.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Indicador visual del estado actual
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: themeProvider.isDarkMode 
                      ? colors.brandPrimary?.withOpacity(0.3) 
                      : colors.textSecondary?.withOpacity(0.2),
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: 200),
                  alignment: themeProvider.isDarkMode 
                      ? Alignment.centerRight 
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeProvider.isDarkMode 
                          ? colors.brandPrimary 
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required dynamic colors,
    bool isDestructive = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final dynamic itemColors =
        themeProvider.colors; // Renombramos para evitar shadowing
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDestructive
                        ? Colors.red.withOpacity(0.8)
                        : itemColors.textPrimary?.withOpacity(0.7) ??
                            Colors.grey,
                size: 22,
              ),
              SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  color:
                      isDestructive
                          ? Colors.red.withOpacity(0.8)
                          : itemColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    final colors = themeProvider.colors;
    final username = userData.nombreUsuario;
    final isDarkMode = themeProvider.isDarkMode;

    _initNavigationItems(userData);

    final currentScreenTitle = _navigationItems[_selectedIndex].title;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: colors.backgroundPrimary,
        backgroundColor: colors.backgroundPrimary,
         title: _selectedIndex == 0 
        ? SizedBox(
            height: 40, // Altura ajustada para que se vea bien en el AppBar
            width: 120, // Ancho para un logo horizontal
            child: Image.asset(
              // Condición para elegir la imagen correcta según el tema
              themeProvider.isDarkMode
                  ? 'assets/finora_blanco.png' // Imagen para modo oscuro
                  : 'assets/finora.png', // Imagen para modo claro
              fit: BoxFit.contain, // Asegura que la imagen se escale correctamente sin deformarse
            ),
          )
        : Text(
            currentScreenTitle,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
          ),
        actions: [
          // >>> CAMBIO 3: Añade el widget del logo a la lista de acciones.
          _buildAppBarLogo(),

          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            padding: EdgeInsets.zero, // Elimina padding interno
            constraints:
                BoxConstraints(), // Elimina restricciones de tamaño por defecto
            icon: Container(
              width: 45, // Tamaño deseado
              height: 45,
               decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(24), // Bordes redondeados
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: colors.brandPrimary,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 10),
        ],
      ),
      endDrawer: _buildEndDrawer(),
      body: _navigationItems[_selectedIndex].screen,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ... El resto de tu código (_buildBottomNavBar, etc.) puede quedar igual.
  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.bottomNavBorder, width: 0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: colors.bottomNavRipple,
          splashColor: colors.bottomNavRipple,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: colors.bottomNavBackground,
          selectedItemColor: colors.bottomNavSelectedItem,
          unselectedItemColor: colors.bottomNavUnselectedItem,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items:
              _navigationItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              _selectedIndex == _navigationItems.indexOf(item)
                                  ? colors.bottomNavSelectedIconBackground
                                  : Colors.transparent,
                        ),
                        child: Icon(
                          _selectedIndex == _navigationItems.indexOf(item)
                              ? item.selectedIcon
                              : item.icon,
                          size: 24,
                        ),
                      ),
                      label: item.title,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildAppBarLogo() {
  return Consumer<UserDataProvider>(
    builder: (context, userDataProvider, _) {
      final themeProvider = Provider.of<ThemeProvider>(
        context,
        listen: false,
      );
      final isDarkMode = themeProvider.isDarkMode;
      final logoImage = userDataProvider.getLogoForTheme(isDarkMode);

      if (logoImage != null && logoImage.rutaImagen.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            width: 70, // Ancho del rectángulo
            height: 45, // Alto del rectángulo
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(24), // Bordes redondeados
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // Igual al del Container
              child: Padding(
                padding: const EdgeInsets.all(4.0), // padding opcional interno
                child: Image.network(
                  '$baseUrl/imagenes/subidas/${logoImage.rutaImagen}',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    },
  );
}

}

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}