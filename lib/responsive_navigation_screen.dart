import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/screens/bitacora.dart';
import 'package:finora_app/screens/screens_config/gestionar_usuarios_screen.dart';
import 'package:finora_app/widgets/custom_user_menu.dart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Importaciones de Providers y Pantallas ---
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/screens/home.dart';
import 'package:finora_app/screens/creditos.dart';
import 'package:finora_app/screens/grupos.dart';
import 'package:finora_app/screens/clientes.dart';
import 'package:finora_app/screens/reportes.dart';
// <<< CAMBIO 1: Importar la nueva pantalla de Bitácora >>>

// Servicios y utilidades
import 'package:finora_app/dialog/about_dialog.dart.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/constants/routes.dart';

// Clase de datos para definir la información de cada item de navegación
class _NavigationItemInfo {
  final String title;
  final IconData icon;
  final IconData? selectedIcon; // Opcional, solo para móvil
  final Widget screen;

  _NavigationItemInfo({
    required this.title,
    required this.icon,
    this.selectedIcon,
    required this.screen,
  });
}

class ResponsiveNavigationScreen extends StatefulWidget {
  const ResponsiveNavigationScreen({Key? key}) : super(key: key);

  @override
  _ResponsiveNavigationScreenState createState() =>
      _ResponsiveNavigationScreenState();
}

