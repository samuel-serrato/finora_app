import 'dart:convert';

import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';


class CambiarPasswordDialog extends StatefulWidget {
  final String idUsuario;
  final bool isDarkMode;

  const CambiarPasswordDialog({
    required this.idUsuario,
    required this.isDarkMode,
  });

  @override
  _CambiarPasswordDialogState createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<CambiarPasswordDialog> {
  final TextEditingController _nuevaPasswordController =
      TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Add password visibility state variables
  bool _obscureNuevaPassword = true;
  bool _obscureConfirmarPassword = true;

  Future<void> _cambiarPassword() async {
    AppLogger.log('flutter: Iniciando cambio de contraseña...');

    if (!_formKey.currentState!.validate()) {
      AppLogger.log('flutter: Validación de formulario fallida');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';
      AppLogger.log('flutter: Token obtenido: ${token.isNotEmpty ? "****" : "VACÍO"}');

      final url =
          '$baseUrl/api/v1/usuarios/recuperar/password/${widget.idUsuario}';
      AppLogger.log('flutter: URL de petición: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'tokenauth': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'password': _nuevaPasswordController.text,
        }),
      );

      AppLogger.log('flutter: Respuesta del servidor - Código: ${response.statusCode}');
      AppLogger.log('flutter: Body de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        AppLogger.log('flutter: Contraseña cambiada exitosamente');
        Navigator.of(context).pop();
        _mostrarMensajeExito();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['Error']['Message'] ?? 'Error al cambiar contraseña';
        AppLogger.log('flutter: Error del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.log('flutter: Excepción capturada: $e');
      print(
          'flutter: Stack trace: ${e is Error ? (e as Error).stackTrace : ""}');
      _mostrarError(e.toString());
    } finally {
      AppLogger.log('flutter: Finalizando proceso de cambio de contraseña');
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMensajeExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contraseña actualizada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: colors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          Icon(Icons.lock_reset,
              size: 40,
              color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
          SizedBox(height: 10),
          Text(
            'Cambiar Contraseña',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
          ),
          Divider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              height: 20),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nuevaPasswordController,
              obscureText: _obscureNuevaPassword,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: TextStyle(
                    color: colors.textPrimary,),
                prefixIcon: Icon(Icons.lock_outline,
                    color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
                // Add suffix icon for password visibility toggle
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(
                      size: 20,
                      _obscureNuevaPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNuevaPassword = !_obscureNuevaPassword;
                      });
                    },
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color:
                          isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6),
                      width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                fillColor: colors.backgroundCard,
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return '⚠️ Campo obligatorio';
                if (value.length < 4) return '⚠️ Mínimo 4 caracteres';
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _confirmarPasswordController,
              obscureText: _obscureConfirmarPassword,
              style: TextStyle(
                fontSize: 14,
                color:colors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                labelStyle: TextStyle(
                    color: colors.textPrimary),
                prefixIcon: Icon(Icons.lock_reset,
                    color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
                // Add suffix icon for password visibility toggle
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: Icon(
                      size: 20,
                      _obscureConfirmarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmarPassword = !_obscureConfirmarPassword;
                      });
                    },
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color:
                          isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6),
                      width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                fillColor: colors.backgroundCard,
                filled: true,
              ),
              validator: (value) {
                if (value != _nuevaPasswordController.text) {
                  return '⚠️ Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _cambiarPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Color(0xFF5162F6) : Color(0xFF5162F6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_rounded,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Guardar',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
