import 'package:finora_app/screens/creditos.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/routes.dart';
import 'providers/theme_provider.dart';
import 'package:finora_app/screens/home.dart';

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
        title: 'Home',
        icon: Icons.home,
        selectedIcon: Icons.home,
        screen: HomeScreen(username: widget.username, tipoUsuario: widget.rol),
      ),
      NavigationItem(
        title: 'Créditos',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        screen: SeguimientoScreenMobile(
          username: widget.username,
          tipoUsuario: widget.rol,
        ),
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
    ];
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
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentScreenTitle = _navigationItems[_selectedIndex].title;
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo o título principal
            Expanded(
              child: Text(
                currentScreenTitle,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleDarkMode(!themeProvider.isDarkMode);
            },
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                widget.username.isNotEmpty
                    ? widget.username[0].toUpperCase()
                    : 'U',
                style: TextStyle(color: Colors.white),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder:
                (BuildContext context) => [
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
      body: _navigationItems[_selectedIndex].screen,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      items:
          _navigationItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.selectedIcon),
                  label: item.title,
                ),
              )
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
