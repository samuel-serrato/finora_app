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


class GestionarUsuariosScreen extends StatefulWidget {
  const GestionarUsuariosScreen({Key? key}) : super(key: key);

  @override
  _GestionarUsuariosScreenState createState() =>
      _GestionarUsuariosScreenState();
}

class _GestionarUsuariosScreenState extends State<GestionarUsuariosScreen>
    with TickerProviderStateMixin {
  // --- Servicios para la lógica de datos ---
  // ADAPTADO: Se cambian las listas y variables de 'Cliente' a 'Usuario'.
  List<Usuario> listaUsuarios = [];
  bool isLoading = true;
  bool errorDeConexion = false;
  bool noItemsFound = false; // Renombrado de noUsersFound
  Timer? _timer;

  // --- Servicios y Controladores ---
  final ApiService _apiService = ApiService();
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  // --- Paginación y Búsqueda ---
  bool _isLoadingMore = false;
  int currentPage = 1;
  int totalPaginas = 1;
  int totalDatos = 0;
  String _currentSearchQuery = '';
  bool _isSearching = false;

  // --- Ordenamiento y Filtros ---
  String? _sortColumnKey;
  bool _sortAscending = true;
  Map<String, dynamic> _filtrosActivos = {};
  late List<ConfiguracionFiltro> _configuracionesFiltros;
  String? _tipoUsuarioSeleccionadoFiltroAPI; // Para los chips de filtro rápido

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
        _fetchData(page: 1); // Llamada inicial
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

  // ADAPTADO: Se definen los filtros para Usuarios.
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

  // ADAPTADO: Se definen los campos de ordenamiento para Usuarios.
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

  // --- Lógica Principal de Datos ---
  // --- Lógica de Datos (Obtener, Buscar, Cargar más) ---

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

    // Filtro rápido por tipo de usuario (chips)
    if (_tipoUsuarioSeleccionadoFiltroAPI != null) {
      queryParams.add(
        'tipoUsuario=${Uri.encodeComponent(_tipoUsuarioSeleccionadoFiltroAPI!)}',
      );
    }

    // Filtros del modal genérico
    _filtrosActivos.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString().toLowerCase() != 'todos') {
        queryParams.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });

    return queryParams.join('&');
  }

  // --- Lógica de Acciones (CRUD) ---

  // --- MÉTODO ACTUALIZADO PARA AGREGAR USUARIO ---
  void _agregarUsuario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ),
      builder: (context) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = MediaQuery.of(context).size.height;
            const double mobileBreakpoint = 768.0;

            double dialogMaxWidth;
            double dialogMaxHeight;

            if (screenWidth < mobileBreakpoint) {
              // --- LÓGICA MÓVIL ---
              dialogMaxWidth = screenWidth;
              dialogMaxHeight = screenHeight * 0.95; 
            } else {
              // --- LÓGICA DESKTOP ---
              // Para usuarios, un ancho más pequeño puede ser suficiente.
              dialogMaxWidth = screenWidth * 0.6;
              if (dialogMaxWidth > 1200) { // Un máximo más pequeño para formularios simples
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
                    constraints: BoxConstraints(
                      maxHeight: dialogMaxHeight,
                    ),
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

  // --- MÉTODO ACTUALIZADO PARA EDITAR USUARIO ---
  void _editarUsuario(Usuario usuario) {
    // Copiamos la misma lógica para mantener la coherencia.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ),
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
                    constraints: BoxConstraints(
                      maxHeight: dialogMaxHeight,
                    ),
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

// Archivo: lib/screens/gestion/gestionar_usuarios_screen.dart

void _showUsuarioDetails(Usuario usuario) {
  // Obtenemos el ancho total de la pantalla ANTES de llamar al BottomSheet.
  final fullScreenWidth = MediaQuery.of(context).size.width;

  // Definimos las constantes y calculamos el ancho del diálogo aquí mismo.
  const double mobileBreakpoint = 600.0; // Breakpoint para Usuarios
  double dialogMaxWidth;

  if (fullScreenWidth < mobileBreakpoint) {
    // En móvil, el diálogo ocupa todo el ancho.
    dialogMaxWidth = fullScreenWidth;
  } else {
    // --- EN ESCRITORIO ---
    // ¡ESTE ES EL ÚNICO NÚMERO QUE DEBES AJUSTAR!
    // Define el ancho como un porcentaje de la pantalla.
    dialogMaxWidth = fullScreenWidth * 0.6; // <-- Cambia este valor si lo necesitas
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Usamos la propiedad `constraints` para pasar el ancho calculado.
    constraints: BoxConstraints(
      maxWidth: dialogMaxWidth,
    ),
    builder: (context) {
      // El builder ahora solo se preocupa por el contenido vertical.
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // La altura máxima se sigue controlando aquí.
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: InfoUsuarioDialog(idUsuario: usuario.idusuarios),
        ),
      );
    },
  );
}

  String _buildEndpoint({required int page, String? searchQuery}) {
    List<String> queryParams = [];
    if (_sortColumnKey != null) {
      queryParams.add('${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}');
    }
    String searchPath =
        (searchQuery != null && searchQuery.isNotEmpty)
            ? '/${Uri.encodeComponent(searchQuery)}'
            : '';
    String finalQuery = queryParams.where((p) => p.isNotEmpty).join('&');
    return '/api/v1/usuarios$searchPath?limit=12&page=$page${finalQuery.isNotEmpty ? '&$finalQuery' : ''}';
  }

  // --- Widgets de Construcción de UI ---
  // --- Método Build ---
  @override
Widget build(BuildContext context) {
  final colors = Provider.of<ThemeProvider>(context).colors;

  // <<< WIDGET CONTENEDOR PRINCIPAL >>>
  // Usamos un Container para darle un color de fondo a toda la vista,
  // incluyendo el área detrás de la nueva barra.
  return Container(
    color: colors.backgroundPrimary, // Asigna el color de fondo correcto
    child: Column(
      children: [
        
        // <<< 1. LA BARRA PARA DESLIZAR (DRAG HANDLE) >>>
        // Es un simple Container con bordes redondeados, centrado.
        // <<< CÓDIGO MUCHO MÁS LIMPIO Y DECLARATIVO >>>
        // Solo se muestra la barra si el contexto se considera 'móvil'
        if (context.isMobile) ...[
            // Drag Handle
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

            // Título de la pantalla (solo para móvil)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
              child: Text(
                'Gestionar Usuarios', // <-- CAMBIA ESTE TEXTO
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      colors.textPrimary, // O el color que prefieras de tu tema
                ),
              ),
            ),
          ],

        // <<< 2. TU CONTENIDO ORIGINAL, ENVUELTO EN EXPANDED >>>
        // Expanded es CRUCIAL. Le dice al ListView que ocupe todo el
        // espacio vertical restante, evitando errores de layout.
        Expanded(
          child: ResponsiveScaffoldListView<Usuario>(
            // --- Datos y Estado (sin cambios) ---
            items: listaUsuarios,
            isLoading: isLoading,
            isLoadingMore: _isLoadingMore,
            hasError: errorDeConexion,
            noItemsFound: noItemsFound,
            totalItems: totalDatos,
            currentPage: currentPage,
            totalPages: totalPaginas,
            scrollController: _scrollController,

            // --- Builders para las tarjetas (sin cambios) ---
            cardBuilder: (context, usuario) =>
                _buildStandardUsuarioCard(usuario, colors),
            tableRowCardBuilder: (context, usuario) =>
                _buildTableRowUsuarioCard(usuario, colors),
            cardHeight: 180,

            // --- Callbacks para acciones (sin cambios) ---
            onRefresh: _onRefresh,
            onLoadMore: _loadMoreData,
            onSearchChanged: _onSearchChanged,
            onAddItem: _agregarUsuario,

            // --- Widgets de la barra de acciones (sin cambios) ---
            actionBarContent: _buildUserTypeFilterChips(colors),
            sortButton: _buildSortButton(context, colors),

            // --- Textos y animaciones (sin cambios) ---
            appBarTitle: 'Usuarios',
            searchHintText: 'Buscar por nombre, usuario...',
            addItemText: 'Agregar Usuario',
            loadingText: 'Cargando usuarios...',
            emptyStateTitle: 'No se encontraron usuarios',
            emptyStateSubtitle: 'Aún no hay usuarios registrados. ¡Agrega uno!',
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
  // --- Widgets de UI (Cards, Chips, Popups) ---

  Widget _buildStandardUsuarioCard(Usuario usuario, dynamic colors) {
    // El Container, Material e InkWell externos se mantienen igual.
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
            // 1. Column principal con spaceBetween, igual que en Cliente.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- SECCIÓN SUPERIOR: Idéntica en estructura a la de Cliente ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserTypeChip(
                      usuario.tipoUsuario,
                    ), // Chip de tipo de usuario
                    const Spacer(),
                    _buildPopupMenu(usuario, colors), // Menú de opciones
                  ],
                ),

                // --- SECCIÓN INFERIOR: Estructura replicada de Cliente ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Row para Nombre/Fecha (y un posible chip a la derecha si lo hubiera).
                    Row(
                      children: [
                        // La columna para el nombre y la fecha está dentro de un Expanded
                        // para ocupar el espacio disponible, igual que en Cliente.
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
                        // NOTA: El modelo Usuario no tiene un "status" como el Cliente.
                        // Si lo tuviera, aquí iría el chip de estado, como en la tarjeta de Cliente.
                        // Al no tenerlo, el Expanded de arriba simplemente ocupa todo el ancho.
                      ],
                    ),

                    // 3. Divisor, igual que en Cliente.
                    const Divider(height: 24),

                    // 4. Row para la información de contacto, con spaceBetween.
                    // Esta estructura es más flexible que dos Rows separadas.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Usamos Expanded para que cada chip pueda crecer pero no desbordarse.
                        Expanded(
                          child: _buildInfoChip(
                            Icons.person_outline_rounded,
                            usuario.usuario,
                            Colors.teal,
                            colors,
                          ),
                        ),
                        const SizedBox(width: 14), // Espacio entre los chips
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

  // ADAPTADO: Chip para el tipo de usuario.
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

  // ADAPTADO: Chips de filtro rápido por tipo de usuario.
Widget _buildUserTypeFilterChips(dynamic colors) {
  final tipos = ['Todos', 'Admin', 'Asesor'];
  final themeProvider = Provider.of<ThemeProvider>(context);

  return SizedBox(
    height: 32,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: tipos.map((tipo) {
        final isSelected =
            (_tipoUsuarioSeleccionadoFiltroAPI == null && tipo == 'Todos') ||
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
              color: isSelected
                  ? Colors.blue
                  : (themeProvider.isDarkMode
                      ? Colors.white70
                      : Colors.grey[700]),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Colors.blue
                    : (themeProvider.isDarkMode
                        ? Colors.grey[700]!
                        : Colors.grey.withOpacity(0.3)),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            // --- CORRECCIÓN APLICADA ---
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // <-- AÑADIDO
            visualDensity: VisualDensity.compact,                   // <-- AÑADIDO
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildFilterButton(BuildContext context) {
    // La implementación genérica de Clientes funciona perfectamente aquí.
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

  /*  Widget _buildSortButton(BuildContext context, dynamic colors) {
    // El widget de Clientes se adapta sin cambios.
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedFieldInfo = _sortableFieldsWithTypes.entries.firstWhere((e) => e.value['api_key'] == _sortColumnKey, orElse: () => null as MapEntry<String, Map<String, dynamic>>?);

    return HoverableActionButton(
      onTap: () => _showSortOptions(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedFieldInfo?.value['icon'] ?? Icons.tune_rounded,
            size: 20,
            color: _sortColumnKey != null ? Colors.blueAccent : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
          ),
          if (_sortColumnKey != null) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 16,
              color: Colors.blueAccent,
            ),
          ],
        ],
      ),
    );
  } */

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
        ascText += '';
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

  /* void _showSortOptions(BuildContext context) {
    // La lógica del modal genérico de Clientes funciona perfectamente.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => OrdenamientoGenericoMobile.create(
        context: context,
        sortableFields: _sortableFieldsWithTypes,
        currentSortKey: _sortColumnKey,
        isAscending: _sortAscending,
        onApply: (newSortKey, newIsAscending) {
          setState(() {
            _sortColumnKey = newSortKey;
            _sortAscending = newIsAscending;
          });
          _aplicarFiltrosYOrdenamiento();
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _sortColumnKey = null;
            _sortAscending = true;
          });
          _aplicarFiltrosYOrdenamiento();
          Navigator.pop(context);
        }
      )
    );
  } */
}

// ADAPTADO: He movido buildFilterButtonMobile fuera de la clase State para que sea una función de nivel superior reutilizable.
// Si ya la tienes en otro archivo, puedes importarla.
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
