import 'dart:async';

import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
// ¡Importamos nuestro nuevo servicio!
import 'package:finora_app/services/grupo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';

class nGrupoForm extends StatefulWidget {
  final VoidCallback? onGrupoAgregado;

  const nGrupoForm({super.key, this.onGrupoAgregado});

  @override
  State<nGrupoForm> createState() => _nGrupoFormState();
}

class _nGrupoFormState extends State<nGrupoForm>
    with SingleTickerProviderStateMixin {
  //region Controladores y Variables de Estado
  final TextEditingController nombreGrupoController = TextEditingController();
  final TextEditingController detallesController = TextEditingController();
  final TextEditingController _typeAheadController = TextEditingController();

  String? selectedTipoGrupo;
  // --- CAMBIO 1: AJUSTE DE LA VARIABLE DE ESTADO ---
  // Ahora es de tipo Usuario? para mayor claridad y seguridad de tipos.
  Usuario? _selectedAsesor; // <-- CAMBIO
  bool esAdicional = false;

  final List<Map<String, dynamic>> _selectedMiembros = [];
  final Map<String, String> _rolesMiembros = {};
  final Map<String, double> _adeudosMiembros = {};

  List<Usuario> _listaAsesores = [];
  final List<String> tiposGrupo = ['Grupal', 'Individual', 'Selecto'];
  final List<String> roles = ['Miembro', 'Presidente/a', 'Tesorero/a'];

  bool _isLoading = false;
  bool _isLoadingAsesores = true;

  late TabController _tabController;
  int _currentIndex = 0;

  final GlobalKey<FormState> _infoGrupoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _miembrosFormKey = GlobalKey<FormState>();
  //endregion

  final GrupoService _grupoService = GrupoService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.setContext(context);
      _obtenerAsesores();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    nombreGrupoController.dispose();
    detallesController.dispose();
    _typeAheadController.dispose();
    super.dispose();
  }

  //region Lógica de Datos (API Calls usando GrupoService)

  /// Obtiene la lista de asesores usando el servicio.
  Future<void> _obtenerAsesores() async {
    setState(() => _isLoadingAsesores = true);

    final response = await _grupoService.getAsesores(
      showErrorDialog: false
      );

    if (mounted) {
      if (response.success && response.data != null) {
        setState(() {
          _listaAsesores = response.data!;
        });
      }
      setState(() => _isLoadingAsesores = false);
    }
  }

  /// Busca clientes para el TypeAheadField usando el servicio.
  Future<List<Map<String, dynamic>>> _buscarClientes(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return [];
    }
    final response = await _grupoService.buscarClientes(trimmedQuery);
    if (response.success && response.data != null) {
      return response.data!;
    }
    return [];
  }

  /// Orquesta la creación del grupo y sus miembros en UNA SOLA PETICIÓN.
  Future<void> _agregarGrupo() async {
    if (!_validarFormularioActual()) {
      _apiService.showErrorDialog(
        "Datos Faltantes. Asegúrate de haber completado toda la información del grupo.",
      );
      return;
    }
    if (_selectedMiembros.isEmpty) {
      _apiService.showErrorDialog(
        "Miembros Faltantes. Debes agregar al menos un miembro al grupo para poder guardarlo.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- CAMBIO 2: LÓGICA DE ENVÍO SIMPLIFICADA ---
      // Como el validador asegura que _selectedAsesor no es nulo, podemos acceder a su ID directamente.
      // La opción "No asignado" ya no existe.
      final String idAsesorPayload = _selectedAsesor!.idusuarios; // <-- CAMBIO

      final Map<String, dynamic> requestData = {
        'nombreGrupo': nombreGrupoController.text,
        'detalles': detallesController.text,
        'tipoGrupo': selectedTipoGrupo,
        'isAdicional': esAdicional ? 'Sí' : 'No',
        'idusuarios': idAsesorPayload, // <-- CAMBIO
        'clientes':
            _selectedMiembros
                .map(
                  (miembro) => {
                    'idclientes': miembro['idclientes'],
                    'nomCargo':
                        _rolesMiembros[miembro['idclientes']] ?? 'Miembro',
                  },
                )
                .toList(),
      };

      final response = await _grupoService.crearGrupoConMiembros(requestData);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Grupo agregado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onGrupoAgregado?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log("🔥 Error catastrófico en _agregarGrupo: $e\n$stackTrace");
      _apiService.showErrorDialog(
        "Ocurrió un error crítico en la aplicación. Detalles: ${e.toString()}",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  //endregion

  @override
  Widget build(BuildContext context) {
    // ... (El resto del método build y la UI no necesitan cambios, los dejo por completitud)
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
                        Text(
                          'Agregar Grupo',
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
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.divider),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: colors.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
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
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: const [
                        Tab(text: 'Información'),
                        Tab(text: 'Miembros'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_paginaInfoGrupo(), _paginaMiembros()],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
    );
  }

  //region Widgets de UI para las páginas
  Widget _paginaInfoGrupo() {
    const double verticalSpacing = 16.0;

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
            const SizedBox(height: verticalSpacing),
            _buildTextField(
              controller: detallesController,
              label: 'Detalles',
              icon: Icons.description,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildDropdown(
              value: selectedTipoGrupo,
              hint: 'Tipo de Grupo',
              items: tiposGrupo,
              onChanged: (v) => setState(() => selectedTipoGrupo = v),
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: verticalSpacing),
            _buildAsesorDropdown(),
            const SizedBox(height: verticalSpacing),
            CheckboxListTile(
              title: const Text("¿Es Adicional?"),
              value: esAdicional,
              onChanged: (bool? value) {
                setState(() => esAdicional = value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // El resto de los métodos (_paginaMiembros, helpers de UI, etc.) no necesitan cambios.
  // Los incluyo para que el código esté completo.
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

  String _formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }

  Widget _paginaMiembros() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _miembrosFormKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              _sectionTitle('Buscar y Agregar Clientes'),
              TypeAheadField<Map<String, dynamic>>(
                controller: _typeAheadController,
                decorationBuilder: (context, child) {
                  return Material(
                    color: colors.backgroundCard,
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                builder: (context, controller, focusNode) {
                  return _buildTextField(
                    controller: controller,
                    label: 'Buscar cliente por nombre...',
                    icon: Icons.search,
                    focusNode: focusNode,
                  );
                },
                suggestionsCallback: _buscarClientes,
                itemBuilder: (context, suggestion) {
                  final textColor = colors.textPrimary;
                  final estado = suggestion['estado'] as String?;
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${suggestion['nombres']} ${suggestion['apellidoP']}',
                            style: TextStyle(
                              color: textColor,
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
                  );
                },
                onSelected: (suggestion) async {
                  _typeAheadController.clear();
                  FocusScope.of(context).unfocus();

                  if (_selectedMiembros.any(
                    (m) => m['idclientes'] == suggestion['idclientes'],
                  )) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Este miembro ya fue agregado.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => const Dialog(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text("Verificando cliente..."),
                              ],
                            ),
                          ),
                        ),
                  );

                  final response = await _grupoService.verificarAdeudoCliente(
                    suggestion['idclientes'],
                  );

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  final double? montoAdeudo =
                      response.success ? response.data : null;

                  void agregarMiembro(double? adeudo) {
                    setState(() {
                      _selectedMiembros.add(suggestion);
                      _rolesMiembros[suggestion['idclientes']] = roles.first;
                      if (adeudo != null && adeudo > 0) {
                        _adeudosMiembros[suggestion['idclientes']] = adeudo;
                      }
                    });
                  }

                  if (montoAdeudo != null && montoAdeudo > 0) {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 10),
                                Text('Cliente con Adeudo'),
                              ],
                            ),
                            content: Text(
                              'Este cliente tiene un adeudo de \$${_formatearNumero(montoAdeudo)}. ¿Deseas agregarlo de todas formas?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                              ),
                              ElevatedButton(
                                child: const Text('Sí, Agregar'),
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                    );

                    if (confirmar == true) {
                      agregarMiembro(montoAdeudo);
                    }
                  } else {
                    agregarMiembro(null);
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
                    _selectedMiembros.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_add,
                                size: 48,
                                color: colors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aún no has agregado miembros al grupo.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _selectedMiembros.length,
                          itemBuilder: (context, index) {
                            final miembro = _selectedMiembros[index];
                            final idCliente = miembro['idclientes'];
                            final estado = miembro['estado'] as String?;
                            final double? montoAdeudo =
                                _adeudosMiembros[idCliente];

                            return Card(
                              color: colors.backgroundCard,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.brandPrimary,
                                        borderRadius: BorderRadius.circular(22),
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
                                          Text(
                                            '${miembro['nombres']} ${miembro['apellidoP']} ${miembro['apellidoM'] ?? ''}',
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              PopupMenuButton<String>(
                                                offset: const Offset(0, 40),
                                                color: colors.backgroundCard,
                                                onSelected: (nuevoRol) {
                                                  setState(
                                                    () =>
                                                        _rolesMiembros[idCliente] =
                                                            nuevoRol,
                                                  );
                                                },
                                                itemBuilder:
                                                    (context) =>
                                                        roles
                                                            .map(
                                                              (
                                                                rol,
                                                              ) => PopupMenuItem(
                                                                value: rol,
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    if (_rolesMiembros[idCliente] ==
                                                                        rol)
                                                                      Icon(
                                                                        Icons
                                                                            .check_circle_rounded,
                                                                        size:
                                                                            14,
                                                                        color:
                                                                            colors.brandPrimary,
                                                                      )
                                                                    else
                                                                      const SizedBox(
                                                                        width:
                                                                            14,
                                                                      ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      rol,
                                                                      style: TextStyle(
                                                                        color:
                                                                            _rolesMiembros[idCliente] ==
                                                                                    rol
                                                                                ? colors.brandPrimary
                                                                                : colors.textPrimary,
                                                                        fontWeight:
                                                                            _rolesMiembros[idCliente] ==
                                                                                    rol
                                                                                ? FontWeight.w600
                                                                                : FontWeight.normal,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colors.brandPrimary
                                                        .withOpacity(0.05),
                                                    border: Border.all(
                                                      color: colors.brandPrimary
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _rolesMiembros[idCliente] ??
                                                            'Seleccionar',
                                                        style: TextStyle(
                                                          color:
                                                              colors
                                                                  .brandPrimary,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        Icons
                                                            .keyboard_arrow_down_rounded,
                                                        color:
                                                            colors.brandPrimary,
                                                        size: 14,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
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
                                    if (montoAdeudo != null)
                                      Tooltip(
                                        message:
                                            'Adeudo: \$${_formatearNumero(montoAdeudo)}',
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                      ),
                                    if (montoAdeudo != null)
                                      const SizedBox(width: 8),
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
                                            _selectedMiembros.removeAt(index);
                                            _rolesMiembros.remove(idCliente);
                                            _adeudosMiembros.remove(idCliente);
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
  //endregion

  //region Widgets de UI (Reutilizados y adaptados)
  void _handleNextOrSave() {
    FocusScope.of(context).unfocus();

    if (!_validarFormularioActual()) {
      _apiService.showErrorDialog(
        "Campos Incompletos, Por favor, complete todos los campos requeridos en esta sección.",
      );
      return;
    }

    if (_currentIndex < 1) {
      _tabController.animateTo(_currentIndex + 1);
    } else {
      if (_selectedMiembros.isEmpty) {
        _apiService.showErrorDialog(
          "No se puede guardar, Por favor, agregue al menos un miembro al grupo.",
        );
        return;
      }
      _agregarGrupo();
    }
  }

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
            onPressed: _handleNextOrSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.backgroundButton,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(_currentIndex == 1 ? 'Guardar Grupo' : 'Siguiente'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

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

  bool _validarFormularioActual() {
    switch (_currentIndex) {
      case 0:
        return _infoGrupoFormKey.currentState?.validate() ?? false;
      case 1:
        return true;
      default:
        return false;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

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
        keyboardType: keyboardType,
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

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

  // --- CAMBIO 3: WIDGET DEL DROPDOWN SIMPLIFICADO ---
  Widget _buildAsesorDropdown() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    if (_isLoadingAsesores) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Cargando asesores..."),
        ),
      );
    }

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
      // El tipo ahora es Usuario? para que coincida con nuestra variable de estado.
      child: DropdownButtonFormField<Usuario?>(
        // <-- CAMBIO
        value: _selectedAsesor, // <-- CAMBIO
        hint: Text(
          "Seleccionar Asesor",
          style: TextStyle(color: colors.textSecondary),
        ),
        // ¡La lista de items ahora solo contiene los asesores reales!
        items:
            _listaAsesores // <-- CAMBIO
                .map(
                  (asesor) => DropdownMenuItem<Usuario?>(
                    // <-- CAMBIO
                    value: asesor,
                    child: Text(
                      asesor.nombreCompleto,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                )
                .toList(),
        onChanged: (v) => setState(() => _selectedAsesor = v), // <-- CAMBIO
        // El validador ahora es más importante que nunca.
        validator:
            (v) =>
                v == null ? 'Debes seleccionar un asesor' : null, // <-- CAMBIO
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
        // ELIMINADO: Ya no necesitamos el `selectedItemBuilder` porque no hay un
        // caso especial para "No asignado". El comportamiento por defecto es perfecto.
      ),
    );
  }

  //endregion
}
