import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart'; // Asegúrate de que este import sea necesario o puedes quitarlo
import 'package:finora_app/ip.dart';
import 'package:finora_app/main.dart'; // Asumo que aquí está
import 'package:finora_app/models/cuenta_bancaria.dart';
import 'package:finora_app/providers/logo_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/screens/screens_config/configracion_credito.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/utils/formatters.dart';
import 'package:finora_app/widgets/cambiar_contrase%C3%B1a.dart';
import 'package:flutter/material.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../utils/app_logger.dart';

// El widget ahora es un StatefulWidget que representa una pantalla completa.
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({Key? key}) : super(key: key);

  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  // --- TODA LA LÓGICA Y VARIABLES DE ESTADO SE MANTIENEN IGUAL ---
  bool notificationsEnabled = true;
  bool dataSync = true;
  String selectedLanguage = 'Español';

  // Variables para el manejo de imágenes

  // Variables para el manejo de imágenes
  Uint8List? _tempColorLogoBytes; // Para la vista previa del logo a color
  String? _colorLogoFileName; // Nombre del archivo para la subida
  String? _colorLogoImagePath;

  Uint8List? _tempWhiteLogoBytes; // Para la vista previa del logo blanco
  String? _whiteLogoFileName; // Nombre del archivo para la subida
  String? _whiteLogoImagePath;

  bool _isUploading = false;
  bool _isSaving = false;
  double? _roundingThreshold;

  // Variables para cuentas bancarias
  List<CuentaBancaria> _cuentasBancarias = [];
  bool _loadingCuentas = false;

  // Estado para controlar la vista del submenú
  bool _showCreditSettings = false;

  // --- AÑADE ESTAS DOS LÍNEAS ---
  String? _diaCorteSeleccionado;
  bool _isLoadingDiaCorte = true;
  // --------------------------------

    // --- AÑADE ESTA LÍNEA ---
  String? _initialDiaCorte; 
  // ------------------------

  @override
  void initState() {
    super.initState();

    _loadSavedLogos();
    _fetchCuentasBancarias();
    _fetchDiaCorte();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = Provider.of<UserDataProvider>(context, listen: false);
      setState(() {
        _roundingThreshold = userData.redondeo ?? 0.5;
      });
    });
  }

  // Cargar los logos guardados previamente
  Future<void> _loadSavedLogos() async {
    final logoProvider = Provider.of<LogoProvider>(context, listen: false);
    setState(() {
      _colorLogoImagePath = logoProvider.colorLogoPath;
      _whiteLogoImagePath = logoProvider.whiteLogoPath;
    });

    //_loadSavedLogos();
    //_fetchCuentasBancarias();
  }

  // --- EL MÉTODO BUILD AHORA UTILIZA SCAFFOLD ---
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colors = themeProvider.colors;

    
  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    // --- REEMPLAZA TU APPBAR CON ESTE ---
    appBar: AppBar(
      backgroundColor: colors.backgroundPrimary,
      elevation: 1.0,
      scrolledUnderElevation: 1.0,
      title: Text(
        _showCreditSettings ? 'Configuración de Crédito' : 'Configuración',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Botón de "atrás" que siempre estará visible y controlará la salida.
     leading: IconButton(
  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
  onPressed: () {
    if (_showCreditSettings) {
      setState(() {
        _showCreditSettings = false;
      });
    } else {
      final bool didChange = _diaCorteSeleccionado != _initialDiaCorte;
      
      // --- PRUEBA 1: AÑADE ESTA LÍNEA ---
      print('SALIENDO DE CONFIG. ¿Hubo cambios?: $didChange. Valor inicial: $_initialDiaCorte, Valor final: $_diaCorteSeleccionado');
      // ----------------------------------

      Navigator.pop(context, didChange);
    }
  },
),
    ),
      // El cuerpo de la pantalla usa el AnimatedSwitcher que ya tenías
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: Offset(
              child.key == const ValueKey('credit_settings') ? 1.0 : -1.0,
              0.0,
            ),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child:
            _showCreditSettings
                ? ConfiguracionCreditoScreen(
                  key: const ValueKey('credit_settings'),
                  initialRoundingValue: _roundingThreshold!,
                  onSave: (newValue) {
                    final userDataProvider = Provider.of<UserDataProvider>(
                      context,
                      listen: false,
                    );
                    userDataProvider.actualizarRedondeo(newValue);
                    setState(() {
                      _roundingThreshold = newValue;
                      _showCreditSettings =
                          false; // Regresa a la vista principal
                    });
                  },
                )
                : _buildMainSettings(key: const ValueKey('main_settings')),
      ),
    );
  }

  // --- TODOS LOS WIDGETS Y FUNCIONES AUXILIARES SE MANTIENEN ---
  // (No es necesario modificarlos, ya que la lógica es la misma)

  // Widget que contiene el menú principal de configuración
  Widget _buildMainSettings({Key? key}) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = Provider.of<UserDataProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return CustomScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildFinancialInfoBlock(context),
              const SizedBox(height: 24),
              _buildUserSection(context),
              const SizedBox(height: 24),
              // --- AQUÍ VA LA NUEVA SECCIÓN ---
              //_buildPlanInfoSection(context), // <--- ¡AÑADE ESTA LÍNEA!
              _buildPlanSection(context), // <--- ¡AÑADE ESTA LÍNEA!
              const SizedBox(height: 24),

              // ---------------------------------
              _buildSection(
                context,
                title: 'Apariencia',
                items: [
                  _buildConfigItem(
                    context,
                    title: 'Modo oscuro',
                    leadingIcon: Icons.dark_mode,
                    iconColor: Colors.purple,
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeColor: const Color(0xFF5162F6),
                      ),
                    ),
                  ),
                ],
              ),
              /*   const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Zoom',
                    items: [_buildZoomSlider(context, )],
                    isExpandable: true,
                  ), */
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Personalizar logo',
                items: [_buildLogoUploader(context)],
                isExpandable: true,
                enabled: userData.tipoUsuario == 'Admin',
              ),
              const SizedBox(height: 24),
              _buildBankAccountsSection(context),
              const SizedBox(height: 24),
              // --- AÑADE ESTAS DOS LÍNEAS AQUÍ ---
              _buildPreferenciasSection(context),
              const SizedBox(height: 24),
              // ------------------------------------
              _buildSection(
                context,
                title: 'Crédito',
                items: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: _buildConfigItem(
                      context,
                      title: 'Configuración de crédito',
                      leadingIcon: Icons.monetization_on,
                      iconColor: Colors.teal,
                      onTap: () {
                        setState(() {
                          _showCreditSettings = true;
                        });
                      },
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      enabled: userData.tipoUsuario == 'Admin',
                    ),
                  ),
                ],
                enabled: userData.tipoUsuario == 'Admin',
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // --- EL RESTO DE TUS FUNCIONES (SIN CAMBIOS) ---
  // Pega aquí todas las demás funciones de tu clase original:
  //
  // _buildConfigItem(...)
  // _buildLogoUploader(...)
  // _buildZoomSlider(...)
  // _adjustZoom(...)
  // _buildZoomButton(...)
  // _buildSection(...)
  // _getSectionIcon(...)
  // _getIconColor(...)
  // _buildDisabledMessage(...)
  // _buildFinancialInfoBlock(...)
  // _buildUserSection(...)
  // _pickAndUploadLogo(...)
  // _saveLogoChanges(...)
  // _uploadLogoToServer(...)
  // _cancelLogoChanges(...)
  // _fetchCuentasBancarias(...)
  // _showAddCuentaDialog(...)
  // _addCuentaBancaria(...)
  // _buildCuentaItem(...)
  // _buildBankAccountsSection(...)
  // _confirmDelete(...)
  // _deleteCuenta(...)
  // _showEditCuentaDialog(...)
  // _showCuentaDialog(...)
  // _editCuentaBancaria(...)
  //
  // (El código es muy extenso para pegarlo todo aquí de nuevo, pero
  // simplemente cópialas y pégalas a continuación. No necesitan cambios).

  Future<void> _fetchDiaCorte() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    setState(() {
      _isLoadingDiaCorte = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/configuracion/dia/corte'),
        headers: {'tokenauth': token},
      );

        if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _diaCorteSeleccionado = data['message'];
          // --- ¡AÑADE ESTA LÍNEA! ---
          _initialDiaCorte = data['message']; // Guardamos el valor inicial
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _diaCorteSeleccionado = 'lunes';
          // --- ¡AÑADE ESTA LÍNEA! ---
          _initialDiaCorte = 'lunes'; // También aquí
        });
      }
      AppLogger.log('Error al obtener día de corte: ${response.body}');
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _diaCorteSeleccionado = 'lunes';
        // --- ¡AÑADE ESTA LÍNEA! ---
        _initialDiaCorte = 'lunes'; // Y aquí
      });
    }
    AppLogger.log('Excepción al obtener día de corte: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDiaCorte = false;
        });
      }
    }
  }

  Future<void> _updateDiaCorte(String nuevoDia) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/configuracion/dia/corte'),
        headers: {'tokenauth': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'diaCorte': nuevoDia}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Día de corte actualizado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Si falla, revertimos al valor anterior para que la UI sea consistente
      _fetchDiaCorte();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el día de corte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPreferenciasSection(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    final List<String> dias = [
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    return _buildSection(
      context,
      title: 'Preferencias',
      isExpandable: true,
      enabled: userData.tipoUsuario == 'Admin',
      items: [
        _isLoadingDiaCorte
            ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
            : _buildConfigItem(
              context,
              title: 'Día de inicio de semana',
              leadingIcon: Icons.calendar_today_outlined,
              iconColor: Colors.blue,
              trailing: Container(
                // --- INICIO DE LOS CAMBIOS ---
                height:
                    38, // 1. AÑADE una altura fija para hacer el contenedor más bajo.
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ), // 2. QUITA el padding vertical.

                // --- FIN DE LOS CAMBIOS ---
                decoration: BoxDecoration(
                  color: colors.backgroundButton.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.backgroundButton,
                    width: 1.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _diaCorteSeleccionado,
                    dropdownColor: colors.backgroundCard,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colors.textPrimary,
                    ),
                    isDense: true, // <-- HACE MÁS COMPACTO EL BOTÓN CERRADO
                   
                    onChanged: (String? nuevoValor) {
                      if (nuevoValor != null) {
                        setState(() {
                          _diaCorteSeleccionado = nuevoValor;
                        });
                        _updateDiaCorte(nuevoValor);
                      }
                    },
                    items:
                        dias.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.capitalize(),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  //<editor-fold desc="Funciones Auxiliares (sin cambios)">
  Widget _buildConfigItem(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget?
    leadingWidget, // Para casos donde un IconData no es suficiente (ej. Imagen)
    Color? iconColor, // Color para el icono y su fondo
    Widget? trailing, // El widget que va al final (Switch, Button, etc.)
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    bool enabled = true,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Determinar el color del ícono por defecto si no se provee
    final effectiveIconColor = iconColor ?? Color(0xFF5162F6);

    Widget leadingContent;
    if (leadingWidget != null) {
      leadingContent = leadingWidget;
    } else if (leadingIcon != null) {
      leadingContent = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color:
              enabled
                  ? effectiveIconColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          leadingIcon,
          color: enabled ? effectiveIconColor : Colors.grey,
          size: 18,
        ),
      );
    } else {
      // Si no hay ícono ni widget líder, dejamos un espacio para mantener la alineación
      leadingContent = SizedBox(width: 14); // Ajusta este valor si es necesario
    }

    Widget titleWidget = Text(
      title,
      style:
          titleStyle ??
          TextStyle(
            color:
                enabled
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : Colors.grey,
            fontSize: 16,
            //fontWeight: FontWeight.w500, // Un poco más de peso para el título
          ),
    );

    Widget? subtitleWidget =
        subtitle != null
            ? Text(
              subtitle,
              style:
                  subtitleStyle ??
                  TextStyle(
                    color:
                        enabled
                            ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                            : Colors.grey[700],
                    fontSize: 14,
                  ),
            )
            : null;

    // Widget principal que contiene todo
    Widget itemContent = Row(
      children: [
        leadingContent,
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment
                    .center, // Centrar verticalmente si hay subtítulo
            children: [
              titleWidget,
              if (subtitleWidget != null) ...[
                SizedBox(height: 2), // Pequeño espacio entre título y subtítulo
                subtitleWidget,
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );

    // Envolver en IgnorePointer y Opacity si no está habilitado
    // Envolver en InkWell si hay onTap
    Widget finalWidget = Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: itemContent,
    );

    if (onTap != null) {
      finalWidget = InkWell(
        onTap: enabled ? onTap : null,
        child: finalWidget,
        borderRadius: BorderRadius.circular(
          8,
        ), // Para que el ripple effect coincida con el contenedor
      );
    }

    if (!enabled) {
      return IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: 0.5, // Atenuar visualmente
          child: finalWidget,
        ),
      );
    }

    return finalWidget;
  }

  // (Copia y reemplaza tu versión actual con esta)
  Widget _buildLogoUploader(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final userData = Provider.of<UserDataProvider>(context);
    bool isAdmin = userData.tipoUsuario == 'Admin';

    final colorLogo =
        userData.imagenes
            .where((img) => img.tipoImagen == 'logoColor')
            .firstOrNull;
    final whiteLogo =
        userData.imagenes
            .where((img) => img.tipoImagen == 'logoBlanco')
            .firstOrNull;

    // --- INICIO DE LA LÓGICA RESPONSIVA ---
    final screenWidth = MediaQuery.of(context).size.width;
    // Definimos un punto de quiebre. Si la pantalla es más ancha que 768px, usamos un Row.
    const double breakpoint = 768.0;

    // Creamos los dos widgets de subida para no repetirlos
    final colorLogoUploader = _buildSingleLogoUploader(
      context: context,
      title: "Logo a color (modo claro)",
      isDarkMode: isDarkMode,
      isAdmin: isAdmin,
      tempLogoBytes: _tempColorLogoBytes,
      savedLogo: colorLogo,
      logoType: "logoColor",
      backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
    );

    final whiteLogoUploader = _buildSingleLogoUploader(
      context: context,
      title: "Logo blanco (modo oscuro)",
      isDarkMode: isDarkMode,
      isAdmin: isAdmin,
      tempLogoBytes: _tempWhiteLogoBytes,
      savedLogo: whiteLogo,
      logoType: "logoBlanco",
      backgroundColor: Colors.grey[800]!,
    );

    // Widget que contendrá los uploaders, será un Row o un Column según el ancho
    Widget logoUploadersLayout;

    if (screenWidth > breakpoint) {
      // LAYOUT PARA DESKTOP (pantalla ancha)
      logoUploadersLayout = Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinea los elementos arriba
        children: [
          Expanded(
            child: colorLogoUploader,
          ), // Expanded para que compartan el espacio
          SizedBox(width: 24), // Separador horizontal
          Expanded(child: whiteLogoUploader),
        ],
      );
    } else {
      // LAYOUT PARA MÓVIL (pantalla estrecha)
      logoUploadersLayout = Column(
        children: [
          colorLogoUploader,
          SizedBox(height: 24), // Separador vertical
          whiteLogoUploader,
        ],
      );
    }
    // --- FIN DE LA LÓGICA RESPONSIVA ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),

        // Aquí usamos nuestro widget responsivo
        logoUploadersLayout,

        // El resto de tu código para botones y textos sigue igual
        if ((_tempColorLogoBytes != null || _tempWhiteLogoBytes != null) &&
            isAdmin) ...[
          Divider(height: 48), // Un poco más de espacio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                )
              else
                ElevatedButton.icon(
                  onPressed: _saveLogoChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.save, size: 16, color: Colors.white),
                  label: Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _cancelLogoChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.cancel, size: 16, color: Colors.white),
                label: Text('Cancelar', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
        SizedBox(height: 24),
        Center(
          child: Text(
            "Formatos permitidos: PNG",
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            "Estas imágenes se utilizarán como logos de la financiera en la aplicación según el modo de visualización",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  // Widget auxiliar para no repetir código en el uploader de logos
  // DESPUÉS (MÉTODO CORREGIDO)
  // Widget auxiliar para no repetir código en el uploader de logos
  // (Copia y reemplaza tu versión actual con esta)

  Widget _buildSingleLogoUploader({
    required BuildContext context,
    required String title,
    required bool isDarkMode,
    required bool isAdmin,
    required Uint8List? tempLogoBytes, // <-- Parámetro actualizado
    required dynamic savedLogo, // Puede ser null
    required String logoType,
    required Color backgroundColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF5162F6), width: 2),
          ),
          child:
              // --- INICIO DE LA LÓGICA DE VISUALIZACIÓN CORREGIDA ---
              tempLogoBytes != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(tempLogoBytes, fit: BoxFit.contain),
                  )
                  : savedLogo != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      '$baseUrl/imagenes/subidas/${savedLogo.rutaImagen}',
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                  : Icon(
                    Icons.add_photo_alternate,
                    size: 50,
                    color: Colors.grey[600],
                  ),
          // --- FIN DE LA LÓGICA DE VISUALIZACIÓN CORREGIDA ---
        ),
        SizedBox(height: 8),
        Text(
          tempLogoBytes !=
                  null // <-- Condición actualizada
              ? "Nuevo (no guardado)"
              : savedLogo != null
              ? "Logo guardado"
              : "Sin logo",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: isAdmin ? () => _pickAndUploadLogo(logoType) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5162F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.photo_camera, size: 16, color: Colors.white),
              label: Text(
                savedLogo != null ? 'Cambiar' : 'Subir',
                style: TextStyle(fontSize: 14),
              ),
            ),
            // --- INICIO DE LA LÓGICA DEL BOTÓN ELIMINAR CORREGIDA ---
            if (savedLogo != null && tempLogoBytes == null) ...[
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed:
                    isAdmin
                        ? () {
                          // TODO: Implementar la lógica para llamar a la API y eliminar el logo.
                          // Por ejemplo, podrías llamar a una función _deleteLogo(logoType)
                          AppLogger.log("Eliminar logo de tipo: $logoType");
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(Icons.delete, size: 16, color: Colors.white),
                label: Text('Eliminar', style: TextStyle(fontSize: 14)),
              ),
            ],
            // --- FIN DE LA LÓGICA DEL BOTÓN ELIMINAR CORREGIDA ---
          ],
        ),
      ],
    );
  }

  /* Widget _buildZoomSlider(BuildContext context,  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentScale = .scaleFactor;

    // Convertir factor de escala a porcentaje para mostrar
    final scalePercent = (currentScale * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.zoom_out,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Color(0xFF5162F6),
                  inactiveTrackColor:
                      isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  thumbColor: Color(0xFF5162F6),
                  overlayColor: Color(0xFF5162F6).withOpacity(0.2),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  value: currentScale,
                  min: 0.5,
                  max: 2.5,
                  divisions: 20,
                  onChanged: (value) {
                    s.setScaleFactor(value);
                  },
                ),
              ),
            ),
            Icon(Icons.zoom_in,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ],
        ),
        SizedBox(height: 8),
        // Mostrar porcentaje de zoom centrado
        Center(
          child: Text(
            "$scalePercent%",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoomButton(context, ,
                icon: Icons.remove,
                onPressed: () => _adjustZoom(, -0.1)),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => .setScaleFactor(1.0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5162F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Restablecer', style: TextStyle(fontSize: 12)),
            ),
            SizedBox(width: 8),
            _buildZoomButton(context, ,
                icon: Icons.add,
                onPressed: () => _adjustZoom(, 0.1)),
          ],
        ),
        // Espacio adicional debajo del botón "Restablecer"
        SizedBox(height: 16),
      ],
    );
  } */

  /* void _adjustZoom( , double amount) {
    double newScale = .scaleFactor + amount;
    // Mantener el zoom dentro de los límites
    if (newScale >= 0.5 && newScale <= 2.5) {
      .setScaleFactor(newScale);
    }
  }

  Widget _buildZoomButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF5162F6),
        foregroundColor: Colors.white,
        padding: EdgeInsets.all(8),
        minimumSize: Size(36, 36),
        maximumSize: Size(36, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
 */
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    bool isExpandable = false,
    bool enabled = true,
    EdgeInsetsGeometry? tilePadding,
    double? titleIconSize,
    double? titleIconContainerSize,
    TextStyle? sectionTitleTextStyle,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    final effectiveTilePadding =
        tilePadding ??
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0);
    final effectiveTitleIconSize = titleIconSize ?? 16.0;
    final effectiveTitleIconContainerSize = titleIconContainerSize ?? 28.0;
    final effectiveSectionTitleTextStyle =
        sectionTitleTextStyle ??
        TextStyle(color: colors.textPrimary, fontSize: 16);

    final ShapeBorder roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.divider, width: 1),
    );

    return Theme(
      // Modificamos este Theme para que haga todo el trabajo
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        // =========== INICIO DE LA SOLUCIÓN ===========
        splashColor: Colors.transparent, // Hace la "onda" transparente
        highlightColor: Colors.transparent, // Quita el sombreado al presionar
        // =========== FIN DE LA SOLUCIÓN ===========
      ),
      child:
          isExpandable
              ? IgnorePointer(
                ignoring: !enabled,
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.6,
                  child: ExpansionTile(
                    shape: roundedShape,
                    collapsedShape: roundedShape,
                    backgroundColor: colors.backgroundCard,
                    collapsedBackgroundColor: colors.backgroundCard,
                    onExpansionChanged: enabled ? (value) {} : null,
                    tilePadding: effectiveTilePadding,
                    title: Row(
                      children: [
                        Container(
                          width: effectiveTitleIconContainerSize,
                          height: effectiveTitleIconContainerSize,
                          decoration: BoxDecoration(
                            color: _getIconColor(title).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getSectionIcon(title),
                            color: _getIconColor(title),
                            size: effectiveTitleIconSize,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(title, style: effectiveSectionTitleTextStyle),
                      ],
                    ),
                    children: enabled ? items : [_buildDisabledMessage()],
                    trailing: Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color:
                          enabled
                              ? (isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600])
                              : Colors.grey,
                    ),
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  color: colors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items,
                  ),
                ),
              ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Mi Plan Actual':
        return Icons.workspace_premium_outlined;
      case 'Zoom':
        return Icons.zoom_in;
      case 'Cuentas bancarias':
        return Icons.account_balance; // Icono nuevo
      case 'Personalizar logo':
        return Icons.image;
      default:
        return Icons.settings;
    }
  }

  Color _getIconColor(String title) {
    switch (title) {
      case 'Mi Plan Actual':
        return Colors.amber;
      case 'Zoom':
        return Colors.blue;
      case 'Cuentas bancarias':
        return Colors.green; // Color nuevo
      case 'Personalizar logo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Nuevo método para mensaje de deshabilitado
  Widget _buildDisabledMessage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Se requieren permisos de administrador\npara modificar esta configuración',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFinancialInfoBlock(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Buscar el logo según el modo de tema
    final logo =
        userData.imagenes.where((img) {
          return isDarkMode
              ? img.tipoImagen == 'logoBlanco'
              : img.tipoImagen == 'logoColor';
        }).firstOrNull;

    final logoUrl =
        logo != null ? '$baseUrl/imagenes/subidas/${logo.rutaImagen}' : null;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider, width: 1),
      ),
      child: Row(
        children: [
          // Contenedor para la imagen del logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child:
                  logoUrl != null
                      ? Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Si falla la carga de la imagen, mostrar ícono
                          return Icon(
                            Icons.account_balance,
                            color: isDarkMode ? Colors.white : Colors.black,
                            size: 30,
                          );
                        },
                      )
                      : Icon(
                        Icons.account_balance,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 30,
                      ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData.nombreNegocio,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Financiera',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return _buildSection(
      context,
      title: 'Usuario',
      items: [
        _buildConfigItem(
          context,
          title: userData.nombreUsuario,
          subtitle: userData.tipoUsuario,
          leadingIcon: Icons.person,
          iconColor: Colors.green,
          trailing: ElevatedButton(
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (context) => CambiarPasswordDialog(
                        idUsuario: userData.idusuario,
                        isDarkMode: isDarkMode,
                      ),
                ),
            child: Text('Cambiar contraseña'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              backgroundColor: colors.backgroundButton,
              foregroundColor: colors.whiteWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DESPUÉS (CORREGIDO)
  Future<void> _pickAndUploadLogo(String tipoLogo) async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    if (userData.tipoUsuario == 'Admin') {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png'],
          withData: true, // ¡MUY IMPORTANTE! Esto carga los bytes del archivo
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;

          setState(() {
            if (tipoLogo == "logoColor") {
              _tempColorLogoBytes = file.bytes; // Guardamos los bytes
              _colorLogoFileName = file.name; // Guardamos el nombre
            } else {
              _tempWhiteLogoBytes = file.bytes; // Guardamos los bytes
              _whiteLogoFileName = file.name; // Guardamos el nombre
            }
          });
        }
      } catch (e) {
        AppLogger.log('Error al seleccionar el logo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar el archivo')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solo los administradores pueden subir logos')),
      );
    }
  }

  // Función para guardar los cambios pendientes (cuando hay imagenes temporales)
  // DESPUÉS (CORREGIDO)
  Future<void> _saveLogoChanges() async {
    try {
      setState(() => _isSaving = true);

      if (_tempColorLogoBytes != null && _colorLogoFileName != null) {
        await _uploadLogoToServer(
          _tempColorLogoBytes!,
          _colorLogoFileName!,
          "logoColor",
        );
      }

      if (_tempWhiteLogoBytes != null && _whiteLogoFileName != null) {
        await _uploadLogoToServer(
          _tempWhiteLogoBytes!,
          _whiteLogoFileName!,
          "logoBlanco",
        );
      }

      // Limpiar variables temporales
      setState(() {
        _tempColorLogoBytes = null;
        _colorLogoFileName = null;
        _tempWhiteLogoBytes = null;
        _whiteLogoFileName = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logo guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Función para subir un logo ya seleccionado
  // DESPUÉS (FUNCIÓN DE SUBIDA CORREGIDA)
  Future<void> _uploadLogoToServer(
    Uint8List fileBytes,
    String fileName,
    String tipoLogo,
  ) async {
    // Firma cambiada
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      if (token.isEmpty) {
        throw Exception(
          'Token de autenticación no encontrado. Por favor, inicia sesión.',
        );
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/imagenes/subir/logo'),
      );

      request.headers['tokenauth'] = token;

      // Adjuntar archivo DESDE BYTES, no desde una ruta
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          fileBytes, // Usamos los bytes
          filename: fileName, // Usamos el nombre del archivo
          contentType: MediaType('image', 'png'),
        ),
      );

      request.fields.addAll({
        'tipoImagen': tipoLogo,
        'idnegocio': userData.idnegocio,
      });

      // El resto de la función (enviar, recibir respuesta, etc.) es igual
      http.StreamedResponse response = await request.send().timeout(
        Duration(seconds: 30),
      );
      String responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        final nuevaRuta = jsonResponse['filename'];
        userData.actualizarLogo(tipoLogo, nuevaRuta);
      } else {
        throw Exception('Error HTTP ${response.statusCode}: $responseBody');
      }
    } on SocketException catch (e) {
      AppLogger.log('Error de red: $e');
      throw Exception('Verifica tu conexión a internet');
    } on TimeoutException {
      AppLogger.log('Tiempo de espera agotado');
      throw Exception('El servidor no respondió a tiempo');
    } catch (e) {
      AppLogger.log('Error inesperado: $e');
      rethrow;
    }
  }

  // (Copia y reemplaza tu versión actual con esta)

  // Función para cancelar los cambios
  void _cancelLogoChanges() {
    setState(() {
      // Limpia los bytes de la imagen a color y su nombre
      _tempColorLogoBytes = null;
      _colorLogoFileName = null;

      // Limpia los bytes de la imagen blanca y su nombre
      _tempWhiteLogoBytes = null;
      _whiteLogoFileName = null;
    });
  }

  Future<void> _fetchCuentasBancarias() async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    setState(() => _loadingCuentas = true);

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/v1/financiera/cuentasbanco/${userData.idnegocio}',
        ),
        headers: {'tokenauth': token},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cuentasBancarias =
            data.map((item) => CuentaBancaria.fromJson(item)).toList();
      }
    } catch (e) {
      AppLogger.log('Error fetching cuentas: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingCuentas = false);
      }
    }
  }

  void _showAddCuentaDialog() {
    // Redirige a la función genérica
    _showCuentaDialog(isEditing: false);
  }

  Future<void> _addCuentaBancaria(
    String nombre,
    String numero,
    String banco,
  ) async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    try {
      // Crear el cuerpo del request
      final requestBody = {
        'idnegocio': userData.idnegocio,
        'nombreCuenta': nombre,
        'numeroCuenta': numero,
        'nombreBanco': banco,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/financiera/cuentasbanco'),
        headers: {'tokenauth': token, 'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        _fetchCuentasBancarias();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error del servidor: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCuentaItem(BuildContext context, CuentaBancaria cuenta) {
    return ListTile(
      leading: Image.network(
        '$baseUrl/imagenes/bancos/${cuenta.rutaBanco}',
        width: 60,
        height: 35,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.account_balance, size: 35),
      ),
      title: Text(
        cuenta.nombreCuenta,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${cuenta.nombreBanco} - ${cuenta.numeroCuenta}'),
          Text(
            'Creada: ${DateFormat('dd/MM/yyyy').format(cuenta.fCreacion)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 20),
            onPressed: () => _showEditCuentaDialog(cuenta),
            tooltip: 'Editar cuenta',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade600, size: 20),
            onPressed: () => _confirmDelete(cuenta.numeroCuenta),
            tooltip: 'Eliminar cuenta',
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final userData = Provider.of<UserDataProvider>(context); // Obtener userData

    return _buildSection(
      context,
      title: 'Cuentas bancarias',
      items: [
        _loadingCuentas
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
            : _cuentasBancarias.isEmpty
            ? Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay cuentas registradas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
            : Column(
              children:
                  _cuentasBancarias
                      .map((cuenta) => _buildCuentaItem(context, cuenta))
                      .toList(),
            ),
        Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: ElevatedButton.icon(
              onPressed:
                  userData.tipoUsuario == 'Admin'
                      ? _showAddCuentaDialog
                      : null, // Deshabilitar si no es Admin
              icon: Icon(Icons.add, size: 20),
              label: Text('Agregar Nueva Cuenta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5162F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
      isExpandable: true,
      enabled: userData.tipoUsuario == 'Admin', // Solo habilitado para Admin
    );
  }

  void _confirmDelete(String numeroCuenta) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar esta cuenta bancaria?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                  _deleteCuenta(numeroCuenta); // Ejecuta la eliminación
                },
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteCuenta(String numeroCuenta) async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    try {
      final url =
          '$baseUrl/api/v1/financiera/cuentasbanco/${userData.idnegocio}/$numeroCuenta';

      final response = await http.delete(
        Uri.parse(url),
        headers: {'tokenauth': token},
      );

      if (response.statusCode == 200) {
        _fetchCuentasBancarias(); // Actualizar la lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditCuentaDialog(CuentaBancaria cuenta) {
    _showCuentaDialog(
      isEditing: true,
      cuentaOriginal: cuenta,
      nombre: cuenta.nombreCuenta,
      numero: cuenta.numeroCuenta,
      banco: cuenta.nombreBanco,
    );
  }

  void _showCuentaDialog({
    bool isEditing = false,
    CuentaBancaria? cuentaOriginal,
    String? nombre,
    String? numero,
    String? banco,
  }) {
    final TextEditingController nombreController = TextEditingController(
      text: nombre,
    );
    final TextEditingController numeroController = TextEditingController(
      text: numero,
    );
    String selectedBanco = banco ?? 'Santander';

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Icon(Icons.account_balance, color: Color(0xFF5162F6)),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  isEditing
                      ? 'Editar Cuenta Bancaria'
                      : 'Nueva Cuenta Bancaria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5162F6),
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la cuenta',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(Icons.label, color: Color(0xFF5162F6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF5162F6),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    fillColor: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
                    filled: true,
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: numeroController,
                  enabled: true,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Número de cuenta',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(Icons.numbers, color: Color(0xFF5162F6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF5162F6),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    fillColor: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
                SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor:
                          isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedBanco,
                      decoration: InputDecoration(
                        labelText: 'Selecciona un banco',
                        labelStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                        prefixIcon: Icon(
                          Icons.business,
                          color: Color(0xFF5162F6),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      dropdownColor:
                          isDarkMode ? Color(0xFF2D2D2D) : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      items:
                          [
                            "BBVA",
                            "Santander",
                            "Banorte",
                            "HSBC",
                            "Banamex",
                            "Scotiabank",
                            "Bancoppel",
                            "Banco Azteca",
                          ].map((String banco) {
                            return DropdownMenuItem<String>(
                              value: banco,
                              child: Text(
                                banco,
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) => selectedBanco = value!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isNotEmpty &&
                    numeroController.text.isNotEmpty) {
                  if (isEditing) {
                    await _editCuentaBancaria(
                      cuentaOriginal!.numeroCuenta,
                      nombreController.text,
                      numeroController.text,
                      selectedBanco,
                    );
                  } else {
                    await _addCuentaBancaria(
                      nombreController.text,
                      numeroController.text,
                      selectedBanco,
                    );
                  }
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5162F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(isEditing ? 'Actualizar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editCuentaBancaria(
    String numeroOriginal,
    String nombre,
    String numero,
    String banco,
  ) async {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenauth') ?? '';

    try {
      final requestBody = {
        'nombreCuenta': nombre,
        'cuentaNueva': numero,
        'nombreBanco': banco,
      };

      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/v1/financiera/cuentasbanco/${userData.idnegocio}/$numeroOriginal',
        ),
        headers: {'tokenauth': token, 'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        _fetchCuentasBancarias();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuenta actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPlanSection(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final licencia = userData.licenciaActiva;

    // Si no hay licencia, no mostramos nada.
    if (licencia == null) {
      return const SizedBox.shrink();
    }

    // Usamos el widget reutilizable _buildSection que ya tenías.
    return _buildSection(
      context,
      title: 'Mi Plan Actual',
      isExpandable: true,
      items: [_buildPlanDetailsContent(context)],
    );
  }

  // --- ¡NUEVO WIDGET! Para la barra de progreso lateral ---
  Widget _buildSideProgressBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final licencia =
        Provider.of<UserDataProvider>(context, listen: false).licenciaActiva!;

    // --- Lógica de cálculo (la misma de antes) ---
    final hoy = DateTime.now();
    final fechaInicio = licencia.fechaInicio;
    final fechaFin = licencia.fechaFin;

    final totalDaysInCycle = fechaFin.difference(fechaInicio).inDays;
    final elapsedDays = hoy.difference(fechaInicio).inDays;
    final double progress =
        totalDaysInCycle > 0
            ? (elapsedDays / totalDaysInCycle).clamp(0.0, 1.0)
            : 1.0;
    final remainingDays = fechaFin.difference(hoy).inDays;
    final remainingDaysText = _getRemainingDaysText(remainingDays);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start, // Alinea el contenido de la columna a la izquierda
      mainAxisSize:
          MainAxisSize
              .min, // Hace que la columna ocupe solo el espacio necesario
      children: [
        // Fila con el texto de los días restantes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ya no necesitamos la etiqueta "Progreso del ciclo", es más implícito
            Text(
              remainingDaysText,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // La barra de progreso visual
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: colors.divider.withOpacity(0.5),
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF5162F6)),
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  // --- NO OLVIDES MANTENER ESTE HELPER ---
  String _getRemainingDaysText(int days) {
    if (days < 0) {
      return 'Vencido';
    }
    switch (days) {
      case 0:
        return 'Vence hoy';
      case 1:
        return 'Queda 1 día';
      default:
        return 'Quedan $days días';
    }
  }

  // =======================================================================
  // ============ NUEVA VERSIÓN - SECCIÓN DE PLAN Y LICENCIA (v3) ============
  // =======================================================================

  // Pega esta función actualizada en tu _ConfiguracionScreenState

  // --- WIDGET PRINCIPAL COMPLETAMENTE REFACTORIZADO ---
  Widget _buildPlanDetailsContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final licencia = userData.licenciaActiva!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ).copyWith(top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECCIÓN SUPERIOR (SIN CAMBIOS) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Plan ${licencia.nombre}",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusBadge(
                licencia.estadoLicencia,
                themeProvider.isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- ¡CAMBIO AQUÍ! ---
          // Ahora usamos un Row para poner el precio al lado de la barra de progreso.
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .end, // Alinea la base del precio con la barra
            children: [
              // Lado izquierdo: El Precio (sin cambios en su contenido)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatCurrency(licencia.totalUnitario),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: _getBillingCycleText(licencia.duracionMesesPlan),
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24), // Espacio de separación
              // Lado derecho: La Barra de Progreso (envuelta en Expanded)
              Expanded(child: _buildSideProgressBar(context)),
            ],
          ),

          // Ya no necesitamos la llamada separada a la barra de progreso aquí.
          const SizedBox(height: 16),
          Divider(color: colors.divider),
          const SizedBox(height: 16),

          // --- El resto del widget continúa sin cambios ---
          LayoutBuilder(
            builder: (context, constraints) {
              const double desktopBreakpoint = 900.0;

              if (constraints.maxWidth > desktopBreakpoint) {
                return _buildDesktopCardsLayout(context);
              } else {
                return _buildMobileColumnLayout(context);
              }
            },
          ),

          /*  const SizedBox(height: 24),

        Center(
          child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.manage_accounts_outlined, size: 20),
              label: Text('Administrar Suscripción'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.backgroundButton,
                foregroundColor: colors.whiteWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ), */
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --- NUEVOS WIDGETS DE LAYOUT ---

  /// Construye la vista de 3 tarjetas horizontales para DESKTOP.
  /// Construye la vista de 3 tarjetas horizontales para DESKTOP.
  Widget _buildDesktopCardsLayout(BuildContext context) {
    return IntrinsicHeight(
      // Hace que todas las tarjetas en el Row tengan la misma altura
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: _buildInfoCard(
              context,
              title: 'Vigencia',
              icon: Icons.date_range_outlined,
              child: _buildDatesCardContent(context),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _buildInfoCard(
              context,
              title: 'Detalles de Pago',
              icon: Icons.payment_outlined,
              child: _buildPaymentCardContent(context),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: _buildInfoCard(
              context,
              title: 'Características Incluidas',
              icon: Icons.checklist_rtl_outlined,
              // --- ¡CAMBIO! Llamada actualizada sin el parámetro isDesktop ---
              child: _buildFeaturesCardContent(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la vista de columna única para MÓVIL.
  /// Construye la vista de columna única para MÓVIL.
  Widget _buildMobileColumnLayout(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatesCardContent(context),
        _buildPaymentCardContent(context),
        const SizedBox(height: 16),
        Divider(color: colors.divider),
        const SizedBox(height: 20), // Un poco más de espacio
        // --- ¡NUEVO! Título fijo para la sección de características en móvil ---
        Row(
          children: [
            Icon(
              Icons.checklist_rtl_outlined,
              color: colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Características Incluidas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // Espacio entre el título y la lista
        // --- La lista de características ahora se muestra directamente ---
        _buildFeaturesCardContent(context),
      ],
    );
  }

  // --- NUEVO WIDGET DE TARJETA REUTILIZABLE ---

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colors.divider),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: colors.divider.withOpacity(0.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // --- WIDGETS DE CONTENIDO PARA CADA TARJETA ---

  /// Contenido para la tarjeta de Fechas.
  Widget _buildDatesCardContent(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final licencia = userData.licenciaActiva!;

    return Column(
      children: [
        _buildInfoRow(
          context,
          icon: Icons.play_circle_outline,
          label: 'Fecha de inicio',
          value: Text(
            DateFormatters.formatearDateTime(
              licencia.fechaInicio,
              tipo: 'corta',
            ),
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        _buildInfoRow(
          context,
          icon: Icons.pause_circle_outline,
          label: 'Vigente hasta',
          value: Text(
            DateFormatters.formatearDateTime(licencia.fechaFin, tipo: 'corta'),
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        _buildInfoRow(
          context,
          icon: Icons.hourglass_bottom_outlined,
          label: 'Meses Contratados',
          value: Text(
            licencia.duracionMeses.toString(),
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Contenido para la tarjeta de Pagos.
  Widget _buildPaymentCardContent(BuildContext context) {
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final licencia = userData.licenciaActiva!;

    return Column(
      children: [
        _buildInfoRow(
          context,
          icon: Icons.credit_card_outlined,
          label: 'Pagado con',
          value: Text(
            licencia.metodoPago.capitalize(),
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        _buildInfoRow(
          context,
          icon: Icons.receipt_long_outlined,
          label: 'Pagado Total',
          value: Text(
            formatCurrency(licencia.precioTotal),
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        if (licencia.descuento > 0)
          _buildInfoRow(
            context,
            icon: Icons.sell_outlined,
            label: 'Descuento aplicado',
            value: Text(
              '${formatCurrency(licencia.descuento)}',
              style: TextStyle(
                color: Colors.green.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  /// Contenido para la tarjeta de Características (antes era tu ExpansionTile).
  /// Contenido para la tarjeta/sección de Características (AHORA ES UNA LISTA FIJA).
  Widget _buildFeaturesCardContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final licencia = userData.licenciaActiva!;

    // Simplemente devolvemos una columna con los items.
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start, // Asegura que el texto de "sin límites" se alinee a la izquierda
      children: [
        ...licencia.restricciones.map((restriccion) {
          return _buildFeatureItem(
            context,
            icon: _getIconForRestrictionType(restriccion.tipoARestringir),
            text: '${restriccion.nombre}',
          );
        }).toList(),

        // Condición para cuando no hay restricciones
        if (licencia.restricciones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
            ), // Un poco de espacio vertical
            child: Text(
              'Todas las características están incluidas sin límites.',
              style: TextStyle(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // --- Widgets y funciones auxiliares para la nueva sección (v3) ---

  // **¡NUEVO HELPER!** Más simple y flexible para las filas de información.
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          Spacer(),
          value, // El widget de valor se coloca directamente aquí
        ],
      ),
    );
  }

  // **¡NUEVA FUNCIÓN!** La que me proporcionaste.
  String _getBillingCycleText(int months) {
    if (months == 1) return '/ Mes';
    if (months > 1 && months < 12) return '/ $months Meses';
    if (months >= 12) {
      final years = months ~/ 12;
      return years == 1 ? '/ Año' : '/ $years Años';
    }
    return '/ Mes'; // Fallback
  }

  Widget _buildStatusBadge(String status, bool isDarkMode) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText = status;

    switch (status.toLowerCase()) {
      case 'activo':
        backgroundColor = Colors.green.shade600;
        break;
      case 'inactivo':
      case 'vencido':
        backgroundColor = Colors.red.shade600;
        break;
      default:
        backgroundColor = Colors.grey.shade500;
        statusText = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5162F6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.capitalize(),
              style: TextStyle(color: colors.textPrimary, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForRestrictionType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'creditos':
        return Icons.credit_score_outlined;
      case 'usuarios':
        return Icons.group_outlined;
      case 'documentos':
        return Icons.folder_zip_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}

// Extensión para capitalizar la primera letra de un String
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
