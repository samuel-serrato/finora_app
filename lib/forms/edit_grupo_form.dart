// Archivo: lib/forms/edit_grupo_form.dart
import 'dart:async';

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/grupo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';


class EditarGrupoForm extends StatefulWidget {
  final String idGrupo;
  final VoidCallback? onGrupoEditado;

  const EditarGrupoForm({
    super.key,
    required this.idGrupo,
    this.onGrupoEditado,
  });

  @override
  _EditarGrupoFormState createState() => _EditarGrupoFormState();
}

class _EditarGrupoFormState extends State<EditarGrupoForm>
    with SingleTickerProviderStateMixin {
  // --- Controladores y Keys ---
  final _infoGrupoFormKey = GlobalKey<FormState>();
  final _miembrosGrupoFormKey = GlobalKey<FormState>();
  late TabController _tabController;
  final TextEditingController nombreGrupoController = TextEditingController();
  final TextEditingController detallesController = TextEditingController();
  final TextEditingController searchClientController = TextEditingController();

  // --- Variables de Estado ---
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentIndex = 0;

  // --- Datos del Grupo ---
  Grupo? _grupoActual;
  String? selectedTipoGrupo;
  Usuario? _selectedAsesor;
  List<Usuario> _listaAsesores = [];

  // --- Datos de Miembros ---
  final List<Map<String, dynamic>> _miembrosSeleccionados = [];
  final Map<String, String> _cargosSeleccionados = {};
  final Map<String, String> _cargosOriginales = {};
  Set<String> _miembrosOriginalesIds = {};
  final List<String> _miembrosEliminadosIds = [];

  // --- Listas de Opciones ---
  final List<String> tiposGrupo = [
    'Grupal',
    'Individual',
    'Automotriz',
    'Empresarial',
  ];
  final List<String> cargos = ['Miembro', 'Presidente/a', 'Tesorero/a'];

  // --- Servicios ---
  final GrupoService _grupoService = GrupoService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
      () => setState(() => _currentIndex = _tabController.index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    nombreGrupoController.dispose();
    detallesController.dispose();
    searchClientController.dispose();
    super.dispose();
  }

  // ========================================================================
  // LÓGICA DE CARGA Y GUARDADO DE DATOS (YA CORREGIDA Y FUNCIONAL)
  // ========================================================================

  // ========================================================================
  // LÓGICA DE CARGA Y GUARDADO DE DATOS
  // ========================================================================

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);

    final responses = await Future.wait([
      _grupoService.getGrupo(widget.idGrupo),
      _grupoService.getAsesores(),
    ]);

    if (!mounted) return;

    final grupoResponse = responses[0] as ApiResponse<Grupo>;
    final asesoresResponse = responses[1] as ApiResponse<List<Usuario>>;

    if (!grupoResponse.success) {
      _apiService.showErrorDialog(
        grupoResponse.error ?? "No se pudieron cargar los datos del grupo.",
      );
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!asesoresResponse.success) {
      _apiService.showErrorDialog(
        asesoresResponse.error ?? "No se pudieron cargar los asesores.",
      );
    }

    _grupoActual = grupoResponse.data!;
    _listaAsesores = asesoresResponse.data ?? [];

    _poblarFormularioConDatos();
    setState(() => _isLoading = false);
  }

  void _poblarFormularioConDatos() {
    if (_grupoActual == null) return;

    final grupo = _grupoActual!;
    nombreGrupoController.text = grupo.nombreGrupo;
    detallesController.text = grupo.detalles;
    selectedTipoGrupo = grupo.tipoGrupo;

    _miembrosSeleccionados.clear();
    _cargosSeleccionados.clear();
    _cargosOriginales.clear();

    for (var resumen in grupo.clientes) {
      final miembroMap = {
        'idclientes': resumen.idclientes,
        'nombres': resumen.nombres,
        'telefono': resumen.telefono,
        'estado': 'En Grupo',
      };
      _miembrosSeleccionados.add(miembroMap);
      _cargosSeleccionados[resumen.idclientes] = resumen.cargo ?? 'Miembro';
      _cargosOriginales[resumen.idclientes] = resumen.cargo ?? 'Miembro';
    }
    _miembrosOriginalesIds = grupo.clientes.map((c) => c.idclientes).toSet();
    _inicializarAsesor();
  }

  void _inicializarAsesor() {
    // Esta función ahora solo se encarga de encontrar y seleccionar el asesor en el dropdown.
    if (_grupoActual?.idusuario == null || _listaAsesores.isEmpty) {
      _selectedAsesor = null;
      return;
    }

    // Es mucho más fiable buscar por ID directamente.
    final idAsesorDelGrupo = _grupoActual!.idusuario;
    Usuario? asesorEncontrado;

    try {
      asesorEncontrado = _listaAsesores.firstWhere(
        (usuario) => usuario.idusuarios == idAsesorDelGrupo,
      );
    } catch (e) {
      asesorEncontrado = null;
    }

    if (asesorEncontrado == null) {
      print(
        "Asesor con ID '$idAsesorDelGrupo' no encontrado en la lista. Se establecerá como nulo.",
      );
      _selectedAsesor = null;
    } else {
      _selectedAsesor = asesorEncontrado;
    }
  }

  // Tu pantalla de edición en la app móvil

  Future<void> _guardarCambios() async {
    // 1. Validación inicial (igual que antes)
    if (_miembrosSeleccionados.isEmpty) {
      _apiService.showErrorDialog("No se puede guardar un grupo sin miembros.");
      return;
    }
    /* if (!(_infoGrupoFormKey.currentState?.validate() ?? false)) {
      _apiService.showErrorDialog(
        "Revisa la información del grupo, hay campos incompletos.",
      );
      return;
    } */

    setState(() => _isSaving = true);

    try {
      // 2. Construir el CUERPO COMPLETO de la petición.
      // Este objeto representa el estado FINAL y DESEADO del grupo.
      // El backend se encargará de reconciliar los cambios.
      final Map<String, dynamic> datosCompletos = {
        // Información básica del grupo
        "nombreGrupo": nombreGrupoController.text,
        "detalles": detallesController.text,
        "tipoGrupo": selectedTipoGrupo,
        // El ID del asesor seleccionado
        "idusuarios": _selectedAsesor?.idusuarios,
        // La LISTA FINAL de miembros con sus cargos actualizados
        "clientes":
            _miembrosSeleccionados.map((miembro) {
              final idCliente = miembro['idclientes'];
              return {
                "idclientes": idCliente,
                "nomCargo": _cargosSeleccionados[idCliente] ?? 'Miembro',
              };
            }).toList(),
      };

      // 3. Realizar UNA ÚNICA llamada a la API
      // Usamos el nuevo método que creamos en el servicio.
      final response = await _grupoService.actualizarGrupoCompleto(
        widget.idGrupo,
        datosCompletos,
      );

      // 4. Manejar la respuesta (mucho más simple ahora)
      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGrupoEditado?.call();
        Navigator.pop(context);
      }
      // No necesitamos un 'else', porque el ApiService ya se encarga
      // de mostrar el diálogo de error en caso de fallo.
    } catch (e) {
      // Este catch es para errores inesperados de programación
      AppLogger.log("Error crítico al guardar cambios: $e");
      _apiService.showErrorDialog(
        "Ocurrió un error inesperado al intentar guardar: $e",
      );
    } finally {
      // Asegurarnos de que el estado de guardado se desactive
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ========================================================================
  // CONSTRUCCIÓN DE LA UI (WIDGETS) - ESTILO nGrupoForm
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // 1. Reemplazamos Scaffold por Card
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      color: colors.backgroundPrimary,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // 2. Añadimos el encabezado del diálogo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                          'Editar Grupo', // Título del diálogo
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Tus widgets originales se mantienen
                  // (Usando el estilo que tenías en EditarGrupoForm)
                  Container(
                    margin: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      0,
                    ), // Ajustamos margen
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Usamos el radio estándar
                      border: Border.all(
                        color: colors.divider,
                      ), // Añadimos borde para consistencia
                    ),
                    child: SizedBox(
                      height: 48, // Altura estándar
                      child: TabBar(
                        padding: const EdgeInsets.all(4), // Padding estándar
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: colors.brandPrimary,
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Radio estándar
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: colors.whiteWhite,
                        unselectedLabelColor:
                            colors.textSecondary, // Consistencia
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, // Consistencia
                          fontSize: 12, // Consistencia
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: 'Información'),
                          Tab(text: 'Miembros'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [_paginaInfoGrupo(), _paginaMiembros()],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
    );
  }

  // --- Widgets de páginas ---

  Widget _paginaInfoGrupo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _infoGrupoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Datos del Grupo'),
            _buildTextField(
              controller: nombreGrupoController,
              label: 'Nombre del Grupo',
              icon: Icons.group_work,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              value: selectedTipoGrupo,
              hint: 'Tipo de Grupo',
              items: tiposGrupo,
              onChanged: (v) => setState(() => selectedTipoGrupo = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildAsesorDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: detallesController,
              label: 'Detalles',
              icon: Icons.notes,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginaMiembros() {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _miembrosGrupoFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              _sectionTitle('Buscar y Agregar Clientes'),
              TypeAheadField<Map<String, dynamic>>(
                controller: searchClientController,
                decorationBuilder:
                    (context, child) => Material(
                      color: colors.backgroundCard,
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                builder:
                    (context, controller, focusNode) => _buildTextField(
                      controller: controller,
                      label: 'Buscar cliente...',
                      icon: Icons.search,
                      focusNode: focusNode,
                    ),
                suggestionsCallback: (pattern) async {
                  if (pattern.trim().length < 2) return [];
                  final response = await _grupoService.buscarClientes(pattern);
                  return response.data ?? [];
                },
                itemBuilder: (context, suggestion) {
                  final estado = suggestion['estado'] as String?;
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${suggestion['nombres']} ${suggestion['apellidoP']}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(estado),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusTextColor(estado),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            estado ?? 'N/A',
                            style: TextStyle(
                              color: _getStatusTextColor(estado),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Tel: ${suggestion['telefono']}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                },
                onSelected: (suggestion) {
                  searchClientController.clear();
                  final idCliente = suggestion['idclientes'].toString();
                  if (!_miembrosSeleccionados.any(
                    (c) => c['idclientes'] == idCliente,
                  )) {
                    setState(() {
                      _miembrosSeleccionados.add(suggestion);
                      _cargosSeleccionados[idCliente] = 'Miembro';
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Este cliente ya está en el grupo.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                loadingBuilder:
                    (context) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                emptyBuilder:
                    (context) => ListTile(
                      title: Text(
                        'No se encontraron clientes.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                errorBuilder:
                    (context, error) => ListTile(
                      title: Text(
                        'Error al buscar clientes',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Miembros Seleccionados'),
              Expanded(
                child:
                    _miembrosSeleccionados.isEmpty
                        ? Center(
                          child: Text(
                            "Aún no hay miembros en el grupo.",
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        )
                        : ListView.builder(
                          itemCount: _miembrosSeleccionados.length,
                          // ... dentro de tu ListView.builder
                          itemBuilder: (context, index) {
                            final miembro = _miembrosSeleccionados[index];
                            final idMiembro = miembro['idclientes'];
                            final estado = miembro['estado'] as String?;

                            // ===========> AÑADE ESTA LÍNEA AQUÍ <===========
                            AppLogger.log('DEBUG MIEMBRO[$index]: $miembro');
                            // ===============================================

                            return Card(
                              color: colors.backgroundCard,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.brandPrimary,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.brandPrimary
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: colors.whiteWhite,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              // Variable para almacenar el nombre completo
                                              String nombreCompleto;

                                              // CONDICIÓN: Verificamos si tenemos los apellidos por separado.
                                              // Usamos 'miembro.containsKey' para más seguridad.
                                              if (miembro.containsKey(
                                                    'apellidoP',
                                                  ) &&
                                                  miembro['apellidoP'] !=
                                                      null) {
                                                // Caso 1: Miembro NUEVO (con apellidos separados)
                                                final nombre =
                                                    miembro['nombres'] ?? '';
                                                final apellidoP =
                                                    miembro['apellidoP'] ?? '';
                                                final apellidoM =
                                                    miembro['apellidoM'] ??
                                                    ''; // ?? '' maneja si es nulo
                                                nombreCompleto =
                                                    '$nombre $apellidoP $apellidoM'
                                                        .trim();
                                              } else {
                                                // Caso 2: Miembro VIEJO (nombre completo en un campo)
                                                nombreCompleto =
                                                    miembro['nombres'] ??
                                                    'Nombre no disponible';
                                              }

                                              // Devolvemos el Text widget con el nombre ya formateado
                                              return Text(
                                                nombreCompleto.replaceAll(
                                                  RegExp(r'\s+'),
                                                  ' ',
                                                ), // Opcional: limpia espacios dobles
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                //overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _buildRoleSelector(
                                                idMiembro,
                                                colors,
                                              ),
                                              if (estado != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      estado,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    estado,
                                                    style: TextStyle(
                                                      color:
                                                          _getStatusTextColor(
                                                            estado,
                                                          ),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red[400],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_miembrosOriginalesIds.contains(
                                              idMiembro,
                                            )) {
                                              _miembrosEliminadosIds.add(
                                                idMiembro,
                                              );
                                            }
                                            _miembrosSeleccionados.removeAt(
                                              index,
                                            );
                                            _cargosSeleccionados.remove(
                                              idMiembro,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de UI Reutilizados ---

  Widget _buildNavigationButtons() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              if (_currentIndex > 0) {
                _tabController.animateTo(_currentIndex - 1);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _currentIndex == 0 ? 'Cancelar' : 'Atrás',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed:
                _isSaving
                    ? null
                    : () {
                      FocusScope.of(context).unfocus();
                      if (_currentIndex < 1) {
                        if (_infoGrupoFormKey.currentState?.validate() ??
                            false) {
                          _tabController.animateTo(_currentIndex + 1);
                        } else {
                          _apiService.showErrorDialog(
                            "Por favor, complete todos los campos requeridos en esta sección.",
                          );
                        }
                      } else {
                        _guardarCambios();
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.backgroundButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      _currentIndex == 1 ? 'Guardar Cambios' : 'Siguiente',
                    ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: colors.brandPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.textSecondary),
          prefixIcon: Icon(icon, color: colors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
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
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        dropdownColor: colors.backgroundCard,
      ),
    );
  }

  Widget _buildAsesorDropdown() {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<Usuario>(
        value: _selectedAsesor,
        hint: Text(
          "Seleccionar Asesor",
          style: TextStyle(color: colors.textSecondary),
        ),
        items:
            _listaAsesores
                .map(
                  (asesor) => DropdownMenuItem(
                    value: asesor,
                    child: Text(
                      asesor.nombreCompleto,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                )
                .toList(),
        onChanged: (v) => setState(() => _selectedAsesor = v),
        validator: (v) => v == null ? 'Requerido' : null,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person_pin, color: colors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        dropdownColor: colors.backgroundCard,
      ),
    );
  }

  Widget _buildRoleSelector(String idCliente, dynamic colors) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      color: colors.backgroundCard,
      onSelected:
          (nuevoRol) =>
              setState(() => _cargosSeleccionados[idCliente] = nuevoRol),
      itemBuilder:
          (context) =>
              cargos
                  .map(
                    (rol) => PopupMenuItem(
                      value: rol,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_cargosSeleccionados[idCliente] == rol)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: colors.brandPrimary,
                            )
                          else
                            const SizedBox(width: 14),
                          const SizedBox(width: 6),
                          Text(
                            rol,
                            style: TextStyle(
                              color:
                                  _cargosSeleccionados[idCliente] == rol
                                      ? colors.brandPrimary
                                      : colors.textPrimary,
                              fontWeight:
                                  _cargosSeleccionados[idCliente] == rol
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.brandPrimary.withOpacity(0.05),
          border: Border.all(
            color: colors.brandPrimary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _cargosSeleccionados[idCliente] ?? 'Seleccionar',
              style: TextStyle(
                color: colors.brandPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colors.brandPrimary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // --- Funciones de color para estado (Píldoras) ---

  Color _getStatusColor(String? estado) {
    switch (estado) {
      case 'En Credito':
        return const Color(0xFFA31D1D).withOpacity(0.1);
      case 'En Grupo':
        return const Color(0xFF3674B5).withOpacity(0.1);
      case 'Disponible':
        return const Color(0xFF059212).withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(String? estado) {
    switch (estado) {
      case 'En Credito':
        return const Color(0xFFA31D1D);
      case 'En Grupo':
        return const Color(0xFF3674B5);
      case 'Disponible':
        return const Color(0xFF059212);
      default:
        return Colors.grey;
    }
  }
}
