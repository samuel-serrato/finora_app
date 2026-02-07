// Imports de paquetes externos
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/providers/logo_provider.dart';
import 'package:finora_app/providers/ui_provider.dart';
import 'package:finora_app/services/navigation_service.dart';
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

import 'utils/app_logger.dart';

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

  final String initialRoute =
      isLoggedIn ? AppRoutes.navigation : AppRoutes.login;

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
        ChangeNotifierProvider(
          create: (_) => UiProvider(),
        ), // <--- AGREGAR ESTA LÍNEA
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
    // ¡LLAMADA CLAVE! Al iniciar la app, busca actualizaciones.
    _updateService.checkForUpdate();

    // El resto de tu lógica se mantiene.
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
    // 1. Eliminamos la comprobación de `mounted`, ya que la GlobalKey maneja eso por nosotros.
    //    Solo comprobamos si la actualización está realmente disponible.
    if (!_updateService.isUpdateAvailable.value) return;

    // 2. OBTENEMOS EL CONTEXTO SEGURO a través de la GlobalKey.
    final BuildContext? dialogContext = navigatorKey.currentContext;

    // 3. Verificamos que el contexto no sea nulo antes de continuar.
    if (dialogContext == null) {
      AppLogger.log(
        "No se pudo mostrar el diálogo de actualización: el contexto del navegador es nulo.",
      );
      return;
    }

    // A partir de aquí, el resto del código es casi idéntico al tuyo,
    // pero usamos el 'dialogContext' seguro que acabamos de obtener.

    // 4. Obtenemos los providers necesarios usando el contexto seguro.
    final themeProvider = Provider.of<ThemeProvider>(
      dialogContext,
      listen: false,
    );
    final colors =
        themeProvider
            .colors; // Suponiendo que `colors` es un getter en tu ThemeProvider

    showDialog<void>(
      // 5. Usamos el contexto seguro para mostrar el diálogo.
      context: dialogContext,
      barrierDismissible: false, // El usuario está obligado a interactuar.
      builder: (BuildContext builderContext) {
        // Renombramos el context del builder a 'builderContext' para evitar confusiones
        // Dentro del builder, es seguro usar el context que nos proporciona.
        return PopScope(
          canPop: false,
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
                    'Actualización Disponible',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
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
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                actions: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(
                        Icons.download_for_offline,
                        color: Colors.white,
                      ),
                      label: const Text('ACTUALIZAR AHORA'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.brandPrimary,
                        foregroundColor: Colors.white,
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
                        // Usamos el 'builderContext' para cerrar el diálogo.
                        Navigator.of(builderContext).pop();
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

  @override
  Widget build(BuildContext context) {
    // Obtenemos el provider del tema para configurar el ThemeData de la app.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      // 2. ASIGNA LA CLAVE AQUÍ
      navigatorKey: navigatorKey,
      // --- Configuración de Localización ---
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
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
        AppRoutes.gestionarUsuarios:
            (context) => const GestionarUsuariosScreen(),
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
    builder:
        (_) => Scaffold(
          body: Center(child: Text('Error de navegación: Ruta no encontrada')),
        ),
  );
}
