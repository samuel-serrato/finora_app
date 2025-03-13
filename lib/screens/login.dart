import 'dart:convert';
import 'package:finora_app/ip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../constants/routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    print('=== INICIANDO LOGIN ===');
    print('Usuario: ${_usernameController.text}');
    print('Contraseña: ${_passwordController.text}');

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      print('Error: Campos vacíos');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Realizando petición a: http://$baseUrl/api/v1/auth/login');
      final response = await http.post(
        Uri.parse('http://$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      print('Respuesta recibida - Código: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['code'] == 200) {
        final token = response.headers['tokenauth'];
        print('Token recibido: $token');

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tokenauth', token);
          print('Token almacenado en SharedPreferences');

          print('Navegando a HomeScreen');
          // En el método de login exitoso:
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.navigation,
            (route) => false,
            arguments: {
              'username': responseBody['usuario'][0]['nombreCompleto'],
              'rol':
                  responseBody['usuario'][0]['roles'].isNotEmpty
                      ? responseBody['usuario'][0]['roles'][0]
                      : 'sin_rol',
              'userId': responseBody['usuario'][0]['idusuarios'],
              'userType': responseBody['usuario'][0]['tipoUsuario'],
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                'Bienvenido ${responseBody['usuario'][0]['nombreCompleto']}',
              ),
            ),
          );
        } else {
          print('Error: Token no encontrado en headers');
          throw Exception('Token no encontrado en los headers');
        }
      } else {
        // Modificación aquí para extraer el mensaje correctamente
        final errorMessage =
            responseBody['Error']?['Message'] ??
            responseBody['message'] ??
            'Error desconocido';
        print('Error en respuesta del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Excepción capturada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== FIN DEL PROCESO DE LOGIN ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF0EFFF), Colors.white],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5162F6)),
                  strokeWidth: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset('assets/finora_hzt.png', height: 100, fit: BoxFit.contain),
        const SizedBox(height: 50),
        _buildTextField(
          label: 'Usuario',
          icon: Icons.person_outline,
          controller: _usernameController,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
          onFieldSubmitted: _handleLogin,
          textInputAction: TextInputAction.go,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5162F6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    VoidCallback? onFieldSubmitted,
    TextInputAction? textInputAction,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool obscurePassword = isPassword;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              obscureText: isPassword ? obscurePassword : false,
              style: TextStyle(color: Colors.grey[800]),
              onFieldSubmitted: (value) => onFieldSubmitted?.call(),
              textInputAction: textInputAction,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey[500]),
                suffixIcon:
                    isPassword
                        ? IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5162F6),
                    width: 2,
                  ),
                ),
                hintText: 'Ingrese su ${label.toLowerCase()}',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        );
      },
    );
  }
}
