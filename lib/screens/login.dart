import 'dart:async'; // Necesario para el Timer del Slider
import 'dart:convert';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/image_data.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:flutter/gestures.dart'; // Necesario para TapGestureRecognizer en el footer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesario para el link del footer

import '../providers/theme_provider.dart';
import '../constants/routes.dart';
import '../../utils/app_logger.dart';


// Definimos un punto de quiebre para decidir cuándo mostrar el layout de desktop.
const double kDesktopBreakpoint = 800.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Variables y Controladores (del código mobile original) ---
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  // --- Datos para el Slider (del código desktop) ---
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Control Financiero\nen un Solo Lugar',
      'color': const Color(0xFF5162F6),
    },
    {
      'title': 'Crea Grupos Personalizados\nde Créditos',
      'color': const Color(0xFF009688),
    },
    {
      'title': 'Historial Completo\nde Transacciones',
      'color': const Color(0xFF9C27B0),
    },
    {
      'title': 'Reportes Detallados\ny en Tiempo Real',
      'color': const Color(0xFF3F51B5),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
    });
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('rememberedUser');
    if (savedUser != null) {
      setState(() {
        _usernameController.text = savedUser;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Lógica de Login (sin cambios, del código mobile) ---
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        usuario: _usernameController.text,
        password: _passwordController.text,
      );

      if (response.success && response.data != null) {
        final userData = response.data!;
        final usuario = userData['usuario'][0];

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('rememberedUser', _usernameController.text);
        } else {
          await prefs.remove('rememberedUser');
        }

        List<ImageData> imagenes =
            (usuario['imagenes'] as List)
                .map((imgJson) => ImageData.fromJson(imgJson))
                .toList();

        final userDataProvider = Provider.of<UserDataProvider>(
          context,
          listen: false,
        );

        userDataProvider.saveUserDataOnLogin(
          nombreNegocio: usuario['nombreNegocio'],
          imagenes: imagenes,
          nombreUsuario: usuario['nombreCompleto'],
          tipoUsuario: usuario['tipoUsuario'],
          idnegocio: usuario['idnegocio'].toString(),
          idusuario: usuario['idusuarios'].toString(),
          redondeo: (usuario['redondeo'] as num).toDouble(),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.navigation, // Usando constante de rutas
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Bienvenido ${usuario['nombreCompleto']}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error de login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- MÉTODO build PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            // El gradiente de fondo se mantiene para ambos layouts
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors:
                    isDarkMode
                        ? [const Color(0xFF1A1A2E), const Color(0xFF121212)]
                        : [const Color(0xFFF0EFFF), Colors.white],
              ),
            ),
            // Usamos LayoutBuilder para decidir qué layout mostrar
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Si el ancho es mayor que nuestro punto de quiebre, mostramos el layout de desktop
                if (constraints.maxWidth > kDesktopBreakpoint) {
                  return _buildDesktopLayout(isDarkMode);
                } else {
                  // De lo contrario, mostramos el layout de mobile
                  return _buildMobileLayout(isDarkMode);
                }
              },
            ),
          ),
          // El indicador de carga se mantiene fuera del layout para cubrir toda la pantalla
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5162F6)),
                  strokeWidth: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS DE LAYOUT ---

  /// Construye el layout para pantallas anchas (Desktop)
    /// Construye el layout para pantallas anchas (Desktop)
  Widget _buildDesktopLayout(bool isDarkMode) {
    return Row(
      children: [
        // Parte izquierda: El Slider (sin cambios)
        Expanded(
          flex: 2,
          child: SliderWidget(slides: _slides),
        ),
        // Parte derecha: El formulario y el footer (MODIFICADA)
        Expanded(
          flex: 3,
          // Reemplazamos el Stack/Positioned con una Column para un control más claro del espacio.
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            child: Column(
              children: [
                // 1. Expanded toma todo el espacio vertical disponible, empujando el footer hacia abajo.
                Expanded(
                  // 2. Center posiciona el contenido principal en el medio de ese espacio.
                  child: Center(
                    // 3. SingleChildScrollView permite el scroll si el contenido es muy alto.
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildLoginForm(isDarkMode, isDesktop: true),
                      ),
                    ),
                  ),
                ),
                // 4. Como Expanded está arriba, estos widgets son empujados al fondo.
                const SizedBox(height: 0),
                _buildFooter(isDarkMode),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el layout para pantallas estrechas (Mobile)
    /// Construye el layout para pantallas estrechas (Mobile)
  Widget _buildMobileLayout(bool isDarkMode) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        // 1. La Column es el widget principal. Su altura está limitada por el SafeArea (la pantalla).
        //    Ahora SÍ tiene una altura finita.
        child: Column(
          children: [
            // 2. Expanded toma todo el espacio vertical disponible, empujando el footer hacia abajo.
            Expanded(
              // 3. LayoutBuilder nos da las restricciones de altura finitas que Expanded calculó.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 4. Ahora el SingleChildScrollView se coloca DENTRO del espacio con altura definida.
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      // 5. Forzamos al contenido del scroll a tener, como mínimo, la altura del viewport.
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      // 6. Esta Column interna ahora puede usar mainAxisAlignment para centrar el formulario
                      //    porque su altura es, al menos, la del viewport.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLoginForm(isDarkMode, isDesktop: false),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 7. El footer queda fuera del Expanded, por lo que se posiciona en la parte inferior.
            const SizedBox(height: 20),
            _buildFooter(isDarkMode),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES ---

  /// Formulario de login, adaptable para desktop o mobile
  Widget _buildLoginForm(bool isDarkMode, {required bool isDesktop}) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El logo cambia dependiendo de si es desktop o mobile
        Image.asset(
          isDesktop
              ? (isDarkMode ? 'assets/finora_blanco.png' : 'assets/finora.png')
              : (isDarkMode ? 'assets/finora_blanco.png' : 'assets/finora.png'),
          height: isDesktop ? 100 : 80,
          fit: BoxFit.contain,
        ),
        SizedBox(height: isDesktop ? 50 : 20),
        _buildTextField(
          label: 'Usuario',
          icon: Icons.person_outline,
          controller: _usernameController,
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: isDesktop ? 30 : 24),
        _buildTextField(
          label: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
          onFieldSubmitted: (v) => _handleLogin(),
          textInputAction: TextInputAction.go,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Checkbox "Recuérdame"
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (bool? value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF5162F6),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Text(
                    "Recuérdame",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            // Botón de cambio de tema
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDarkMode ? Colors.yellow.shade700 : Color(0xFF5162F6),
              ),
              onPressed: () => themeProvider.toggleTheme(!isDarkMode),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 40 : 20),
        // Botón de Ingresar
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5162F6),
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isDesktop ? 15 : 12),
            ),
            elevation: 5,
          ),
          onPressed: _handleLogin,
          child: const Text(
            'Ingresar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// Footer con información de versión y copyright (del código desktop)
  Widget _buildFooter(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Asumimos que getLocalVersion() existe en tu proyecto.
        // Si no, puedes reemplazarlo por un texto fijo o quitar el FutureBuilder.
        FutureBuilder<String>(
          future: Future.value("1.0.0"), // Placeholder para la versión
          builder: (context, snapshot) {
            String finoraText = 'Finora';
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              finoraText = 'Finora v${snapshot.data}';
            }
            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$finoraText  |  Desarrollado por ',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'CODX',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      //decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _launchURL,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          '© ${DateTime.now().year} Todos los derechos reservados.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
  required String label,
  required IconData icon,
  required TextEditingController controller,
  required bool isDarkMode,
  bool isPassword = false,
  // ESTA LÍNEA ES LA QUE CAMBIA:
  void Function(String)? onFieldSubmitted,
  TextInputAction? textInputAction,
}) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
        // Se pasa directamente el parámetro recibido
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF5162F6), width: 2),
          ),
          hintText: 'Ingrese su ${label.toLowerCase()}',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            fontSize: 15,
          ),
        ),
      ),
    ],
  );
}

  /// Función para abrir URL (del código desktop)
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://codxtech.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      AppLogger.log('No se pudo abrir el enlace: $url');
    }
  }
}

// --- WIDGET DEL SLIDER (Copiado directamente del código de desktop) ---

class SliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> slides;
  const SliderWidget({super.key, required this.slides});

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    });
  }

  void _goToPage(int index) {
    _timer?.cancel();
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        )
        .then((_) => _startAutoSlide());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: widget.slides.length,
                itemBuilder: (context, index) {
                  final slide = widget.slides[index];
                  return Container(
                    color: slide['color'],
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 20,
                child: Row(
                  children: List.generate(
                    widget.slides.length,
                    (index) => MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _goToPage(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 25 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
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
}
