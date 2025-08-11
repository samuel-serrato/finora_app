// lib/forms/editUsuario_form.dart

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/forms/cambiar_password_form.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class editUsuarioForm extends StatefulWidget {
  final String idUsuario;
  final VoidCallback onUsuarioEditado;

  const editUsuarioForm({
    Key? key,
    required this.idUsuario,
    required this.onUsuarioEditado,
  }) : super(key: key);

  @override
  _editUsuarioFormState createState() => _editUsuarioFormState();
}

class _editUsuarioFormState extends State<editUsuarioForm> {
  // --- Controladores y Clave del Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // --- Variables de Estado ---
  String? _selectedTipoUsuario;
  bool _isLoading = true; // Empieza en true para mostrar carga mientras se obtienen datos
  bool _isSaving = false; // Estado para el proceso de guardado

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
        _apiService.setContext(context);
        _fetchUsuarioData(); // Carga los datos del usuario al iniciar
      }
    });
  }

  @override
  void dispose() {
    // Limpia los controladores para liberar memoria
    _usuarioController.dispose();
    _nombreCompletoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Carga los datos iniciales del usuario desde la API.
  // lib/forms/editUsuario_form.dart

// ... dentro de la clase _editUsuarioFormState

  Future<void> _fetchUsuarioData() async {
    setState(() => _isLoading = true);

    final response = await _usuarioService.getUsuarioPorId(widget.idUsuario);

    if (mounted) {
      if (response.success && response.data != null) {
        final usuario = response.data!;
        
        String nombreUsuarioSinSufijo = usuario.usuario;
        if (nombreUsuarioSinSufijo.contains('.')) {
          nombreUsuarioSinSufijo = nombreUsuarioSinSufijo.split('.').first;
        }

        _usuarioController.text = nombreUsuarioSinSufijo;
        _nombreCompletoController.text = usuario.nombreCompleto;
        
        // ======================= CAMBIO 1 =======================
        // Si el email viene vacío o nulo, mostramos 'No asignado'.
        // De lo contrario, mostramos el email real.
        _emailController.text = (usuario.email == null || usuario.email.isEmpty)
            ? 'No asignado'
            : usuario.email;
        // ===================== FIN DEL CAMBIO 1 =====================

        setState(() {
          _selectedTipoUsuario = usuario.tipoUsuario;
        });

      } else {
        Navigator.of(context).pop();
      }
      setState(() => _isLoading = false);
    }
  }
  
  /// Método principal para manejar la actualización del usuario
  
  Future<void> _handleEditarUsuario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _apiService.showErrorDialog(
        "Por favor, corrige los errores en el formulario.",
        title: "Campos Inválidos",
      );
      return;
    }

    setState(() => _isSaving = true);
    
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final usuarioCompleto = '${_usuarioController.text}.${userData.nombreNegocio.toLowerCase().replaceAll(' ', '')}';

    // ======================= CAMBIO 3 =======================
    // Prepara el valor del email para el guardado.
    // Si el valor en el controlador es 'No asignado', lo convertimos a un string vacío.
    final String emailParaGuardar = 
        (_emailController.text.trim() == 'No asignado')
        ? ''
        : _emailController.text;
    // ===================== FIN DEL CAMBIO 3 =====================

    final Map<String, dynamic> payload = {
      'usuario': usuarioCompleto,
      'tipoUsuario': _selectedTipoUsuario,
      'nombreCompleto': _nombreCompletoController.text,
      'email': emailParaGuardar, // Usamos la variable procesada
    };

    final response = await _usuarioService.actualizarUsuario(widget.idUsuario, payload);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (response.success) {
      if (widget.idUsuario == userData.idusuario) {
        userData.actualizarDatosUsuario(
          nombreCompleto: _nombreCompletoController.text,
          tipoUsuario: _selectedTipoUsuario,
        );
      }
      widget.onUsuarioEditado();
      Navigator.of(context).pop();
    }
  }

   // =========================================================================
  // ======================= NUEVO MÉTODO AÑADIDO ============================
  // =========================================================================
   void _mostrarDialogoCambiarPassword() {
    // Definimos un punto de quiebre para decidir qué diálogo mostrar.
    const double desktopBreakpoint = 768.0;
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < desktopBreakpoint) {
      // --- LÓGICA MÓVIL: Usamos el BottomSheet ---
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // El color lo dará el formulario
        builder: (context) {
          // El formulario ya está diseñado para un BottomSheet, así que solo lo llamamos.
          // Le pasamos el padding para el teclado aquí.
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: CambiarPasswordForm(idUsuario: widget.idUsuario),
          );
        },
      );
    } else {
      // --- LÓGICA DESKTOP: Usamos un Dialog centrado ---
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            // El Dialog ya provee el fondo y la sombra.
            backgroundColor: Colors.transparent, // Hacemos transparente para que el Card de adentro tome el control
            elevation: 0,
            child: ConstrainedBox(
              // Limitamos el ancho para que no sea demasiado grande en pantallas anchas.
              constraints: const BoxConstraints(maxWidth: 420),
              child: CambiarPasswordForm(idUsuario: widget.idUsuario),
            ),
          );
        },
      );
    }
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
        : Stack( // Mantenemos el Stack para el overlay de guardado
          children: [
            Column( // El layout principal sigue siendo una Columna
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
                        'Editar Usuario', // Título
                        style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22
                      ),
                      ),
                    ],
                  ),
                ),

                // 3. El contenido del formulario va en un Expanded para ser scrollable
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
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            icon: Icon(Icons.lock_reset, color: colors.blackWhite),
                            label: const Text('Cambiar Contraseña'),
                            onPressed: _mostrarDialogoCambiarPassword,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: colors.backgroundCard,
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.brandPrimary.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
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
                              final value = v?.trim() ?? '';
                              if (value.isEmpty || value == 'No asignado') return null;
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Formato de correo inválido';
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
                          const SizedBox(height: 20), // Espacio al final
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Movemos el botón de guardar aquí
                if (!_isLoading) _buildSaveButton(colors),
              ],
            ),

            // El overlay de "guardando" se queda en el Stack para cubrir todo
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
  );
}

  // --- Widgets de UI Reutilizables (Idénticos al formulario de agregar) ---
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
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Text(
            '.${userData.nombreNegocio.toLowerCase().replaceAll(' ', '')}',
            style: TextStyle(fontSize: 14, color: colors.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    
    // Asegurarse de que el valor seleccionado esté en la lista
    final String? validValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 1))],
      ),
      child: DropdownButtonFormField<String>(
        value: validValue,
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
        icon: Icon(Icons.save_alt_rounded, color: colors.iconButton,),
        label: const Text('Guardar Cambios'),
        onPressed: _isSaving ? null : _handleEditarUsuario,
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