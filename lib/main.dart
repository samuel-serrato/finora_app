import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'providers/pagos_provider.dart';
import 'screens/login.dart';
import 'constants/routes.dart';
import 'navigation.dart'; // Renombrado de navigation_rail a navigation para ser más genérico

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la configuración de fechas en español
  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagosProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.navigation) {
          if (settings.arguments is! Map<String, dynamic>) {
            return _errorRoute();
          }
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => NavigationScreen(
              username: args['username'] ?? 'Usuario',
              rol: args['rol'] ?? 'sin_rol',
              userId: args['userId'] ?? '',
              userType: args['userType'] ?? 'standard',
            ),
          );
        }
        return _errorRoute();
      },
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
    );
  }
}

// Ruta de error genérica
Route<dynamic> _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      body: Center(
        child: Text('Error de navegación'),
      ),
    ),
  );
}