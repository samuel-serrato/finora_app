import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/routes.dart';
import 'providers/theme_provider.dart';

class NavigationScreen extends StatefulWidget {
  final String username;
  final String rol;
  final String userId;
  final String userType;

  const NavigationScreen({
    Key? key,
    required this.username,
    required this.rol,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  late List<NavigationItem> _navigationItems;
  
  @override
  void initState() {
    super.initState();
    _initNavigationItems();
  }

  void _initNavigationItems() {
    _navigationItems = [
      NavigationItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        screen: _buildPlaceholderScreen('Dashboard'),
      ),
    ];

    // Añade elementos de navegación basados en el rol del usuario
    if (widget.rol == 'administrador' || widget.rol == 'superadmin') {
      _navigationItems.addAll([
        NavigationItem(
          title: 'Usuarios',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          screen: _buildPlaceholderScreen('Usuarios'),
        ),
        NavigationItem(
          title: 'Configuración',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          screen: _buildPlaceholderScreen('Configuración'),
        ),
      ]);
    }

    // Elementos comunes para todos los roles
    _navigationItems.addAll([
      NavigationItem(
        title: 'Créditos',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        screen: _buildPlaceholderScreen('Créditos'),
      ),
      NavigationItem(
        title: 'Pagos',
        icon: Icons.payment_outlined,
        selectedIcon: Icons.payment,
        screen: _buildPlaceholderScreen('Pagos'),
      ),
      NavigationItem(
        title: 'Reportes',
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        screen: _buildPlaceholderScreen('Reportes'),
      ),
    ]);
  }

  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Módulo de $title',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Esta pantalla está en construcción',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tokenauth');
    
    Navigator.pushNamedAndRemoveUntil(
      context, 
      AppRoutes.login, 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Finora'),
        actions: [
          // Botón para cambiar entre modo claro/oscuro
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              
            }
          ),
          // Menú de usuario
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(widget.username),
                  subtitle: Text(widget.rol),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
        ],
      ),
      // Mostrar un drawer en pantallas pequeñas o botones de navegación lateral en pantallas grandes
      drawer: isLargeScreen ? null : _buildDrawer(),
      // Contenido principal
      body: Row(
        children: [
          // Navegación lateral para pantallas grandes
          if (isLargeScreen) _buildSideNavigation(),
          // Contenido principal
          Expanded(
            child: _navigationItems[_selectedIndex].screen,
          ),
        ],
      ),
      // Barra de navegación inferior para pantallas pequeñas
      bottomNavigationBar: isLargeScreen ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.username),
            accountEmail: Text(widget.rol),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
                style: TextStyle(fontSize: 24, color: Colors.blue),
              ),
            ),
          ),
          ..._navigationItems.map((item) => ListTile(
            leading: Icon(
              _selectedIndex == _navigationItems.indexOf(item)
                ? item.selectedIcon
                : item.icon,
            ),
            title: Text(item.title),
            selected: _selectedIndex == _navigationItems.indexOf(item),
            onTap: () {
              setState(() {
                _selectedIndex = _navigationItems.indexOf(item);
              });
              Navigator.pop(context); // Cierra el drawer
            },
          )).toList(),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.all,
      destinations: _navigationItems
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.title),
              ))
          .toList(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 6,
    );
  }

  Widget _buildBottomNavBar() {
    // Si hay muchos elementos, mostramos solo los primeros 5 en el bottom bar
    List<NavigationItem> visibleItems = _navigationItems.length > 5
        ? _navigationItems.sublist(0, 5)
        : _navigationItems;
        
    return BottomNavigationBar(
      currentIndex: _selectedIndex > visibleItems.length - 1 ? 0 : _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      items: visibleItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.selectedIcon),
                label: item.title,
              ))
          .toList(),
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