// Archivo: lib/forms/renovar_grupo_form.dart
import 'dart:async';

import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/grupo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';


class RenovarGrupoForm extends StatefulWidget {
  final String idGrupo;
  final VoidCallback? onGrupoRenovado;

  const RenovarGrupoForm({
    super.key,
    required this.idGrupo,
    this.onGrupoRenovado,
  });

  @override
  _RenovarGrupoFormState createState() => _RenovarGrupoFormState();
}

class _RenovarGrupoFormState extends State<RenovarGrupoForm>
    with SingleTickerProviderStateMixin {
  // --- Controladores y Keys ---
  final _infoGrupoFormKey = GlobalKey<FormState>();
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

  // --- NUEVO: Estado para los descuentos de renovación ---
  Map<String, double> _descuentosRenovacion = {};

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
  // LÓGICA DE CARGA Y GUARDADO DE DATOS (Adaptada para Renovación)
  // ========================================================================

  Future<void> _cargarDatosIniciales() async {
    setState(() => _isLoading = true);

    // Hacemos todas las llamadas en paralelo para mayor eficiencia
    final responses = await Future.wait([
      _grupoService.getGrupo(widget.idGrupo),
      _grupoService.getAsesores(),
      _grupoService.getDescuentosRenovacion(
        widget.idGrupo,
      ), // <-- NUEVA LLAMADA
    ]);

    if (!mounted) return;

    final grupoResponse = responses[0] as ApiResponse<Grupo>;
    final asesoresResponse = responses[1] as ApiResponse<List<Usuario>>;
    final descuentosResponse =
        responses[2] as ApiResponse<Map<String, double>>; // <-- NUEVO

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

    // Guardamos los descuentos obtenidos
    if (descuentosResponse.success) {
      _descuentosRenovacion = descuentosResponse.data ?? {};
      AppLogger.log("Descuentos de renovación cargados: $_descuentosRenovacion");
    } else {
      print(
        "Aviso: No se pudieron cargar los descuentos de renovación. ${descuentosResponse.error}",
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

    for (var resumen in grupo.clientes) {
      _miembrosSeleccionados.add({
        'idclientes': resumen.idclientes,
        'nombres': resumen.nombres,
        'telefono': resumen.telefono,
        'estado': 'En Grupo', // Puedes adaptar el estado si lo tienes
      });
      _cargosSeleccionados[resumen.idclientes] = resumen.cargo ?? 'Miembro';
    }
    _inicializarAsesor();
  }

  void _inicializarAsesor() {
    if (_grupoActual?.idusuario == null || _listaAsesores.isEmpty) return;
    try {
      _selectedAsesor = _listaAsesores.firstWhere(
        (usuario) => usuario.idusuarios == _grupoActual!.idusuario,
      );
    } catch (e) {
      _selectedAsesor = null;
    }
  }

  // La función clave que llama al endpoint de renovación
  Future<void> _renovarGrupo() async {
    if (_miembrosSeleccionados.isEmpty) {
      _apiService.showErrorDialog("No se puede renovar un grupo sin miembros.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Construimos el cuerpo de la solicitud
      final Map<String, dynamic> datosRenovacion = {
        'idgrupos': widget.idGrupo, // ID del grupo a renovar
        'nombreGrupo': nombreGrupoController.text,
        'detalles': detallesController.text,
        'tipoGrupo': selectedTipoGrupo,
        'idusuarios': _selectedAsesor?.idusuarios,
        'clientes':
            _miembrosSeleccionados
                .map(
                  (persona) => {
                    'idclientes': persona['idclientes'],
                    'nomCargo':
                        _cargosSeleccionados[persona['idclientes']] ??
                        'Miembro',
                  },
                )
                .toList(),
      };

      // Llamamos al nuevo método en el servicio
      final response = await _grupoService.renovarGrupo(datosRenovacion);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo renovado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGrupoRenovado?.call();
        Navigator.pop(context);
      }
      // El ApiService ya maneja los errores, no necesitamos un 'else'.
    } catch (e) {
      AppLogger.log("Error crítico al renovar grupo: $e");
      _apiService.showErrorDialog(
        "Ocurrió un error inesperado al intentar renovar: $e",
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ========================================================================
  // CONSTRUCCIÓN DE LA UI (Widgets)
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

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
                        const Text(
                          'Renovar Grupo', // <-- TÍTULO CAMBIADO
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.divider),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: TabBar(
                        padding: const EdgeInsets.all(4),
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: colors.brandPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: colors.whiteWhite,
                        unselectedLabelColor: colors.textSecondary,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  String _formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }

  Widget _paginaInfoGrupo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Form(
        key: _infoGrupoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Datos del Grupo'),
            // --- CAMPO DESHABILITADO ---
            _buildTextField(
              controller: nombreGrupoController,
              label: 'Nombre del Grupo',
              icon: Icons.group_work,
              enabled: false, // <-- RESTRICCIÓN
            ),
            const SizedBox(height: 16),
            // --- CAMPO DESHABILITADO ---
            _buildDropdown(
              value: selectedTipoGrupo,
              hint: 'Tipo de Grupo',
              items: tiposGrupo,
              onChanged: (v) {}, // No hace nada
              enabled: false, // <-- RESTRICCIÓN
            ),
            const SizedBox(height: 16),
            _buildAsesorDropdown(), // Asesor sí se puede editar
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            _sectionTitle('Buscar y Agregar Clientes'),
            TypeAheadField<Map<String, dynamic>>(
              controller: searchClientController,
              //... (código del TypeAheadField idéntico a EditarGrupoForm)
              // --- INICIO CÓDIGO TYPEAHEAD (SIN CAMBIOS) ---
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
                      if (estado != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              color: _getStatusColor(estado),
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
              // --- FIN CÓDIGO TYPEAHEAD ---
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
                        itemBuilder: (context, index) {
                          final miembro = _miembrosSeleccionados[index];
                          final idMiembro = miembro['idclientes'];
                          final estado = miembro['estado'] as String?;

                          // --- LÓGICA DE ADEUDO ---
                          final tieneAdeudo = _descuentosRenovacion.containsKey(
                            idMiembro,
                          );
                          final montoAdeudo =
                              tieneAdeudo
                                  ? _descuentosRenovacion[idMiembro]
                                  : 0.0;

                          // Formateamos el nombre completo
                          String nombreCompleto =
                              (miembro['nombres'] ?? '') +
                              ' ' +
                              (miembro['apellidoP'] ?? '') +
                              ' ' +
                              (miembro['apellidoM'] ?? '');
                          nombreCompleto = nombreCompleto.trim().replaceAll(
                            RegExp(r'\s+'),
                            ' ',
                          );

                          return Card(
                            color: colors.backgroundCard,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: colors.divider),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // --- ÍCONO DE ADVERTENCIA ---
                                  if (tieneAdeudo)
                                    Tooltip(
                                      message:
                                          'Adeudo anterior: \$${_formatearNumero(montoAdeudo!)}',
                                      child: Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange.shade600,
                                        size: 22,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: colors.brandPrimary,
                                      size: 22,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombreCompleto,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
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
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    estado,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  estado,
                                                  style: TextStyle(
                                                    color: _getStatusColor(
                                                      estado,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
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
                                    margin: const EdgeInsets.only(left: 8),
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
                                      onPressed:
                                          () => setState(() {
                                            _miembrosSeleccionados.removeAt(
                                              index,
                                            );
                                            _cargosSeleccionados.remove(
                                              idMiembro,
                                            );
                                          }),
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
        color: colors.backgroundCard.withOpacity(0.95),
        border: Border(top: BorderSide(color: colors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                            "Complete los campos requeridos.",
                          );
                        }
                      } else {
                        _renovarGrupo(); // <-- Llama a la función de renovación
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.brandPrimary,
              foregroundColor: colors.whiteWhite,
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
                      _currentIndex == 1
                          ? 'Renovar Grupo'
                          : 'Siguiente', // <-- TEXTO CAMBIADO
                    ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    // ... (idéntico a EditarGrupoForm)
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  // --- WIDGET MODIFICADO PARA SOPORTAR ESTADO 'enabled' ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    bool enabled = true, // <-- NUEVO PARÁMETRO
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final isEnabled = enabled; // Para legibilidad

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Container(
        decoration: BoxDecoration(
          color:
              isEnabled
                  ? colors.backgroundCard
                  : colors.backgroundCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color:
                  isEnabled
                      ? colors.textSecondary
                      : colors.textSecondary.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              icon,
              color:
                  isEnabled
                      ? colors.textSecondary
                      : colors.textSecondary.withOpacity(0.7),
            ),
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
          style: TextStyle(
            color:
                isEnabled
                    ? colors.textPrimary
                    : colors.textPrimary.withOpacity(0.7),
          ),
          enabled: isEnabled, // Importante para el comportamiento nativo
        ),
      ),
    );
  }

  // --- WIDGET MODIFICADO PARA SOPORTAR ESTADO 'enabled' ---
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool enabled = true, // <-- NUEVO PARÁMETRO
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final isEnabled = enabled;

    return IgnorePointer(
      ignoring: !isEnabled,
      child: Container(
        decoration: BoxDecoration(
          color:
              isEnabled
                  ? colors.backgroundCard
                  : colors.backgroundCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
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
          onChanged: isEnabled ? onChanged : null, // Deshabilita el onChanged
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
      ),
    );
  }

  Widget _buildAsesorDropdown() {
    // ... (idéntico a EditarGrupoForm)
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
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
    // ... (idéntico a EditarGrupoForm)
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

  Color _getStatusColor(String? estado) {
    // ... (idéntico a EditarGrupoForm)
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