class _ResponsiveNavigationScreenState
    extends State<ResponsiveNavigationScreen> {
  // Punto de quiebre para cambiar entre layouts
  static const double desktopBreakpoint = 800.0;

  // Controladores y estado para AMBAS plataformas
  final PageController _pageController = PageController(initialPage: 0);
  final SideMenuController _sideMenuController = SideMenuController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
 // --- ¡CAMBIA ESTO! ---
  // Key _homeScreenKey = UniqueKey(); // Reemplaza esto...
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>(); // ...por esto.
  


  int _selectedIndex = 0;
  bool _isDesktopMenuOpen = true;

  bool? _wasDesktopLayout;

  // Lista única de información de navegación.
  List<_NavigationItemInfo> _navigationItems = [];

  //late final UpdateService  _updateService; // 1. Declara la instancia del servicio

  final AppColors colors = AppColors();

  @override
  void initState() {
    super.initState();
    // _updateService = UpdateService(); // 2. Inicializa el servicio

    // 3. Añade un listener para mostrar el SnackBar cuando haya una actualización
    // _updateService.isUpdateAvailable.addListener(_showUpdateDialog);
  }

  @override
  void dispose() {
    // No olvides quitar el listener para evitar memory leaks
    //_updateService.isUpdateAvailable.removeListener(_showUpdateDialog);
    // ... tu otro código de dispose ...
//    _homeScreenRebuildNotifier.dispose(); // No olvides hacer dispose
    super.dispose();
  }

  void _onNavigationItemSelected(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    _sideMenuController.changePage(index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildNavigationItems();
  }

 
  // --- ¡MODIFICA ESTA FUNCIÓN! ---
  void _refreshHomeScreen() {
    // Ahora usamos la GlobalKey para acceder al estado y llamar a su método público
    _homeScreenKey.currentState?.refreshData();
    print("🔄 Solicitando a HomeScreen que refresque sus datos y su calendario.");
  }


  void _buildNavigationItems() {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final username = userData.nombreUsuario;
    final userType = userData.tipoUsuario;

    List<_NavigationItemInfo> items = [
      _NavigationItemInfo(
        title: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: HomeScreen(
           key: _homeScreenKey, // <--- ¡APLICA LA KEY AQUÍ!
          username: username,
          tipoUsuario: userType,
        ),
      ),
      _NavigationItemInfo(
        title: 'Créditos',
        icon: Icons.wallet_outlined,
        selectedIcon: Icons.wallet,
        screen: SeguimientoScreenMobile(
          username: username,
          tipoUsuario: userType,
        ),
      ),
      _NavigationItemInfo(
        title: 'Grupos',
        icon: Icons.groups_2_outlined,
        selectedIcon: Icons.groups_rounded,
        screen: GruposScreenMobile(username: username, tipoUsuario: userType),
      ),
      _NavigationItemInfo(
        title: 'Clientes',
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        screen: ClientesScreenMobile(username: username, tipoUsuario: userType),
      ),
    ];

    if (userType == 'Admin') {
      items.add(
        _NavigationItemInfo(
          title: 'Usuarios',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          screen: GestionarUsuariosScreen(),
        ),
      );
    }

    if (userType != 'Invitado') {
      items.add(
        _NavigationItemInfo(
          title: 'Reportes',
          icon: Icons.insert_chart_outlined,
          selectedIcon: Icons.insert_chart_rounded,
          screen: ReportesScreenMobile(
            username: username,
            tipoUsuario: userType,
          ),
        ),
      );
    }

    // <<< CAMBIO 2: Añadir "Bitácora" a la lista de navegación principal >>>
    // Esto hace que aparezca en el menú de Desktop y esté disponible para la navegación.
    // <<< CORRECCIÓN CON PARÉNTESIS >>>
    // Primero validamos si el rol es Admin O Contador, y LUEGO validamos el acceso.
    if ((userType == 'Admin' || userType == 'Contador') &&
        userData.tieneAccesoA('bitacora')) {
      items.add(
        _NavigationItemInfo(
          title: 'Bitácora',
          icon: Icons.history_outlined, // Icono para desktop y móvil (inactivo)
          selectedIcon: Icons.history_edu, // Icono para móvil (activo)
          screen: const BitacoraScreen(), // La pantalla que acabamos de crear
        ),
      );
    }

    setState(() {
      _navigationItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_navigationItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > desktopBreakpoint;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_wasDesktopLayout != null && _wasDesktopLayout != isDesktop) {
            _handleLayoutChange(isDesktop);
          }
          _wasDesktopLayout = isDesktop;
        });

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  void _handleLayoutChange(bool isNowDesktop) {
    // Encontrar los índices
    final int usuariosIndex = _navigationItems.indexWhere(
      (item) => item.title == 'Usuarios',
    );
    // <<< AÑADE ESTA LÍNEA >>>
    final int bitacoraIndex = _navigationItems.indexWhere(
      (item) => item.title == 'Bitácora',
    );

    // <<< MODIFICA LA CONDICIÓN DEL IF >>>
    if (usuariosIndex == -1 && bitacoraIndex == -1) return;

    if (isNowDesktop) {
      // ... sin cambios aquí
    } else {
      // <<< MODIFICA ESTA CONDICIÓN >>>
      // Si la pantalla activa era Usuarios O Bitácora, ve a Home.
      if (_selectedIndex == usuariosIndex || _selectedIndex == bitacoraIndex) {
        _onNavigationItemSelected(0);
      }
    }
  }

  //============================================================================
  // CONSTRUCCIÓN DE LA INTERFAZ DE DESKTOP
  //============================================================================
  //============================================================================
  // CONSTRUCCIÓN DE LA INTERFAZ DE DESKTOP
  //============================================================================
  Widget _buildDesktopLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != _selectedIndex) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });

    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

     final List<Widget> pagesWithAppBar = _navigationItems.map((item) {
    return Scaffold( // <--- Vuelve a la versión simple
      backgroundColor: isDarkMode ? const Color(0xff121212) : const Color(0xFFF4F6F8),
      appBar: CustomDesktopAppBar(
        title: item.title,
        onLogout: _logout,
        onRefreshHome: _refreshHomeScreen, // <--- Pasa la función
        // Quita la lógica de onRefreshHome por ahora
      ),
      body: item.screen,
    );
  }).toList();

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            // El ancho sigue siendo controlado por la misma variable de estado
            width: _isDesktopMenuOpen ? 180 : 70,
            child: SideMenu(
              controller: _sideMenuController,
              style: SideMenuStyle(
                itemOuterPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
                displayMode:
                    _isDesktopMenuOpen
                        ? SideMenuDisplayMode.open
                        : SideMenuDisplayMode.compact,
                hoverColor:
                    isDarkMode ? Colors.blueGrey[800] : Colors.blue[100],
                selectedHoverColor:
                    isDarkMode ? Colors.blueGrey[700] : const Color(0xFF2D336B),
                selectedColor:
                    isDarkMode ? Colors.blueGrey[900] : const Color(0xFF5162F6),
                selectedTitleTextStyle: const TextStyle(color: Colors.white),
                selectedIconColor: Colors.white,
                unselectedTitleTextStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                unselectedIconColor: isDarkMode ? Colors.white : Colors.black,
                backgroundColor: colors.backgroundCardDark,
              ),
              // <<< ¡CAMBIO PRINCIPAL AQUÍ! >>>
              // Se reemplaza el widget complejo por una llamada a un método más limpio.
              title: _buildDesktopMenuTitle(isDarkMode),
              items:
                  _navigationItems.asMap().entries.map((entry) {
                    return SideMenuItem(
                      title: entry.value.title,
                      onTap: (tappedIndex, _) {
                        _onNavigationItemSelected(tappedIndex);
                      },
                      icon: Icon(entry.value.icon),
                    );
                  }).toList(),
              footer: _buildDesktopFooter(isDarkMode),
            ),
          ),
          Container(
            width: 1,
            height: double.infinity,
            color: isDarkMode ? const Color(0xFF353641)! : Colors.grey[300]!,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: pagesWithAppBar,
            ),
          ),
        ],
      ),
    );
  }

  // <<<  NUEVO MÉTODO AUXILIAR PARA EL TÍTULO DEL MENÚ  >>>
  // Este método replica la lógica de tu app CODX para mostrar el título
  // de forma diferente si el menú está abierto o cerrado.
  Widget _buildDesktopMenuTitle(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child:
          _isDesktopMenuOpen
              // --- ESTADO ABIERTO: Muestra logo grande y botón al lado ---
              ? Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 20.0,
                    ),
                    child: SizedBox(
                      height: 35,
                      child: Image.asset(
                        isDarkMode
                            ? 'assets/finora_blanco.png'
                            : 'assets/finora.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    // <<< INICIO DE LA CORRECCIÓN >>>
                    padding: EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip:
                        'Cerrar menú', // Es buena práctica añadir un tooltip en desktop
                    // <<< FIN DE LA CORRECCIÓN >>>
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                    onPressed: () => setState(() => _isDesktopMenuOpen = false),
                  ),
                ],
              )
              // --- ESTADO CERRADO: Muestra logo pequeño y botón debajo ---
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Image.asset(
                        'assets/finora_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ), // Espacio entre el logo y el botón
                  IconButton(
                    // <<< INICIO DE LA CORRECCIÓN >>>
                    padding: EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Abrir menú',
                    // <<< FIN DE LA CORRECCIÓN >>>
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                    onPressed: () => setState(() => _isDesktopMenuOpen = true),
                  ),
                ],
              ),
    );
  }

  Widget _buildDesktopFooter(bool isDarkMode) {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child:
          _isDesktopMenuOpen
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Desarrollado por',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                      fontFamily: 'Verdana',
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 70,
                    height: 30,
                    child: Image.asset(
                      isDarkMode
                          ? 'assets/codx_transparente_blanco.png'
                          : 'assets/codx_transparente_full_negro.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }

  // <<<====================== NUEVO WIDGET ======================>>>
  // Añade este nuevo método completo.
  Widget _buildMobileFooter(bool isDarkMode) {
    return Padding(
      // Añadimos un poco de espacio para que no quede pegado
      padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Desarrollado por',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 10,
              fontFamily: 'Verdana',
              fontWeight: FontWeight.w100,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 70,
            height: 30,
            child: Image.asset(
              isDarkMode
                  ? 'assets/codx_transparente_blanco.png'
                  : 'assets/codx_transparente_full_negro.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
  // <<<===========================================================>>>

  //============================================================================
  // CONSTRUCCIÓN DE LA INTERFAZ MÓVIL
  //============================================================================

  Widget _buildMobileLayout() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    final currentScreenTitle = _navigationItems[_selectedIndex].title;
    final List<Widget> pages =
        _navigationItems.map((item) => item.screen).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        // Tu AppBar no cambia, está perfecto.
        automaticallyImplyLeading: false,
        elevation: 0,
        surfaceTintColor: colors.backgroundPrimary,
        backgroundColor: colors.backgroundPrimary,
        title:
            _selectedIndex == 0
                ? SizedBox(
                  height: 40,
                  width: 120,
                  child: Image.asset(
                    isDarkMode
                        ? 'assets/finora_blanco.png'
                        : 'assets/finora.png',
                    fit: BoxFit.contain,
                  ),
                )
                : Text(
                  currentScreenTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
        actions: [
          _buildAppBarLogo(),
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Text(
                  userData.nombreUsuario.isNotEmpty
                      ? userData.nombreUsuario[0].toUpperCase()
                      : 'U',
                  style: TextStyle(color: colors.brandPrimary, fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      endDrawer: _buildEndDrawer(),
      body: IndexedStack(index: _selectedIndex, children: pages),

      // <<< ======================= MODIFICA ESTA PARTE ======================= >>>
      bottomNavigationBar: BottomAppBar(
        // En lugar de EdgeInsets.zero, vamos a añadir un padding en la parte inferior.
        // Prueba con un valor pequeño como 8 o 10.
        padding: const EdgeInsets.only(bottom: 8.0),

        elevation: 0,
        color: colors.bottomNavBackground,
        child: _buildBottomNavBar(),
      ),
      // <<< ======================= FIN DE LA MODIFICACIÓN ====================== >>>
      // --- AÑADE ESTE BOTÓN TEMPORAL ---
      /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simplemente cambia el valor para disparar el listener.
          _updateService.isUpdateAvailable.value = true;
        },
        tooltip: 'Simular Actualización',
        child: const Icon(Icons.update),
        backgroundColor:
            Colors.orange, // Un color diferente para que sepas que es de prueba
      ), */
      // --- FIN DEL CÓDIGO AÑADIDO ---
    );
  }

  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // <<< TODA ESTA LÓGICA DE FILTRADO ESTÁ PERFECTA, NO LA TOQUES >>>
    final navBarItems =
        _navigationItems
            .where(
              (item) => item.title != 'Usuarios' && item.title != 'Bitácora',
            )
            .toList();

    int bottomNavIndex = _selectedIndex;
    final currentSelectedItemTitle = _navigationItems[_selectedIndex].title;
    if (currentSelectedItemTitle == 'Usuarios' ||
        currentSelectedItemTitle == 'Bitácora') {
      bottomNavIndex = -1;
    } else {
      bottomNavIndex = navBarItems.indexWhere(
        (item) => item.title == currentSelectedItemTitle,
      );
    }

    // <<< EL CAMBIO ESTÁ AQUÍ, SOLO DEVOLVEMOS EL WIDGET DIRECTAMENTE >>>
    return BottomNavigationBar(
      // <-- Sin el SafeArea envolviéndolo
      currentIndex: bottomNavIndex == -1 ? 0 : bottomNavIndex,
      onTap: (tappedIndexInBottomNav) {
        final String tappedTitle = navBarItems[tappedIndexInBottomNav].title;
        final int globalIndex = _navigationItems.indexWhere(
          (item) => item.title == tappedTitle,
        );

        if (globalIndex != -1) {
          _onNavigationItemSelected(globalIndex);
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.bottomNavBackground,
      selectedItemColor: colors.bottomNavSelectedItem,
      unselectedItemColor: colors.bottomNavUnselectedItem,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      elevation: 0,
      showUnselectedLabels: true,
      items:
          navBarItems.map((item) {
            return BottomNavigationBarItem(
              label: item.title,
              icon: Icon(item.icon, size: 24),
              activeIcon: Icon(item.selectedIcon ?? item.icon, size: 24),
            );
          }).toList(),
    );
  }

  // --- MÉTODOS HELPER (logout, dialogs, etc.) ---

  // <<< AÑADE ESTA FUNCIÓN COMPLETA >>>
  void _showBitacoraDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = MediaQuery.of(context).size.height;

            const double mobileBreakpoint = 768.0;

            double dialogMaxWidth;
            double dialogMaxHeight;
            BorderRadius dialogBorderRadius;

            if (screenWidth < mobileBreakpoint) {
              dialogMaxWidth = screenWidth;
              //dialogMaxHeight = screenHeight * 0.95;
              dialogMaxHeight = screenHeight * 0.99;
              dialogBorderRadius = const BorderRadius.vertical(
                top: Radius.circular(20),
              );
            } else {
              dialogMaxWidth = screenWidth * 0.7;
              if (dialogMaxWidth > 900) dialogMaxWidth = 900;
              dialogMaxHeight = screenHeight * 0.85;
              dialogBorderRadius = BorderRadius.circular(16);
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: screenWidth < mobileBreakpoint ? 0 : 40,
                ),
                child: SizedBox(
                  width: dialogMaxWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                    child: ClipRRect(
                      borderRadius: dialogBorderRadius,
                      // La única diferencia real es esta línea:
                      child: const BitacoraScreen(), // Tu pantalla de bitácora
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    // ... tu código de logout sin cambios ...
    final apiService = ApiService();
    if (!mounted) return;
    apiService.setContext(context);

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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colors.brandPrimary),
                const SizedBox(height: 20),
                const Text(
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
      final response = await apiService.logout();
      if (mounted) Navigator.of(context).pop();

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              content: Text('Sesión cerrada correctamente'),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              content: Text(
                'Error al cerrar sesión: ${response.error ?? 'Error desconocido'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
            content: Text('Error inesperado: $e'),
          ),
        );
      }
    }
  }

  void _showGestionarUsuariosDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = MediaQuery.of(context).size.height;

            const double mobileBreakpoint = 768.0;

            double dialogMaxWidth;
            double dialogMaxHeight;
            BorderRadius dialogBorderRadius;

            if (screenWidth < mobileBreakpoint) {
              dialogMaxWidth = screenWidth;
              //dialogMaxHeight = screenHeight * 0.95;
              dialogMaxHeight = screenHeight * 0.99;
              dialogBorderRadius = const BorderRadius.vertical(
                top: Radius.circular(20),
              );
            } else {
              dialogMaxWidth = screenWidth * 0.7;
              if (dialogMaxWidth > 900) dialogMaxWidth = 900;
              dialogMaxHeight = screenHeight * 0.85;
              dialogBorderRadius = BorderRadius.circular(16);
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: screenWidth < mobileBreakpoint ? 0 : 40,
                ),
                child: SizedBox(
                  width: dialogMaxWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                    child: ClipRRect(
                      borderRadius: dialogBorderRadius,
                      child:
                          GestionarUsuariosScreen(), // Tu pantalla de usuarios
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleMenuOption(String value) {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    Future.delayed(const Duration(milliseconds: 250), () async {
      switch (value) {
        case 'gestionar_usuarios':
          _showGestionarUsuariosDialog();
          break;
        case 'bitacora':
          _showBitacoraDialog();
          break;
          case 'configuracion':
        final result = await Navigator.pushNamed(context, AppRoutes.configuracion);
        if (result == true) {
          _refreshHomeScreen(); // <--- LLAMA A LA FUNCIÓN AQUÍ TAMBIÉN
        }
        break;
        // --- FIN DE LA MODIFICACIÓN ---
        case 'about':
          showCustomAboutDialog(context);
          break;
        case 'theme':
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          themeProvider.toggleTheme(!themeProvider.isDarkMode);
          break;
        case 'logout':
          _logout();
          break;
      }
    });
  }

  Widget _buildEndDrawer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // --- CÓDIGO CORRECTO ---
    final String? planUsuario = userData.licenciaActiva?.nombre;

    return Drawer(
      child: Container(
        color: colors.backgroundSideMenu,
        child: Column(
          children: [
            SafeArea(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  bottom: 24,
                  left: 20,
                  right: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.brandPrimary.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          userData.nombreUsuario.isNotEmpty
                              ? userData.nombreUsuario[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: colors.brandPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userData.nombreUsuario,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            planUsuario != null && planUsuario.isNotEmpty
                                ? "${userData.tipoUsuario} · Plan ${planUsuario}"
                                : userData.tipoUsuario,
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
            Container(
              height: 1,
              margin: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: 20,
              ),
              color:
                  colors.textSecondary?.withOpacity(0.1) ??
                  Colors.grey.withOpacity(0.1),
            ),
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
                    if (userData.tipoUsuario == 'Admin')
                      _buildMinimalDrawerItem(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Gestionar Usuarios',
                        onTap: () => _handleMenuOption('gestionar_usuarios'),
                        colors: colors,
                      ),
                    // <<< CAMBIO 4: Añadir "Bitácora" al menú lateral de móvil >>>
                    // <<< CORRECCIÓN CON PARÉNTESIS AQUÍ TAMBIÉN >>>
                    if ((userData.tipoUsuario == 'Admin' ||
                            userData.tipoUsuario == 'Contador') &&
                        userData.tieneAccesoA('bitacora'))
                      _buildMinimalDrawerItem(
                        icon: Icons.history_outlined,
                        title: 'Bitácora',
                        colors: colors,
                        onTap:
                            () => _handleMenuOption(
                              'bitacora',
                            ), // <-- ¡CORRECTO! Llama al manejador de opciones.
                      ),
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
            // <<< MODIFICACIÓN 2: Añade la llamada al nuevo footer aquí >>>
            //_buildMobileFooter(isDarkMode),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color:
                  colors.textSecondary?.withOpacity(0.1) ??
                  Colors.grey.withOpacity(0.1),
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 16,
                bottom: 50,
              ),
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

  Widget _buildThemeToggleItem(dynamic colors, ThemeProvider themeProvider) {
    // ... tu código sin cambios ...
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleMenuOption('theme'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: colors.textPrimary?.withOpacity(0.7) ?? Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 20),
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
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      themeProvider.isDarkMode
                          ? colors.brandPrimary?.withOpacity(0.3)
                          : colors.textSecondary?.withOpacity(0.2),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      themeProvider.isDarkMode
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          themeProvider.isDarkMode
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
    // ... tu código sin cambios ...
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDestructive
                        ? Colors.red.withOpacity(0.8)
                        : colors.textPrimary?.withOpacity(0.7) ?? Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  color:
                      isDestructive
                          ? Colors.red.withOpacity(0.8)
                          : colors.textPrimary,
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

  Widget _buildAppBarLogo() {
    // ... tu código sin cambios ...
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
              width: 70,
              height: 45,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
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
                    errorBuilder:
                        (context, error, stackTrace) => const SizedBox.shrink(),
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

// --- Widgets de AppBar y Menú de Usuario ---
// (Tu código existente, sin cambios)

class CustomDesktopAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onLogout;
  final VoidCallback onRefreshHome; // <--- CAMBIA LA KEY POR ESTO

  @override
  final Size preferredSize;

  CustomDesktopAppBar({
    Key? key,
    required this.title,
    required this.onLogout,
    required this.onRefreshHome,
  }) : preferredSize = const Size.fromHeight(60.0),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colors = themeProvider.colors;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 1,
      shadowColor: isDarkMode ? Color(0xFF8C8FAD) : Colors.grey[300]!,
      surfaceTintColor: colors.backgroundCardDark,
      backgroundColor: colors.backgroundCardDark,
      titleSpacing: 24,

      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),

      actions: [
        IconButton(
          tooltip: 'Cambiar tema',
          icon: Icon(
            isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
          onPressed: () => themeProvider.toggleTheme(!isDarkMode),
        ),

        const SizedBox(width: 8),
        _buildAppBarLogo(context, isDarkMode, baseUrl),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: CustomUserMenu(
            userData: userData,
            onLogout: onLogout,
            isDarkMode: isDarkMode,
            showCustomAboutDialog: showCustomAboutDialog,
            onRefreshHome: onRefreshHome, // <--- PASA LA FUNCIÓN
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildAppBarLogo(
    BuildContext context,
    bool isDarkMode,
    String baseUrl,
  ) {
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
    final logoImage = userDataProvider.getLogoForTheme(isDarkMode);

    if (logoImage != null && logoImage.rutaImagen.isNotEmpty) {
      return Container(
        width: 100,
        height: 40,
        padding: const EdgeInsets.all(4.0),
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
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
