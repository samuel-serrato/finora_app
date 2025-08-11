// lib/forms/cambiar_password_form.dart

import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class CambiarPasswordForm extends StatefulWidget {
  final String idUsuario;

  const CambiarPasswordForm({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _CambiarPasswordFormState createState() => _CambiarPasswordFormState();
}

class _CambiarPasswordFormState extends State<CambiarPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nuevaPasswordController = TextEditingController();
  final TextEditingController _confirmarPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNuevaPassword = true;
  bool _obscureConfirmarPassword = true;

  final UsuarioService _usuarioService = UsuarioService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
    });
  }

  @override
  void dispose() {
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Llama a un nuevo método en UsuarioService (que debemos crear)
    final response = await _usuarioService.cambiarPassword(
      idUsuario: widget.idUsuario,
      nuevaPassword: _nuevaPasswordController.text,
    );
    
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success) {
      Navigator.of(context).pop(); // Cierra el modal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } 
    // Si falla, ApiService se encarga del diálogo de error
  }

   @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // Usamos Card como el widget raíz. Se adapta bien a Dialog y a BottomSheet.
    return Card(
      // El margin ahora es cero porque el padding del teclado se maneja en el lanzador.
      margin: EdgeInsets.zero,
      // Los bordes redondeados se verán bien en ambos casos.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      color: colors.backgroundPrimary,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Esencial para que se ajuste al contenido.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40, height: 4,
                  // El color de la barra de arrastre debe contrastar con el fondo.
                  decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                'Cambiar Contraseña',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                controller: _nuevaPasswordController,
                label: 'Nueva Contraseña',
                obscureText: _obscureNuevaPassword,
                onToggleVisibility: () => setState(() => _obscureNuevaPassword = !_obscureNuevaPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (value.length < 4) return 'Mínimo 4 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmarPasswordController,
                label: 'Confirmar Contraseña',
                obscureText: _obscureConfirmarPassword,
                onToggleVisibility: () => setState(() => _obscureConfirmarPassword = !_obscureConfirmarPassword),
                validator: (value) {
                  if (value != _nuevaPasswordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox.shrink() : Icon(Icons.lock_person_rounded, color: colors.whiteWhite,), // Cambiado el ícono
                label: _isLoading 
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: colors.whiteWhite)) 
                    : const Text('Guardar Contraseña'),
                onPressed: _isLoading ? null : _handleCambiarPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.brandPrimary,
                  foregroundColor: colors.whiteWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colors.backgroundCard,
      ),
      validator: validator,
    );
  }
}