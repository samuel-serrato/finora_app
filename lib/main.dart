// Imports de paquetes externos
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/providers/logo_provider.dart';
import 'package:finora_app/services/update_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  
  // ==================== INICIO DE CAMBIOS ====================

  // A. Creamos las instancias de los providers que necesitan carga previa.
  final userDataProvider = UserDataProvider();
  final themeProvider = ThemeProvider(); // Creamos la instancia aquí

  // B. Ejecutamos las operaciones asíncronas de inicialización y esperamos a que terminen.
  final bool isLoggedIn = await userDataProvider.loadUserDataFromStorage();
  await themeProvider.init(); // ¡Llamamos a nuestro nuevo método init!

  // ===================== FIN DE CAMBIOS ======================

  final String initialRoute = isLoggedIn ? AppRoutes.navigation : AppRoutes.login;

  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagosProvider()),

        // ¡IMPORTANTE! Usamos `.value` para los providers que ya hemos creado e inicializado.
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: userDataProvider),
        
        ChangeNotifierProvider(create: (_) => LogoProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

// 8. El widget `MyApp` se modifica para aceptar la ruta inicial como parámetro.
class MyApp extends StatefulWidget {
  final String initialRoute; // Propiedad para almacenar la ruta inicial.

  // El constructor ahora requiere que se le pase el `initialRoute`.
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // 1. Declaramos e inicializamos nuestro servicio de actualización aquí.
  final UpdateService _updateService = UpdateService();


    @override
  void initState() {
    super.initState();
    _updateService.isUpdateAvailable.addListener(_showUpdateDialogIfNeeded);
  }

  @override
  void dispose() {
    _updateService.isUpdateAvailable.removeListener(_showUpdateDialogIfNeeded);
    _updateService.dispose();
    super.dispose();
  }

    final AppColors colors = AppColors();


    void _showUpdateDialogIfNeeded() {
    // La comprobación inicial sigue siendo la misma.
    if (mounted && _updateService.isUpdateAvailable.value) {
      // Obtenemos los providers necesarios.
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final colors = themeProvider.colors;

      showDialog<void>(
        context: context,
        barrierDismissible: false, // El usuario está obligado a interactuar.
        builder: (BuildContext dialogContext) {
          // *** CAMBIO IMPORTANTE: Usamos PopScope en lugar de WillPopScope ***
          // Evita que el diálogo se cierre con el botón de "atrás" del sistema.
          return PopScope(
            canPop: false, // Esto es el equivalente moderno de onWillPop: () async => false
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: AlertDialog(
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  backgroundColor: colors.backgroundPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  iconPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  icon: Icon(
                    Icons.cloud_download_outlined,
                    color: colors.brandPrimary,
                    size: 48,
                  ),
                  title: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Actualización Disponible', // He simplificado el salto de línea
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary, // Asegúrate de usar el color del tema
                      ),
                    ),
                  ),
                  content: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Se ha encontrado una nueva versión de Finora con mejoras y nuevas funciones. \n\nPor favor, actualiza para continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: colors.textPrimary, // Asegúrate de usar el color del tema
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  actions: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.download_for_offline, color: Colors.white), // Color del icono
                        label: const Text('ACTUALIZAR AHORA'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.brandPrimary,
                          foregroundColor: Colors.white, // Color del texto
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // 1. Cierra el diálogo para dar feedback visual inmediato.
                          Navigator.of(dialogContext).pop();
                          // 2. Llama al servicio para que aplique la actualización.
                          // La página se recargará por completo.
                          _updateService.activateNewVersion();
                        },
                      ),
                    ),
                  ],
                  titlePadding: const EdgeInsets.only(top: 16),
                  contentPadding: const EdgeInsets.only(
                    top: 16,
                    left: 24,
                    right: 24,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  
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
      initialRoute: widget.initialRoute,
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