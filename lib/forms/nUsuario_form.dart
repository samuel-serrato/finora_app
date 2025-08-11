// lib/forms/nUsuario_form.dart

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class nUsuarioForm extends StatefulWidget {
  final VoidCallback onUsuarioAgregado;

  const nUsuarioForm({Key? key, required this.onUsuarioAgregado}) : super(key: key);

  @override
  _nUsuarioFormState createState() => _nUsuarioFormState();
}

class _nUsuarioFormState extends State<nUsuarioForm> {
  // --- Controladores y Clave del Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // --- Variables de Estado ---
  String? _selectedTipoUsuario;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // --- Listas de Opciones ---
  final List<String> _tiposUsuario = ['Admin', 'Contador', 'Asistente', 'Campo', 'Invitado'];

  // --- Instancias de Servicios ---
  final UsuarioService _usuarioService = UsuarioService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Es crucial establecer el contexto para que ApiService pueda mostrar diálogos
        _apiService.setContext(context);
      }
    });
  }

  @override
  void dispose() {
    // Limpia los controladores para liberar memoria
    _usuarioController.dispose();
    _nombreCompletoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Método principal para manejar la creación del usuario
  Future<void> _handleAgregarUsuario() async {
    // Oculta el teclado si está abierto
    FocusScope.of(context).unfocus();

    // Valida el formulario
    if (!_formKey.currentState!.validate()) {
      _apiService.showErrorDialog(
        "Por favor, corrige los errores en el formulario.",
        title: "Campos Inválidos",
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Obtiene datos del provider, como el nombre del negocio y el ID
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    
    // Construye el nombre de usuario completo
    final usuarioCompleto = '${_usuarioController.text}.${userData.nombreNegocio.toLowerCase().replaceAll(' ', '')}';

    // Prepara el payload para la API
    final Map<String, dynamic> payload = {
      'usuario': usuarioCompleto,
      'tipoUsuario': _selectedTipoUsuario,
      'nombreCompleto': _nombreCompletoController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'idnegocio': userData.idnegocio,
    };

    // Llama al servicio para crear el usuario
    final response = await _usuarioService.crearUsuario(payload);

    // Si el widget ya no está en el árbol, no continuamos
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success) {
      // Si la operación fue exitosa, llama al callback para refrescar la lista
      // y cierra el formulario.
      widget.onUsuarioAgregado();
      Navigator.of(context).pop();
    } 
    // Si falla, ApiService se encarga de mostrar el diálogo de error.
  }

   @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final userData = Provider.of<UserDataProvider>(context, listen: false);

    // 1. Reemplazamos Scaffold por Card
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      color: colors.backgroundPrimary,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column( // El widget principal ahora es una Columna
              children: [
                // 2. Añadimos el encabezado del diálogo
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Agregar Usuario', // Título
                       style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22
                      ),
                      ),
                    ],
                  ),
                ),
                
                // 3. El contenido del formulario va dentro de un Expanded para que sea scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tu contenido original del formulario va aquí...
                          _sectionTitle('Información de Acceso', colors),
                          const SizedBox(height: 16),
                          _buildUsuarioField(userData, colors),
                          const SizedBox(height: 16),
                          _buildPasswordField(colors),
                          const SizedBox(height: 24),
                          _sectionTitle('Datos Personales', colors),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _nombreCompletoController,
                            label: 'Nombre Completo',
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Correo Electrónico (Opcional)',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                return 'Formato de correo inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            value: _selectedTipoUsuario,
                            hint: 'Tipo de Usuario',
                            items: _tiposUsuario,
                            onChanged: (v) => setState(() => _selectedTipoUsuario = v),
                            validator: (v) => v == null ? 'Seleccione un tipo de usuario' : null,
                          ),
                          const SizedBox(height: 20), // Espacio al final del scroll
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 4. Movemos el botón de guardar aquí, fuera del scroll
                if (!_isLoading) _buildSaveButton(colors),
              ],
            ),
    );
  }

  // --- Widgets de UI Reutilizables ---

  Widget _sectionTitle(String title, AppColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: colors.brandPrimary,
      ),
    );
  }

  Widget _buildUsuarioField(UserDataProvider userData, AppColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildTextField(
            controller: _usuarioController,
            label: 'Nombre de Usuario',
            icon: Icons.person_outline,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
          ),
        ),
        const SizedBox(width: 8),
        // Muestra el sufijo del negocio
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Text(
            '.${userData.nombreNegocio.toLowerCase().replaceAll(' ', '')}',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(Icons.lock_outline, color: colors.textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: colors.textSecondary,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'La contraseña es requerida';
          if (v.length < 4) return 'Mínimo 4 caracteres';
          return null;
        },
        style: TextStyle(color: colors.textPrimary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(icon, color: colors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(color: colors.textPrimary),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(color: colors.textPrimary)))).toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.category_outlined, color: colors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: colors.backgroundCard,
      ),
    );
  }

  Widget _buildSaveButton(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, -1))],
      ),
      child: ElevatedButton.icon(
        icon: Icon(Icons.save_alt_rounded, color: colors.iconButton),
        label: const Text('Guardar Usuario'),
        onPressed: _handleAgregarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}