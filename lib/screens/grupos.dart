import 'dart:async';
import 'dart:math';
import 'package:finora_app/dialog/grupo_detalle_dialog.dart';
import 'package:finora_app/forms/edit_grupo_form.dart';
import 'package:finora_app/forms/ngrupo_form.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/ui_provider.dart'; // <--- 1. IMPORTAR UI PROVIDER
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/grupo_service.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/widgets/filtros_genericos_widget.dart';
import 'package:finora_app/widgets/global_layout_button.dart';
import 'package:finora_app/widgets/hoverableActionButton.dart';
import 'package:finora_app/widgets/ordenamiento_genericos.dart';
import 'package:finora_app/widgets/responsive_scaffold_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finora_app/ip.dart';

class GruposScreenMobile extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const GruposScreenMobile({
    super.key,
    required this.username,
    required this.tipoUsuario,
  });

  @override
  _GruposScreenMobileState createState() => _GruposScreenMobileState();
}

class _GruposScreenMobileState extends State<GruposScreenMobile>
    with TickerProviderStateMixin {
  List<Grupo> listaGrupos = [];
  List<Grupo> listaFiltrada = [];
  bool isLoading = false;
  bool errorDeConexion = false;
  bool noGroupsFound = false;
  String _searchQuery = '';
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final GrupoService _grupoService = GrupoService();
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
  String? _estadoGrupoSeleccionadoFiltroAPI;
  List<Usuario> _usuarios = [];
  bool _isLoadingUsuarios = false;
  
  // --- 2. VARIABLE PARA EL HOVER DEL BOTÓN ---
  bool _isButtonHovered = false; 

  // Constantes de ordenamiento
  static const String _keySortColumnConfig = 'sort_by_column_config_key';
  static const String _keySortDirectionConfig = 'sort_direction_config_key';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializarFiltros();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _apiService.setContext(context);
        obtenerGrupos();
        obtenerUsuariosCampo();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
  }

  void _initializarFiltros() {
    _configuracionesFiltros = [
      ConfiguracionFiltro(
        clave: 'tipogrupo',
        titulo: 'Tipo de Grupo',
        tipo: TipoFiltro.dropdown,
        opciones: ['Grupal', 'Individual', 'Automotriz', 'Empresarial'],
      ),
      ConfiguracionFiltro(
        clave: 'asesor',
        titulo: 'Asesor',
        tipo: TipoFiltro.dropdown,
        opciones: [],
      ),
    ];
    _filtrosActivos = {
      for (var config in _configuracionesFiltros) config.clave: null,
    };
  }

  final Map<String, Map<String, dynamic>> _sortableFieldsWithTypes = {
    'Nombre Grupo': {
      'api_key': 'nombregrupo',
      'type': 'text',
      'icon': Icons.sort_by_alpha_rounded,
    },
    'Fecha Creación': {
      'api_key': 'fCreacion',
      'type': 'date',
      'icon': Icons.calendar_today_rounded,
    },
  };

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE DATOS (obtenerGrupos, searchGrupos, etc.) ---
  // (Se mantienen igual que en tu código original)
  Future<void> obtenerGrupos({int page = 1, bool loadMore = false}) async {
    if (!mounted || (loadMore && _isLoadingMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        isLoading = true;
        errorDeConexion = false;
        noGroupsFound = false;
      }
      currentPage = page;
    });

    String sortQuery =
        _sortColumnKey != null
            ? '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}'
            : '';
    String filterQuery = _buildFilterQuery();
    final endpoint =
        '/api/v1/grupodetalles?limit=24&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';

    try {
      final response = await _apiService.get<List<Grupo>>(
        endpoint,
        parser:
            (json) =>
                (json as List).map((item) => Grupo.fromJson(item)).toList(),
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaGrupos.addAll(response.data!);
              listaFiltrada.addAll(response.data!);
            } else {
              listaGrupos = response.data!;
              listaFiltrada = List.from(listaGrupos);
              if (listaGrupos.isNotEmpty) _animationController.forward(from: 0);
            }
            noGroupsFound = listaGrupos.isEmpty;
            errorDeConexion = false;

            totalDatos =
                int.tryParse(response.headers?['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers?['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
          } else if (!loadMore) {
            listaGrupos = [];
            listaFiltrada = [];
            noGroupsFound = true;
            totalDatos = 0;
            totalPaginas = 1;
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
        });
      }
    }
  }

  Future<void> searchGrupos(
    String query, {
    int page = 1,
    bool loadMore = false,
  }) async {
    _currentSearchQuery = query;
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _isSearching = false;
      obtenerGrupos(page: 1);
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
        noGroupsFound = false;
      }
      currentPage = page;
    });

    String sortQuery =
        _sortColumnKey != null
            ? '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}'
            : '';
    String filterQuery = _buildFilterQuery();
    final encodedQuery = Uri.encodeComponent(query);
    final endpoint =
        '/api/v1/grupodetalles/$encodedQuery?limit=24&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';

    try {
      final response = await _apiService.get<List<Grupo>>(
        endpoint,
        parser:
            (json) =>
                (json is List)
                    ? json.map((item) => Grupo.fromJson(item)).toList()
                    : <Grupo>[],
        showErrorDialog: false,
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaGrupos.addAll(response.data!);
              listaFiltrada.addAll(response.data!);
            } else {
              listaGrupos = response.data!;
              listaFiltrada = List.from(listaGrupos);
              if (listaGrupos.isNotEmpty) _animationController.forward(from: 0);
            }
            noGroupsFound = listaGrupos.isEmpty;
            totalDatos =
                int.tryParse(response.headers?['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers?['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
          } else if (!loadMore) {
            listaGrupos = [];
            listaFiltrada = [];
            noGroupsFound = true;
            totalDatos = 0;
            totalPaginas = 1;
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
        });
      }
    }
  }

  Future<void> obtenerUsuariosCampo() async {
    setState(() => _isLoadingUsuarios = true);
    final response = await _apiService.get<List<Usuario>>(
      '/api/v1/usuarios/tipo/campo',
      parser: (json) => (json as List).map((e) => Usuario.fromJson(e)).toList(),
      showErrorDialog: false,
    );
    if (mounted && response.success) {
      setState(() {
        _usuarios = response.data ?? [];
        _configuracionesFiltros
            .firstWhere((c) => c.clave == 'asesor')
            .opciones = _usuarios.map((u) => u.nombreCompleto).toList();
        _isLoadingUsuarios = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingUsuarios = false);
    }
  }

  void _loadMoreData() {
    if (currentPage < totalPaginas && !_isLoadingMore) {
      if (_isSearching && _currentSearchQuery.isNotEmpty) {
        searchGrupos(
          _currentSearchQuery,
          page: currentPage + 1,
          loadMore: true,
        );
      } else {
        obtenerGrupos(page: currentPage + 1, loadMore: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    currentPage = 1;
    totalPaginas = 1;
    totalDatos = 0;
    listaGrupos.clear();
    listaFiltrada.clear();
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      await searchGrupos(_currentSearchQuery, page: 1);
    } else {
      await obtenerGrupos(page: 1);
    }
  }

  Future<void> _eliminarGrupo(String idGrupo) async {
    bool? confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Grupo'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este grupo? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmado != true) return;

    try {
      final response = await _grupoService.eliminarGrupoCompleto(idGrupo);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo eliminado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        obtenerGrupos();
      } else {
        _apiService.showErrorDialog(
          response.error ?? "Ocurrió un error al intentar eliminar el grupo.",
        );
      }
    } catch (e) {
      _apiService.showErrorDialog("Error de conexión: $e");
    }
  }

  void _onSearchChanged(String query) {
    _currentSearchQuery = query;
    _isSearching = query.trim().isNotEmpty;
    if (_isSearching) {
      searchGrupos(query);
    } else {
      obtenerGrupos();
    }
  }
  
  // --- 3. NUEVOS MÉTODOS PARA CONTROL DE LAYOUT (COPIADOS DE CREDITOS) ---
  
  Widget _buildLayoutControlButton(BuildContext context, dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final uiProvider = Provider.of<UiProvider>(context); // Leer Provider Global
    final isDarkMode = themeProvider.isDarkMode;

    final currentCount = uiProvider.crossAxisCount;

    IconData iconData;
    if (currentCount == null || currentCount > 1) {
      iconData = Icons.grid_view_rounded;
    } else {
      iconData = Icons.view_list_rounded;
    }

    final Color backgroundColor = _isButtonHovered
        ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200)
        : themeProvider.colors.backgroundCard;

    final List<BoxShadow> boxShadow = [
      BoxShadow(
        color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(
          _isButtonHovered ? 0.15 : 0.1,
        ),
        blurRadius: _isButtonHovered ? 12 : 8,
        offset: Offset(0, _isButtonHovered ? 4 : 2),
      ),
    ];

    return PopupMenuButton<int>(
      tooltip: '',
      offset: const Offset(0, 35),
      onSelected: (int value) {
        // Llamamos al método global del Provider
        uiProvider.setCrossAxisCount(value);
      },
      color: colors.backgroundPrimary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isButtonHovered = true),
        onExit: (_) => setState(() => _isButtonHovered = false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3),
              width: 1.3,
            ),
            boxShadow: boxShadow,
          ),
          child: Icon(
            iconData,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupMenuItem(1, '1 Columna', Icons.view_list_rounded, colors, currentCount),
        _buildPopupMenuItem(2, '2 Columnas', Icons.grid_view_rounded, colors, currentCount),
        _buildPopupMenuItem(3, '3 Columnas', Icons.view_quilt_rounded, colors, currentCount),
        const PopupMenuDivider(),
        _buildPopupMenuItem(0, 'Automático', Icons.dynamic_feed_rounded, colors, currentCount),
      ],
    );
  }

  PopupMenuItem<int> _buildPopupMenuItem(
    int value,
    String text,
    IconData icon,
    dynamic colors,
    int? currentCount,
  ) {
    final bool isSelected = (currentCount == value) || 
                            (currentCount == null && value == 0);

    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. MÉTODO BUILD ACTUALIZADO ---
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    // Obtenemos el provider para pasar el valor a la lista
    final uiProvider = Provider.of<UiProvider>(context);

    return ResponsiveScaffoldListView<Grupo>(
      // Datos y Estado
      items: listaGrupos,
      isLoading: isLoading,
      isLoadingMore: _isLoadingMore,
      hasError: errorDeConexion,
      noItemsFound: noGroupsFound,
      totalItems: totalDatos,
      currentPage: currentPage,
      totalPages: totalPaginas,
      scrollController: _scrollController,
      // ¡Mira qué limpio queda esto!
  userSelectedCrossAxisCount: Provider.of<UiProvider>(context).crossAxisCount,
  layoutControlButton: const GlobalLayoutButton(), 

      // Resto de la configuración
      actionBarContent: _buildStatusFiltersChips(colors),
      cardHeight: 180,
      
      // Builders
      cardBuilder: (context, grupo) => _buildStandardGroupCard(grupo, colors),
      tableRowCardBuilder: (context, grupo) => _buildTableRowGroupCard(grupo, colors),

      // Acciones
      onRefresh: _onRefresh,
      onLoadMore: _loadMoreData,
      onSearchChanged: _onSearchChanged,
      onAddItem: _agregarGrupo,

      // Widgets barra superior
      filterButton: _buildFilterButton(context),
      sortButton: _buildSortButton(context, colors),

      // Textos
      searchHintText: 'Buscar por nombre...',
      addItemText: 'Agregar Grupo',
      loadingText: 'Cargando grupos...',
      emptyStateTitle: 'No se encontraron grupos',
      emptyStateSubtitle: 'Aún no hay grupos registrados. ¡Agrega uno!',
      emptyStateIcon: Icons.group_off_rounded,
      
      animationController: _animationController,
      fadeAnimation: _fadeAnimation,
      fabHeroTag: 'fab_grupos',
    );
  }

  // ... (El resto de tus métodos: _buildStandardGroupCard, _buildTableRowGroupCard, 
  // _showModernGrupoDetails, _agregarGrupo, _editarGrupo, etc. se mantienen EXACTAMENTE IGUAL)
  
  // SOLO PEGARÉ LOS CARD BUILDERS PARA QUE NO HAYA ERRORES AL COPIAR EL ARCHIVO COMPLETO
  
  Widget _buildStandardGroupCard(Grupo grupo, dynamic colors) {
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
          onTap: () => _showModernGrupoDetails(grupo.idgrupos, grupo.nombreGrupo),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        grupo.tipoGrupo,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildPopupMenu(grupo, colors),
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
                                grupo.nombreGrupo,
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
                                DateFormatters.formatearFechaRelativa(grupo.fCreacion),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildModernStatusChip(grupo.estado),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.person_pin_rounded, color: Colors.teal, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            grupo.asesor ?? 'Sin asesor',
                            style: TextStyle(color: colors.textPrimary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Icon(Icons.info_outline_rounded, color: Colors.blueGrey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          grupo.detalles.isNotEmpty ? grupo.detalles : 'Sin detalles',
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
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

  Widget _buildTableRowGroupCard(Grupo grupo, dynamic colors) {
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
          onTap: () => _showModernGrupoDetails(grupo.idgrupos, grupo.nombreGrupo),
          hoverColor: colors.textPrimary.withOpacity(0.04),
          splashColor: colors.textPrimary.withOpacity(0.08),
          highlightColor: colors.textPrimary.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          grupo.tipoGrupo,
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        grupo.nombreGrupo,
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
                        DateFormatters.formatearFechaRelativa(grupo.fCreacion),
                        style: TextStyle(color: colors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(indent: 8, endIndent: 8),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person_pin_rounded, color: Colors.teal, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                grupo.asesor ?? 'Sin asesor',
                                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.blueGrey, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                grupo.detalles.isNotEmpty ? grupo.detalles : 'Sin detalles',
                                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildModernStatusChip(grupo.estado),
                const SizedBox(width: 10),
                _buildPopupMenu(grupo, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES Y DIÁLOGOS (Mantener los existentes) ---

  void _showModernGrupoDetails(String idGrupo, String nombreGrupo) {
    final fullScreenWidth = MediaQuery.of(context).size.width;
    const double mobileBreakpoint = 600.0;
    double dialogMaxWidth;

    if (fullScreenWidth < mobileBreakpoint) {
      dialogMaxWidth = fullScreenWidth;
    } else {
      dialogMaxWidth = fullScreenWidth * 0.8;
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
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: GrupoDetalleDialog(
              idGrupo: idGrupo,
              nombreGrupo: nombreGrupo,
              onGrupoRenovado: _onRefresh,
              onEstadoCambiado: _onRefresh,
            ),
          ),
        );
      },
    );
  }
  
  void _agregarGrupo() {
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
              dialogMaxWidth = screenWidth * 0.8;
              if (dialogMaxWidth > 1200) dialogMaxWidth = 1200;
              dialogMaxHeight = screenHeight * 0.92;
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
                    child: nGrupoForm(onGrupoAgregado: _onRefresh),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarGrupo(Grupo grupo) {
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
              dialogMaxWidth = screenWidth * 0.8;
              if (dialogMaxWidth > 1200) dialogMaxWidth = 1200;
              dialogMaxHeight = screenHeight * 0.92;
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
                    child: EditarGrupoForm(
                      idGrupo: grupo.idgrupos,
                      onGrupoEditado: _onRefresh,
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

  // --- FILTROS Y ORDENAMIENTO (MÉTODOS HELPER) ---

  Widget _buildFilterButton(BuildContext context) => buildFilterButtonMobile(
    context,
    _filtrosActivos,
    _configuracionesFiltros,
    (filtros) {
      setState(() => _filtrosActivos = Map.from(filtros));
      _aplicarFiltrosYOrdenamiento();
    },
    () {
      setState(() => _filtrosActivos.clear());
      _aplicarFiltrosYOrdenamiento();
    },
  );

  void _aplicarFiltrosYOrdenamiento() {
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      searchGrupos(_currentSearchQuery, page: 1);
    } else {
      obtenerGrupos(page: 1);
    }
  }

  String _buildFilterQuery() {
    List<String> params = [];
    if (_estadoGrupoSeleccionadoFiltroAPI != null)
      params.add('estado=${Uri.encodeComponent(_estadoGrupoSeleccionadoFiltroAPI!)}');
    _filtrosActivos.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty)
        params.add('$key=${Uri.encodeComponent(value.toString())}');
    });
    return params.join('&');
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
    int activeFilterCount = filtrosActivos.entries.where((entry) {
      return entry.value != null && entry.value.toString().toLowerCase() != 'todos';
    }).length;

    return HoverableActionButton(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return FiltrosGenericosMobile(
                configuraciones: configuracionesFiltros,
                valoresIniciales: Map.from(filtrosActivos),
                titulo: 'Filtros de Grupos',
                onAplicar: onAplicarFiltros,
                onRestablecer: onRestablecerFiltros,
              );
            },
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_list_rounded, size: 22, color: isDarkMode ? Colors.white : Colors.black87),
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

  Widget _buildSortButton(BuildContext context, dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedFieldInfo = _getSelectedFieldInfo();

    return HoverableActionButton(
      onTap: () {
        _showSortOptionsUsingGenericWidget(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedFieldInfo != null ? selectedFieldInfo['icon'] : Icons.tune,
            size: 20,
            color: _sortColumnKey != null
                ? Colors.blueAccent
                : (isDarkMode ? Colors.white : Colors.black87),
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
  }
  
  Widget _buildModernStatusChip(String estado) {
    final statusConfig = {
      'Activo': {'color': Colors.green, 'icon': Icons.check_circle_outline_rounded},
      'Disponible': {'color': Colors.blue, 'icon': Icons.circle_outlined},
      'Inactivo': {'color': Colors.red, 'icon': Icons.cancel_outlined},
      'Liquidado': {'color': Colors.purple, 'icon': Icons.paid_outlined},
      'Finalizado': {'color': Colors.grey[600], 'icon': Icons.flag_circle_outlined},
      'default': {'color': Colors.grey, 'icon': Icons.info_outline_rounded},
    };
    final config = statusConfig[estado] ?? statusConfig['default']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;
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
            estado,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusFiltersChips(dynamic colors) {
    final estados = ['Todos', 'Activo', 'Disponible', 'Liquidado', 'Inactivo'];
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: estados.map((estado) {
          final isSelected = (_estadoGrupoSeleccionadoFiltroAPI == null && estado == 'Todos') ||
              (_estadoGrupoSeleccionadoFiltroAPI == estado);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(estado, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _estadoGrupoSeleccionadoFiltroAPI = estado == 'Todos' ? null : estado);
                  _aplicarFiltrosYOrdenamiento();
                }
              },
              backgroundColor: themeProvider.colors.backgroundCard,
              selectedColor: Colors.blue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.blue : (themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3)),
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
  
  PopupMenuButton<String> _buildPopupMenu(Grupo grupo, dynamic colors) => PopupMenuButton<String>(
        offset: const Offset(0, 40),
        color: colors.backgroundPrimary,
        icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 24),
        onSelected: (value) {
          if (value == 'editar') _editarGrupo(grupo);
          if (value == 'eliminar') _eliminarGrupo(grupo.idgrupos);
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'editar',
            child: Row(children: const [Icon(Icons.edit_outlined, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Editar')]),
          ),
          PopupMenuItem<String>(
            value: 'eliminar',
            child: Row(children: const [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 12), Text('Eliminar')]),
          ),
        ],
      );

  Map<String, dynamic>? _getSelectedFieldInfo() {
    if (_sortColumnKey == null) return null;
    for (var entry in _sortableFieldsWithTypes.entries) {
      if (entry.value['api_key'] == _sortColumnKey) {
        return {'display_name': entry.key, 'type': entry.value['type'], 'icon': entry.value['icon']};
      }
    }
    return null;
  }
  
  String? _getCurrentSortFieldDisplayName() {
    if (_sortColumnKey == null) return null;
    for (var entry in _sortableFieldsWithTypes.entries) {
      if (entry.value['api_key'] == _sortColumnKey) return entry.key;
    }
    return null;
  }
  
  String? _getFieldTypeForSortableField(String? fieldDisplayName) {
    if (fieldDisplayName == null || fieldDisplayName == 'Ninguno') return null;
    return _sortableFieldsWithTypes[fieldDisplayName]?['type'];
  }
  
  Map<String, String> _getDirectionDisplayLabels(String? fieldType) {
    String ascText = 'Ascendente';
    String descText = 'Descendente';
    switch (fieldType) {
      case 'date': ascText += ' (más antiguo primero)'; descText += ' (más reciente primero)'; break;
      case 'text': ascText += ' (A-Z)'; descText += ' (Z-A)'; break;
      default: ascText += ' (A-Z)'; descText += ' (Z-A)'; break;
    }
    return {'Ascendente': ascText, 'Descendente': descText};
  }
  
  void _showSortOptionsUsingGenericWidget(BuildContext context) {
    final List<String> camposOrdenamiento = ['Ninguno', ..._sortableFieldsWithTypes.keys];
    final String? initialSortFieldDisplayName = _getCurrentSortFieldDisplayName();
    final String? initialFieldType = _getFieldTypeForSortableField(initialSortFieldDisplayName);
    final Map<String, String> initialDirectionDisplayLabels = _getDirectionDisplayLabels(initialFieldType);
    List<String> initialOpcionesDireccionConDescripcion = initialDirectionDisplayLabels.values.toList();
    String? initialDirectionValue;

    if (_sortColumnKey != null) {
      initialDirectionValue = _sortAscending
          ? initialDirectionDisplayLabels['Ascendente']
          : initialDirectionDisplayLabels['Descendente'];
      if (!initialOpcionesDireccionConDescripcion.contains(initialDirectionValue)) {
        initialDirectionValue = null;
      }
    } else {
      initialDirectionValue = null;
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
      builder: (modalContext) => DraggableScrollableSheet(
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
                onValorCambiado: (String claveCampoCambiado, dynamic nuevoValor) {
                  modalSetState(() {
                    currentValoresOrdenamiento[claveCampoCambiado] = nuevoValor;
                    if (claveCampoCambiado == _keySortColumnConfig) {
                      final String? nuevoCampoOrdenamiento = nuevoValor as String?;
                      final String? nuevoTipoCampo = _getFieldTypeForSortableField(nuevoCampoOrdenamiento);
                      final Map<String, String> nuevasEtiquetasDireccion = _getDirectionDisplayLabels(nuevoTipoCampo);
                      final List<String> nuevasOpcionesDireccion = nuevasEtiquetasDireccion.values.toList();
                      int directionConfigIndex = currentConfigsOrdenamiento.indexWhere((c) => c.clave == _keySortDirectionConfig);
                      if (directionConfigIndex != -1) {
                        currentConfigsOrdenamiento[directionConfigIndex] = ConfiguracionOrdenamiento(
                          clave: _keySortDirectionConfig,
                          titulo: "Dirección",
                          tipo: TipoOrdenamiento.dropdown,
                          opciones: nuevasOpcionesDireccion,
                          hintText: 'Selecciona dirección',
                        );
                      }
                      currentValoresOrdenamiento[_keySortDirectionConfig] = null;
                    }
                  });
                },
                onAplicar: (valoresAplicados) {
                  final String? nuevoCampoDisplayName = valoresAplicados[_keySortColumnConfig];
                  final String? nuevaDireccionConDescripcion = valoresAplicados[_keySortDirectionConfig];
                  bool esAscendente = true;
                  if (nuevaDireccionConDescripcion != null) {
                    final String? tipoDeCampoActual = _getFieldTypeForSortableField(nuevoCampoDisplayName);
                    final Map<String, String> etiquetasDireccionActuales = _getDirectionDisplayLabels(tipoDeCampoActual);
                    for (var entry in etiquetasDireccionActuales.entries) {
                      if (entry.value == nuevaDireccionConDescripcion) {
                        esAscendente = (entry.key == 'Ascendente');
                        break;
                      }
                    }
                  } else if (nuevoCampoDisplayName == null || nuevoCampoDisplayName == 'Ninguno') {
                    esAscendente = true;
                  }
                  _sortAscending = esAscendente;
                  if (nuevoCampoDisplayName != null && nuevoCampoDisplayName != 'Ninguno') {
                    _sortColumnKey = _sortableFieldsWithTypes[nuevoCampoDisplayName]!['api_key'];
                  } else {
                    _sortColumnKey = null;
                    _sortAscending = true;
                  }
                  _aplicarFiltrosYOrdenamiento();
                  Navigator.pop(context);
                },
                onRestablecer: () {
                  modalSetState(() {
                    _sortColumnKey = null;
                    _sortAscending = true;
                    currentValoresOrdenamiento[_keySortColumnConfig] = 'Ninguno';
                    currentValoresOrdenamiento[_keySortDirectionConfig] = null;
                    final String? defaultFieldType = _getFieldTypeForSortableField('Ninguno');
                    final Map<String, String> defaultDirectionLabels = _getDirectionDisplayLabels(defaultFieldType);
                    final List<String> defaultDirectionOptions = defaultDirectionLabels.values.toList();
                    int directionConfigIndex = currentConfigsOrdenamiento.indexWhere((c) => c.clave == _keySortDirectionConfig);
                    if (directionConfigIndex != -1) {
                      currentConfigsOrdenamiento[directionConfigIndex] = ConfiguracionOrdenamiento(
                        clave: _keySortDirectionConfig,
                        titulo: "Dirección",
                        tipo: TipoOrdenamiento.dropdown,
                        opciones: defaultDirectionOptions,
                        hintText: 'Selecciona dirección',
                      );
                    }
                  });
                  _aplicarFiltrosYOrdenamiento();
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}