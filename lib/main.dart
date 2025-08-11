// Imports de paquetes externos
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Imports de tu propio proyecto
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/pagos_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/screens/login.dart';
import 'package:finora_app/responsive_navigation_screen.dart';
import 'package:finora_app/screens/screens_config/acerca_de_screen.dart';
import 'package:finora_app/screens/screens_config/configuracion_screen.dart';
import 'package:finora_app/screens/screens_config/gestionar_usuarios_screen.dart';
import 'package:finora_app/constants/routes.dart';

// 1. La función `main` ahora es `async` para permitir operaciones asíncronas antes de iniciar la app.
void main() async {
  // 2. Es obligatorio llamar a `ensureInitialized` cuando `main` es `async`.
  //    Prepara el motor de Flutter para ejecutar código antes de `runApp`.
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Creamos una instancia del UserDataProvider ANTES de construir la UI.
  final userDataProvider = UserDataProvider();
  
  // 4. Invocamos el método para cargar la sesión desde el almacenamiento persistente.
  //    `isLoggedIn` contendrá `true` si se encontró una sesión válida, y `false` en caso contrario.
  final bool isLoggedIn = await userDataProvider.loadUserDataFromStorage();

  // 5. Basado en si hay una sesión activa, decidimos cuál será la primera pantalla que verá el usuario.
  final String initialRoute = isLoggedIn ? AppRoutes.navigation : AppRoutes.login;

  // 6. Inicializamos la localización de fechas para español. Esto está correcto.
  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';

  // 7. Lanzamos la aplicación con `runApp`.
  runApp(
    // `MultiProvider` es el lugar ideal para definir todos los providers globales de la app.
    MultiProvider(
      providers: [
        // Provider para el estado temporal de los pagos. Se crea de cero cada vez.
        ChangeNotifierProvider(create: (_) => PagosProvider()),

        // Provider para el tema. Su propio constructor se encargará de cargar la preferencia.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ¡IMPORTANTE! Usamos `ChangeNotifierProvider.value` para el UserDataProvider.
        // Esto es porque ya tenemos una instancia (`userDataProvider`) en la que hemos
        // cargado datos. `.value` reutiliza esa instancia en lugar de crear una nueva.
        ChangeNotifierProvider.value(value: userDataProvider),
      ],
      // Pasamos la ruta inicial que determinamos a nuestro widget principal `MyApp`.
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

// 8. El widget `MyApp` se modifica para aceptar la ruta inicial como parámetro.
class MyApp extends StatelessWidget {
  final String initialRoute; // Propiedad para almacenar la ruta inicial.

  // El constructor ahora requiere que se le pase el `initialRoute`.
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider del tema para configurar el ThemeData de la app.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // --- Configuración de Localización ---
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US')
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // --- Configuración de Navegación ---
      // 9. Aquí se utiliza la variable `initialRoute` para definir la pantalla de inicio.
      initialRoute: initialRoute,
      routes: {
        // Mapeo de todas las rutas con nombre de la aplicación.
        AppRoutes.login: (context) => LoginScreen(),
        AppRoutes.navigation: (context) => const ResponsiveNavigationScreen(),
        AppRoutes.gestionarUsuarios: (context) => const GestionarUsuariosScreen(),
        AppRoutes.configuracion: (context) => const ConfiguracionScreen(),
        AppRoutes.acercaDe: (context) => const AcercaDeScreen(),
      },
      // `onGenerateRoute` se usa como un fallback si se intenta navegar a una ruta no definida.
      onGenerateRoute: (settings) {
        return _errorRoute();
      },
      
      // --- Configuración Visual ---
      debugShowCheckedModeBanner: false,
      // El tema de la aplicación (claro u oscuro) se controla dinámicamente desde el ThemeProvider.
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
    );
  }
}

// Función helper para mostrar una pantalla de error en caso de una ruta desconocida.
Route<dynamic> _errorRoute() {
  return MaterialPageRoute(
    builder: (_) => Scaffold(
      body: Center(
        child: Text('Error de navegación: Ruta no encontrada'),
      ),
    ),
  );
}