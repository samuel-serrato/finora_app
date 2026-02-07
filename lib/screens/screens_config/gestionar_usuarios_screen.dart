// Archivo: lib/screens/gestion/gestionar_usuarios_screen.dart

import 'dart:async';
import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/dialog/usuario_detalle_dialog.dart';
import 'package:finora_app/forms/editUsuario_form.dart';
import 'package:finora_app/forms/nUsuario_form.dart';
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/usuario_service.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/widgets/filtros_genericos_widget.dart';
import 'package:finora_app/widgets/hoverableActionButton.dart';
import 'package:finora_app/widgets/ordenamiento_genericos.dart';
import 'package:finora_app/widgets/responsive_scaffold_list_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_logger.dart';

// --- 1. IMPORTAR LOS WIDGETS Y PROVIDERS NECESARIOS ---
import 'package:finora_app/providers/ui_provider.dart';
import 'package:finora_app/widgets/global_layout_button.dart';
// --------------------------------------------------------

class GestionarUsuariosScreen extends StatefulWidget {
  const GestionarUsuariosScreen({Key? key}) : super(key: key);

  @override
  _GestionarUsuariosScreenState createState() =>
      _GestionarUsuariosScreenState();
}

class _GestionarUsuariosScreenState extends State<GestionarUsuariosScreen>
    with TickerProviderStateMixin {
  // --- Todas tus variables de estado se mantienen igual ---
  List<Usuario> listaUsuarios = [];
  bool isLoading = true;
  bool errorDeConexion = false;
  bool noItemsFound = false;
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int currentPage = 1;
  int totalPaginas = 1;
  int totalDatos = 0;
  String _currentSearchQuery = '';
  bool _isSearching = false;
  String? _sortColumnKey;
  bool _sortAscending = true;
  Map<String, dynamic> _filtrosActivos = {};
  late List<ConfiguracionFiltro> _configuracionesFiltros;
  String? _tipoUsuarioSeleccionadoFiltroAPI;

  // (El resto de tus métodos initState, dispose, obtenerUsuarios, etc. se mantienen igual)
  // ...
  // ... (Aquí iría todo tu código de lógica de datos que ya tienes)
  // ...

  // --- 2. MODIFICAR EL MÉTODO BUILD ---
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    // Obtenemos la instancia del UiProvider para leer la configuración
    final uiProvider = Provider.of<UiProvider>(context);

    return Container(
      color: colors.backgroundPrimary,
      child: Column(
        children: [
          if (context.isMobile) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
              child: Text(
                'Gestionar Usuarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
          Expanded(
            child: ResponsiveScaffoldListView<Usuario>(
              // --- Datos y Estado ---
              items: listaUsuarios,
              isLoading: isLoading,
              isLoadingMore: _isLoadingMore,
              hasError: errorDeConexion,
              noItemsFound: noItemsFound,
              totalItems: totalDatos,
              currentPage: currentPage,
              totalPages: totalPaginas,
              scrollController: _scrollController,

              // --- ¡CONECTANDO LA LÓGICA GLOBAL AQUÍ! ---
              userSelectedCrossAxisCount:
                  uiProvider.crossAxisCount, // <-- Le pasamos el valor guardado
              layoutControlButton:
                  const GlobalLayoutButton(), // <-- Le pasamos el botón reutilizable
              // --- Builders para las tarjetas ---
              cardBuilder:
                  (context, usuario) =>
                      _buildStandardUsuarioCard(usuario, colors),
              tableRowCardBuilder:
                  (context, usuario) =>
                      _buildTableRowUsuarioCard(usuario, colors),
              cardHeight: 180,

              // --- Callbacks para acciones ---
              onRefresh: _onRefresh,
              onLoadMore: _loadMoreData,
              onSearchChanged: _onSearchChanged,
              onAddItem: _agregarUsuario,

              // --- Widgets de la barra de acciones ---
              actionBarContent: _buildUserTypeFilterChips(colors),
              sortButton: _buildSortButton(context, colors),
              // filterButton: _buildFilterButton(context), // Opcional, si lo necesitas

              // --- Textos y animaciones ---
              appBarTitle: 'Usuarios',
              searchHintText: 'Buscar por nombre, usuario...',
              addItemText: 'Agregar Usuario',
              loadingText: 'Cargando usuarios...',
              emptyStateTitle: 'No se encontraron usuarios',
              emptyStateSubtitle:
                  'Aún no hay usuarios registrados. ¡Agrega uno!',
              emptyStateIcon: Icons.people_outline_rounded,
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
              fabHeroTag: 'fab_usuarios',
            ),
          ),
        ],
      ),
    );
  }

  // --- El resto de tu código no necesita cambios ---
  // (Pego el resto de tu código para que lo tengas completo)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializarFiltros();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMoreData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _apiService.setContext(context);
        _fetchData(page: 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializarFiltros() {
    _configuracionesFiltros = [
      ConfiguracionFiltro(
        clave: 'tipoUsuario',
        titulo: 'Tipo de Usuario',
        tipo: TipoFiltro.dropdown,
        opciones: ['Admin', 'Asesor'],
      ),
    ];
    _filtrosActivos = {
      for (var config in _configuracionesFiltros) config.clave: null,
    };
  }

  final Map<String, Map<String, dynamic>> _sortableFieldsWithTypes = {
    'Nombre Completo': {
      'api_key': 'nombrecompleto',
      'type': 'text',
      'icon': Icons.sort_by_alpha_rounded,
    },
    'Nombre de Usuario': {
      'api_key': 'usuario',
      'type': 'text',
      'icon': Icons.person_rounded,
    },
    'Fecha Creación': {
      'api_key': 'fCreacion',
      'type': 'date',
      'icon': Icons.calendar_today_rounded,
    },
  };

  Future<void> _fetchData({required int page, bool loadMore = false}) async {
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      await searchUsuarios(_currentSearchQuery, page: page, loadMore: loadMore);
    } else {
      await obtenerUsuarios(page: page, loadMore: loadMore);
    }
  }

  Future<void> obtenerUsuarios({int page = 1, bool loadMore = false}) async {
    if (!mounted || (loadMore && _isLoadingMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        isLoading = true;
        errorDeConexion = false;
        noItemsFound = false;
      }
      currentPage = page;
    });

    String filterQuery = _buildFilterQuery();
    String sortQuery =
        _sortColumnKey != null
            ? '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}'
            : '';
    final endpoint =
        '/api/v1/usuarios?limit=12&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔄 Obteniendo usuarios: $baseUrl$endpoint');

    try {
      final response = await _apiService.get<List<Usuario>>(
        endpoint,
        parser:
            (json) =>
                (json as List).map((item) => Usuario.fromJson(item)).toList(),
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaUsuarios.addAll(response.data!);
            } else {
              listaUsuarios = response.data!;
              if (listaUsuarios.isNotEmpty) {
                _animationController.forward(from: 0.0);
              }
            }
            noItemsFound = listaUsuarios.isEmpty;
            totalDatos =
                int.tryParse(response.headers?['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers?['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
          } else {
            if (!loadMore) {
              listaUsuarios = [];
              noItemsFound = true;
              totalDatos = 0;
            }
          }
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) listaUsuarios.clear();
        });
      }
    }
  }

  Future<void> searchUsuarios(
    String query, {
    int page = 1,
    bool loadMore = false,
  }) async {
    _currentSearchQuery = query;
    if (query.trim().isEmpty) {
      _isSearching = false;
      obtenerUsuarios(page: 1);
      return;
    }
    if (!mounted || (loadMore && _isLoadingMore)) return;
    _isSearching = true;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        isLoading = true;
        errorDeConexion = false;
        noItemsFound = false;
      }
      currentPage = page;
    });

    String filterQuery = _buildFilterQuery();
    String sortQuery =
        _sortColumnKey != null
            ? '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}'
            : '';
    final encodedQuery = Uri.encodeComponent(query);
    final endpoint =
        '/api/v1/usuarios/$encodedQuery?limit=12&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔍 Buscando usuarios: $baseUrl$endpoint');

    try {
      final response = await _apiService.get<List<Usuario>>(
        endpoint,
        parser:
            (json) =>
                (json as List).map((item) => Usuario.fromJson(item)).toList(),
        showErrorDialog: false,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaUsuarios.addAll(response.data!);
            } else {
              listaUsuarios = response.data!;
              if (listaUsuarios.isNotEmpty) {
                _animationController.forward(from: 0.0);
              }
            }
            noItemsFound = listaUsuarios.isEmpty;
            totalDatos =
                int.tryParse(response.headers?['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers?['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
          } else {
            if (!loadMore) {
              listaUsuarios = [];
              noItemsFound = true;
              totalDatos = 0;
            }
          }
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) listaUsuarios.clear();
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _currentSearchQuery = query;
    _isSearching = query.trim().isNotEmpty;
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 700),
      () => _fetchData(page: 1),
    );
  }

  Future<void> _onRefresh() async {
    _searchController.clear();
    _currentSearchQuery = '';
    _isSearching = false;
    await _fetchData(page: 1);
  }

  void _loadMoreData() {
    if (currentPage < totalPaginas && !_isLoadingMore) {
      _fetchData(page: currentPage + 1, loadMore: true);
    }
  }

  void _aplicarFiltrosYOrdenamiento() {
    _fetchData(page: 1);
  }

  String _buildFilterQuery() {
    List<String> queryParams = [];

    if (_tipoUsuarioSeleccionadoFiltroAPI != null) {
      queryParams.add(
        'tipoUsuario=${Uri.encodeComponent(_tipoUsuarioSeleccionadoFiltroAPI!)}',
      );
    }

    _filtrosActivos.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString().toLowerCase() != 'todos') {
        queryParams.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });

    return queryParams.join('&');
  }

  void _agregarUsuario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = MediaQuery.of(context).size.height;
            const double mobileBreakpoint = 768.0;

            double dialogMaxWidth;
            double dialogMaxHeight;

            if (screenWidth < mobileBreakpoint) {
              dialogMaxWidth = screenWidth;
              dialogMaxHeight = screenHeight * 0.95;
            } else {
              dialogMaxWidth = screenWidth * 0.6;
              if (dialogMaxWidth > 1200) {
                dialogMaxWidth = 1200;
              }
              dialogMaxHeight = screenHeight * 0.85;
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: dialogMaxWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                    child: nUsuarioForm(onUsuarioAgregado: _onRefresh),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarUsuario(Usuario usuario) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = MediaQuery.of(context).size.height;
            const double mobileBreakpoint = 768.0;

            double dialogMaxWidth;
            double dialogMaxHeight;

            if (screenWidth < mobileBreakpoint) {
              dialogMaxWidth = screenWidth;
              dialogMaxHeight = screenHeight * 0.85;
            } else {
              dialogMaxWidth = screenWidth * 0.6;
              if (dialogMaxWidth > 1200) {
                dialogMaxWidth = 1200;
              }
              dialogMaxHeight = screenHeight * 0.85;
            }

            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: dialogMaxWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                    child: editUsuarioForm(
                      idUsuario: usuario.idusuarios,
                      onUsuarioEditado: _onRefresh,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _eliminarUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Seguro que quieres eliminar a ${usuario.nombreCompleto}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _confirmarEliminacion(usuario);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmarEliminacion(Usuario usuario) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await _usuarioService.eliminarUsuario(
      usuario.idusuarios,
      showErrorDialog: false,
    );
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado'),
          backgroundColor: Colors.green,
        ),
      );
      _onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Error al eliminar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUsuarioDetails(Usuario usuario) {
    final fullScreenWidth = MediaQuery.of(context).size.width;

    const double mobileBreakpoint = 600.0;
    double dialogMaxWidth;

    if (fullScreenWidth < mobileBreakpoint) {
      dialogMaxWidth = fullScreenWidth;
    } else {
      dialogMaxWidth = fullScreenWidth * 0.6;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: dialogMaxWidth),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            child: InfoUsuarioDialog(idUsuario: usuario.idusuarios),
          ),
        );
      },
    );
  }

  Widget _buildStandardUsuarioCard(Usuario usuario, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showUsuarioDetails(usuario),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserTypeChip(usuario.tipoUsuario),
                    const Spacer(),
                    _buildPopupMenu(usuario, colors),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usuario.nombreCompleto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatters.formatearFechaRelativa(
                                  usuario.fCreacion,
                                ),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.person_outline_rounded,
                            usuario.usuario,
                            Colors.teal,
                            colors,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildInfoChip(
                            Icons.email_outlined,
                            usuario.email,
                            Colors.blueGrey,
                            colors,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRowUsuarioCard(Usuario usuario, dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _showUsuarioDetails(usuario),
          hoverColor: colors.textPrimary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        usuario.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatters.formatearFechaRelativa(
                          usuario.fCreacion,
                        ),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(indent: 8, endIndent: 8),
                Expanded(
                  flex: 2,
                  child: _buildInfoChip(
                    Icons.person_rounded,
                    usuario.usuario,
                    Colors.teal,
                    colors,
                  ),
                ),
                const VerticalDivider(indent: 8, endIndent: 8),
                Expanded(
                  flex: 3,
                  child: _buildInfoChip(
                    Icons.email_rounded,
                    usuario.email,
                    Colors.blueGrey,
                    colors,
                  ),
                ),
                const Spacer(),
                _buildUserTypeChip(usuario.tipoUsuario),
                const SizedBox(width: 10),
                _buildPopupMenu(usuario, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuButton<String> _buildPopupMenu(Usuario usuario, dynamic colors) =>
      PopupMenuButton<String>(
        offset: const Offset(0, 40),
        color: colors.backgroundPrimary,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: colors.textSecondary,
          size: 24,
        ),
        onSelected: (value) {
          if (value == 'editar') _editarUsuario(usuario);
          if (value == 'eliminar') _eliminarUsuario(usuario);
        },
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Eliminar'),
                  ],
                ),
              ),
            ],
      );

  Widget _buildInfoChip(
    IconData icon,
    String text,
    Color color,
    dynamic colors,
  ) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _buildUserTypeChip(String tipoUsuario) {
    final bool esAdmin = tipoUsuario.toLowerCase() == 'admin';
    final color = esAdmin ? Colors.purple : Colors.blue;
    final icon = esAdmin ? Icons.shield_rounded : Icons.person_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            tipoUsuario,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeFilterChips(dynamic colors) {
    final tipos = ['Todos', 'Admin', 'Asesor'];
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            tipos.map((tipo) {
              final isSelected =
                  (_tipoUsuarioSeleccionadoFiltroAPI == null &&
                      tipo == 'Todos') ||
                  (_tipoUsuarioSeleccionadoFiltroAPI == tipo);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  showCheckmark: false,
                  label: Text(tipo, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                        () =>
                            _tipoUsuarioSeleccionadoFiltroAPI =
                                tipo == 'Todos' ? null : tipo,
                      );
                      _aplicarFiltrosYOrdenamiento();
                    }
                  },
                  backgroundColor: themeProvider.colors.backgroundCard,
                  selectedColor: Colors.blue.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Colors.blue
                            : (themeProvider.isDarkMode
                                ? Colors.white70
                                : Colors.grey[700]),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isSelected
                              ? Colors.blue
                              : (themeProvider.isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey.withOpacity(0.3)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return buildFilterButtonMobile(
      context,
      _filtrosActivos,
      _configuracionesFiltros,
      (filtrosAplicados) {
        setState(() => _filtrosActivos = Map.from(filtrosAplicados));
        _aplicarFiltrosYOrdenamiento();
      },
      () {
        setState(() => _filtrosActivos.updateAll((key, value) => null));
        _aplicarFiltrosYOrdenamiento();
      },
    );
  }

  Widget _buildSortButton(BuildContext context, AppColors colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedFieldInfo = _getSelectedFieldInfo();
    return HoverableActionButton(
      onTap: () => _showSortOptions(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedFieldInfo != null ? selectedFieldInfo['icon'] : Icons.tune,
            size: 20,
            color:
                _sortColumnKey != null
                    ? colors.brandPrimary
                    : (isDarkMode ? Colors.white : Colors.black87),
          ),
          if (_sortColumnKey != null) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
              color: colors.brandPrimary,
            ),
          ],
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final List<String> camposOrdenamiento = [
      'Ninguno',
      ..._sortableFieldsWithTypes.keys,
    ];
    final String? initialSortFieldDisplayName =
        _getCurrentSortFieldDisplayName();
    final String? initialFieldType = _getFieldTypeForSortableField(
      initialSortFieldDisplayName,
    );
    final Map<String, String> initialDirectionDisplayLabels =
        _getDirectionDisplayLabels(initialFieldType);

    List<String> initialOpcionesDireccionConDescripcion =
        initialDirectionDisplayLabels.values
            .where((label) => label.isNotEmpty)
            .toList();
    String? initialDirectionValue;

    if (_sortColumnKey != null) {
      initialDirectionValue =
          _sortAscending
              ? initialDirectionDisplayLabels['Ascendente']
              : initialDirectionDisplayLabels['Descendente'];
      if (!initialOpcionesDireccionConDescripcion.contains(
        initialDirectionValue,
      )) {
        initialDirectionValue = null;
      }
    }

    List<ConfiguracionOrdenamiento> currentConfigsOrdenamiento = [
      ConfiguracionOrdenamiento(
        clave: _keySortColumnConfig,
        titulo: "Ordenar por",
        tipo: TipoOrdenamiento.dropdown,
        opciones: camposOrdenamiento,
        hintText: "Selecciona un campo",
      ),
      ConfiguracionOrdenamiento(
        clave: _keySortDirectionConfig,
        titulo: "Dirección",
        tipo: TipoOrdenamiento.dropdown,
        opciones: List<String>.from(initialOpcionesDireccionConDescripcion),
        hintText: 'Selecciona dirección',
      ),
    ];

    Map<String, dynamic> currentValoresOrdenamiento = {
      _keySortColumnConfig: initialSortFieldDisplayName ?? 'Ninguno',
      _keySortDirectionConfig: initialDirectionValue,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return StatefulBuilder(
                builder: (BuildContext sbfContext, StateSetter modalSetState) {
                  return OrdenamientoGenericoMobile(
                    configuraciones: currentConfigsOrdenamiento,
                    valoresIniciales: currentValoresOrdenamiento,
                    titulo: 'Opciones de Ordenamiento',
                    textoBotonAplicar: 'Aplicar',
                    onValorCambiado: (
                      String claveCampoCambiado,
                      dynamic nuevoValor,
                    ) {
                      modalSetState(() {
                        currentValoresOrdenamiento[claveCampoCambiado] =
                            nuevoValor;
                        if (claveCampoCambiado == _keySortColumnConfig) {
                          final String? nuevoCampoOrdenamiento =
                              nuevoValor as String?;
                          final String? nuevoTipoCampo =
                              _getFieldTypeForSortableField(
                                nuevoCampoOrdenamiento,
                              );
                          final Map<String, String> nuevasEtiquetasDireccion =
                              _getDirectionDisplayLabels(nuevoTipoCampo);
                          final List<String> nuevasOpcionesDireccion =
                              nuevasEtiquetasDireccion.values
                                  .where((label) => label.isNotEmpty)
                                  .toList();
                          int directionConfigIndex = currentConfigsOrdenamiento
                              .indexWhere(
                                (c) => c.clave == _keySortDirectionConfig,
                              );
                          if (directionConfigIndex != -1) {
                            currentConfigsOrdenamiento[directionConfigIndex] =
                                ConfiguracionOrdenamiento(
                                  clave: _keySortDirectionConfig,
                                  titulo: "Dirección",
                                  tipo: TipoOrdenamiento.dropdown,
                                  opciones: nuevasOpcionesDireccion,
                                  hintText: 'Selecciona dirección',
                                );
                          }
                          currentValoresOrdenamiento[_keySortDirectionConfig] =
                              null;
                        }
                      });
                    },
                    onAplicar: (valoresAplicados) {
                      final String? nuevoCampoDisplayName =
                          valoresAplicados[_keySortColumnConfig];
                      final String? nuevaDireccionConDescripcion =
                          valoresAplicados[_keySortDirectionConfig];
                      bool esAscendente = true;

                      if (nuevaDireccionConDescripcion != null) {
                        final String? tipoDeCampoActual =
                            _getFieldTypeForSortableField(
                              nuevoCampoDisplayName,
                            );
                        final Map<String, String> etiquetasDireccionActuales =
                            _getDirectionDisplayLabels(tipoDeCampoActual);
                        for (var entry in etiquetasDireccionActuales.entries) {
                          if (entry.value == nuevaDireccionConDescripcion) {
                            esAscendente = (entry.key == 'Ascendente');
                            break;
                          }
                        }
                      }

                      setState(() {
                        _sortAscending = esAscendente;
                        if (nuevoCampoDisplayName != null &&
                            nuevoCampoDisplayName != 'Ninguno') {
                          _sortColumnKey =
                              _sortableFieldsWithTypes[nuevoCampoDisplayName]!['api_key'];
                        } else {
                          _sortColumnKey = null;
                        }
                      });
                      obtenerUsuarios(page: 1);
                      Navigator.pop(context);
                    },
                    onRestablecer: () {
                      setState(() {
                        _sortColumnKey = null;
                        _sortAscending = true;
                      });
                      obtenerUsuarios(page: 1);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
    );
  }

  Map<String, String> _getDirectionDisplayLabels(String? fieldType) {
    String ascText = 'Ascendente';
    String descText = 'Descendente';
    switch (fieldType) {
      case 'date':
        ascText += ' (más antiguo)';
        descText += ' (más reciente)';
        break;
      case 'text':
        ascText += ' (A-Z)';
        descText += ' (Z-A)';
        break;
      default:
        // Si no es ni fecha ni texto, no mostramos descripción de dirección.
        ascText = '';
        descText = '';
        break;
    }
    return {'Ascendente': ascText, 'Descendente': descText};
  }

  static const String _keySortColumnConfig = 'sort_by_column_config_key';
  static const String _keySortDirectionConfig = 'sort_direction_config_key';

  String? _getFieldTypeForSortableField(String? fieldDisplayName) {
    if (fieldDisplayName == null || fieldDisplayName == 'Ninguno') return null;
    return _sortableFieldsWithTypes[fieldDisplayName]?['type'];
  }

  String? _getCurrentSortFieldDisplayName() {
    if (_sortColumnKey == null) return null;
    for (var entry in _sortableFieldsWithTypes.entries) {
      if (entry.value['api_key'] == _sortColumnKey) return entry.key;
    }
    return null;
  }

  Map<String, dynamic>? _getSelectedFieldInfo() {
    if (_sortColumnKey == null) return null;
    for (var entry in _sortableFieldsWithTypes.entries) {
      if (entry.value['api_key'] == _sortColumnKey) {
        return {
          'display_name': entry.key,
          'type': entry.value['type'],
          'icon': entry.value['icon'],
        };
      }
    }
    return null;
  }
}

Widget buildFilterButtonMobile(
  BuildContext context,
  Map<String, dynamic> filtrosActivos,
  List<ConfiguracionFiltro> configuracionesFiltros,
  Function(Map<String, dynamic>) onAplicarFiltros,
  VoidCallback onRestablecerFiltros,
) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDarkMode = themeProvider.isDarkMode;

  int activeFilterCount =
      filtrosActivos.values
          .where((v) => v != null && v.toString().toLowerCase() != 'todos')
          .length;

  return HoverableActionButton(
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (modalContext) => FiltrosGenericosMobile(
              configuraciones: configuracionesFiltros,
              valoresIniciales: Map.from(filtrosActivos),
              titulo: 'Filtros de Usuarios',
              onAplicar: onAplicarFiltros,
              onRestablecer: onRestablecerFiltros,
            ),
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.filter_list_rounded,
          size: 22,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        if (activeFilterCount > 0)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeFilterCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    ),
  );
}
