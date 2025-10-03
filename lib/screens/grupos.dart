// Archivo: lib/screens/grupos_screen_mobile.dart

import 'dart:async';
import 'dart:math';
import 'package:finora_app/dialog/grupo_detalle_dialog.dart';
import 'package:finora_app/forms/edit_grupo_form.dart';
import 'package:finora_app/forms/ngrupo_form.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/grupo_service.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/widgets/filtros_genericos_widget.dart';
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
  // --- Variables de estado (sin cambios en su mayoría) ---
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
  // --- Fin de variables de estado ---

  // --- VERSIÓN ACTUALIZADA CON ANIMACIÓN DE SUBIDA Y DISEÑO RESPONSIVO ---
  // Archivo: lib/screens/grupos_screen_mobile.dart

  // Archivo: lib/screens/grupos_screen_mobile.dart

  void _showModernGrupoDetails(String idGrupo, String nombreGrupo) {
    // Obtenemos el ancho total de la pantalla ANTES de llamar al BottomSheet.
    final fullScreenWidth = MediaQuery.of(context).size.width;

    // Definimos las constantes y calculamos el ancho del diálogo aquí mismo.
    const double mobileBreakpoint = 600.0; // Breakpoint para Grupos
    double dialogMaxWidth;

    if (fullScreenWidth < mobileBreakpoint) {
      // En móvil, el diálogo ocupa todo el ancho.
      dialogMaxWidth = fullScreenWidth;
    } else {
      // --- EN ESCRITORIO ---
      // ¡ESTE ES EL ÚNICO NÚMERO QUE DEBES AJUSTAR!
      // Define el ancho como un porcentaje de la pantalla.
      dialogMaxWidth =
          fullScreenWidth * 0.8; // <-- Cambia este valor si lo necesitas
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Usamos la propiedad `constraints` para pasar el ancho calculado.
      constraints: BoxConstraints(maxWidth: dialogMaxWidth),
      builder: (context) {
        // El builder ahora solo se preocupa por el contenido vertical.
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // La altura máxima se sigue controlando aquí.
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            child: GrupoDetalleDialog(
              idGrupo: idGrupo,
              nombreGrupo: nombreGrupo,
              onGrupoRenovado: _onRefresh,
              // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
              // Le pasamos la misma función que usamos para renovar.
              onEstadoCambiado: _onRefresh,
            ),
          ),
        );
      },
    );
  }

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

  static const String _keySortColumnConfig = 'sort_by_column_config_key';
  static const String _keySortDirectionConfig = 'sort_direction_config_key';

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
      showErrorDialog: false, // <--- ¡AÑADE ESTA LÍNEA!
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
    // 1. Diálogo de confirmación (se mantiene igual, es buena práctica)
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

    if (confirmado != true) {
      return; // El usuario canceló
    }

    // Muestra un indicador de carga si lo deseas
    // setState(() => _isDeleting = true);

    try {
      // 2. UNA SOLA LLAMADA al servicio para eliminar todo
      final response = await _grupoService.eliminarGrupoCompleto(idGrupo);

      if (!mounted) return;

      // 3. Manejar la respuesta
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo eliminado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        // Actualiza tu lista de grupos para reflejar el cambio
        obtenerGrupos();
      } else {
        // El ApiService ya debería mostrar un diálogo de error
        // con el mensaje que viene del backend.
        // Pero si quieres un mensaje por defecto, puedes añadirlo aquí.
        _apiService.showErrorDialog(
          response.error ?? "Ocurrió un error al intentar eliminar el grupo.",
        );
      }
    } catch (e) {
      // Para errores de programación o de red no manejados por ApiService
      _apiService.showErrorDialog("Error de conexión: $e");
    } finally {
      // Oculta el indicador de carga
      // if(mounted) setState(() => _isDeleting = false);
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

  // --- EL MÉTODO BUILD AHORA ES SÚPER SIMPLE ---
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    // Solo devolvemos nuestro widget reutilizable, pasándole toda la lógica.
    return ResponsiveScaffoldListView<Grupo>(
      // --- Datos y Estado ---
      items: listaGrupos,
      isLoading: isLoading,
      isLoadingMore: _isLoadingMore,
      hasError: errorDeConexion,
      noItemsFound: noGroupsFound,
      totalItems: totalDatos,
      currentPage: currentPage,
      totalPages: totalPaginas,
      scrollController: _scrollController,
      // --- ¡AQUÍ PASAMOS LOS WIDGETS FALTANTES! ---
      actionBarContent: _buildStatusFiltersChips(colors),
      cardHeight:
          180, // Ajusta esta altura para que coincida con tu diseño de tarjeta
      // --- Builders para las tarjetas ---
      // --- Builders para las tarjetas (ACTUALIZADOS) ---
      cardBuilder: (context, grupo) => _buildStandardGroupCard(grupo, colors),
      tableRowCardBuilder:
          (context, grupo) => _buildTableRowGroupCard(grupo, colors),

      // --- Callbacks para acciones ---
      onRefresh: _onRefresh,
      onLoadMore: _loadMoreData,
      onSearchChanged: _onSearchChanged,
      onAddItem: _agregarGrupo,

      // --- Widgets de la barra de acciones ---
      filterButton: _buildFilterButton(context),
      sortButton: _buildSortButton(context, colors),

      // --- Textos personalizables ---
      //appBarTitle: 'Grupos',
      searchHintText: 'Buscar por nombre...',
      addItemText: 'Agregar Grupo',
      loadingText: 'Cargando grupos...',
      emptyStateTitle: 'No se encontraron grupos',
      emptyStateSubtitle: 'Aún no hay grupos registrados. ¡Agrega uno!',
      emptyStateIcon: Icons.group_off_rounded,
      // 5. PASA LOS CONTROLADORES DE ANIMACIÓN
      animationController: _animationController,
      fadeAnimation: _fadeAnimation,
      fabHeroTag: 'fab_grupos', // Etiqueta única para grupos
    );
  }

  /// Construye la tarjeta vertical estándar para un grupo.
  /// Construye la tarjeta vertical estándar para un grupo (DISEÑO COMPLETO).
  // Archivo: lib/screens/grupos_screen_mobile.dart

  // REEMPLAZA ESTE MÉTODO COMPLETO
  /// Construye la tarjeta vertical estándar para un grupo (CORREGIDA).
  Widget _buildStandardGroupCard(Grupo grupo, dynamic colors) {
    return Container(
      // El Container y el InkWell se mantienen igual
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
          onTap:
              () => _showModernGrupoDetails(grupo.idgrupos, grupo.nombreGrupo),
          child: Padding(
            padding: const EdgeInsets.all(20),
            // --- ¡AQUÍ ESTÁ EL CAMBIO PRINCIPAL! ---
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // 1. Usamos `spaceBetween` para distribuir el espacio verticalmente.
              // Esto empujará el primer hijo hacia arriba y el último hacia abajo.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PRIMER HIJO: Fila superior (Tag y Menú)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
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
                    const Spacer(), // Spacer en una Row está bien porque el ancho SÍ es finito.
                    _buildPopupMenu(grupo, colors),
                  ],
                ),

                // 2. HEMOS QUITADO EL SPACER DE AQUÍ.

                // ÚLTIMO HIJO: Agrupamos todo el contenido inferior en otra Column.
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
                                DateFormatters.formatearFechaRelativa(
                                  grupo.fCreacion,
                                ),
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
                    // CÓDIGO CORREGIDO Y MÁS SIMPLE
                    Row(
                      children: [
                        // --- Elementos de la Izquierda ---
                        Icon(
                          Icons.person_pin_rounded,
                          color: Colors.teal,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          // <--- ¡LA MAGIA ESTÁ AQUÍ!
                          child: Text(
                            grupo.asesor ?? 'Sin asesor',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                            overflow:
                                TextOverflow.ellipsis, // Ahora sí funcionará
                            maxLines: 1, // Buena práctica añadir esto
                          ),
                        ),

                        // --- Elementos de la Derecha ---
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blueGrey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          grupo.detalles.isNotEmpty
                              ? grupo.detalles
                              : 'Sin detalles',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
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

  // Y como tu _buildTableRowGroupCard llama a este, el error se soluciona en ambos lados.
  // AÑADE ESTE MÉTODO A TU CLASE _GruposScreenMobileState
  /// Construye la tarjeta horizontal (fila) para un grupo.
  /// Construye la tarjeta horizontal (fila) para un grupo.
  /// Construye la tarjeta horizontal (fila) para un grupo.
  Widget _buildTableRowGroupCard(Grupo grupo, dynamic colors) {
    // El Container, Material e InkWell se mantienen igual.
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
          onTap:
              () => _showModernGrupoDetails(grupo.idgrupos, grupo.nombreGrupo),
          hoverColor: colors.textPrimary.withOpacity(0.04),
          splashColor: colors.textPrimary.withOpacity(0.08),
          highlightColor: colors.textPrimary.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
                // Sección 1: Etiqueta, Nombre y Fecha
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // AÑADIMOS LA ETIQUETA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      const SizedBox(
                        height: 8,
                      ), // Espacio entre etiqueta y nombre
                      // Nombre y fecha (sin cambios)
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
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(indent: 8, endIndent: 8),

                // Sección 2: Asesor y Detalles
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_pin_rounded,
                              color: Colors.teal,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                grupo.asesor ?? 'Sin asesor',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blueGrey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                grupo.detalles.isNotEmpty
                                    ? grupo.detalles
                                    : 'Sin detalles',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                ),
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

                // Sección 3: Estado y Menú de opciones
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

  // --- ¡ASEGÚRATE DE QUE ESTOS MÉTODOS ESTÉN PRESENTES EN TU CLASE! ---

  Widget _buildStatusFiltersChips(dynamic colors) {
    final estados = [
      'Todos',
      'Activo',
      'Disponible',
      'Liquidado',
      // 'Finalizado',
      'Inactivo',
    ];
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            estados.map((estado) {
              final isSelected =
                  (_estadoGrupoSeleccionadoFiltroAPI == null &&
                      estado == 'Todos') ||
                  (_estadoGrupoSeleccionadoFiltroAPI == estado);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  showCheckmark: false,
                  label: Text(estado, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                        () =>
                            _estadoGrupoSeleccionadoFiltroAPI =
                                estado == 'Todos' ? null : estado,
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
                  // --- AQUÍ LA SOLUCIÓN ---
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // <-- AÑADIDO
                  visualDensity: VisualDensity.compact, // <-- AÑADIDO
                ),
              );
            }).toList(),
      ),
    );
  }

  // --- Widgets y métodos de ayuda específicos de la pantalla de Grupos ---

  PopupMenuButton<String> _buildPopupMenu(Grupo grupo, dynamic colors) =>
      PopupMenuButton<String>(
        offset: const Offset(0, 40),
        color: colors.backgroundPrimary,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: colors.textSecondary,
          size: 24,
        ),
        onSelected: (value) {
          if (value == 'editar') _editarGrupo(grupo);
          if (value == 'eliminar') _eliminarGrupo(grupo.idgrupos);
        },
        itemBuilder:
            (context) => [
              PopupMenuItem<String>(
                value: 'editar',
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
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
      case 'date':
        ascText += ' (más antiguo primero)';
        descText += ' (más reciente primero)';
        break;
      case 'text':
        ascText += ' (A-Z)';
        descText += ' (Z-A)';
        break;
      default:
        ascText += ' (A-Z)';
        descText += ' (Z-A)';
        break;
    }
    return {'Ascendente': ascText, 'Descendente': descText};
  }

  void _showSortOptionsUsingGenericWidget(BuildContext context) {
    // Este método tampoco necesita cambios, ya que se basa en las configuraciones
    // que ya hemos adaptado.
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
        initialDirectionDisplayLabels.values.toList();
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
                              nuevasEtiquetasDireccion.values.toList();
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
                      } else if (nuevoCampoDisplayName == null ||
                          nuevoCampoDisplayName == 'Ninguno') {
                        esAscendente = true;
                      }
                      _sortAscending = esAscendente;
                      if (nuevoCampoDisplayName != null &&
                          nuevoCampoDisplayName != 'Ninguno') {
                        _sortColumnKey =
                            _sortableFieldsWithTypes[nuevoCampoDisplayName]!['api_key'];
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
                        currentValoresOrdenamiento[_keySortColumnConfig] =
                            'Ninguno';
                        currentValoresOrdenamiento[_keySortDirectionConfig] =
                            null;
                        final String? defaultFieldType =
                            _getFieldTypeForSortableField('Ninguno');
                        final Map<String, String> defaultDirectionLabels =
                            _getDirectionDisplayLabels(defaultFieldType);
                        final List<String> defaultDirectionOptions =
                            defaultDirectionLabels.values.toList();
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

  Widget _buildSortButton(BuildContext context, dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedFieldInfo = _getSelectedFieldInfo();

    // Reemplazamos toda la estructura anterior por nuestro nuevo widget
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
            color:
                _sortColumnKey != null
                    ? Colors.blueAccent
                    : (isDarkMode ? Colors.white : Colors.black87),
          ),
          if (_sortColumnKey != null) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
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
      'Activo': {
        'color': Colors.green,
        'icon': Icons.check_circle_outline_rounded,
      },
      'Disponible': {'color': Colors.blue, 'icon': Icons.circle_outlined},
      'Inactivo': {'color': Colors.red, 'icon': Icons.cancel_outlined},
      'Liquidado': {'color': Colors.purple, 'icon': Icons.paid_outlined},
      'Finalizado': {
        'color': Colors.grey[600],
        'icon': Icons.flag_circle_outlined,
      },
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

  // --- NUEVO MÉTODO PARA AGREGAR GRUPO ---
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
              // --- LÓGICA MÓVIL ---
              dialogMaxWidth = screenWidth;
              dialogMaxHeight =
                  screenHeight * 0.95; // Ocupa casi toda la altura
            } else {
              // --- LÓGICA DESKTOP ---
              dialogMaxWidth = screenWidth * 0.8;
              if (dialogMaxWidth > 1200) {
                dialogMaxWidth = 1200;
              }
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
                    // ¡AQUÍ ESTÁ LA MAGIA! Llamamos a tu formulario de nuevo grupo.
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

  // --- NUEVO MÉTODO PARA EDITAR GRUPO ---
  void _editarGrupo(Grupo grupo) {
    // Copiamos la misma lógica para mantener la coherencia visual.
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
              if (dialogMaxWidth > 1200) {
                dialogMaxWidth = 1200;
              }
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
                    // ¡AQUÍ ESTÁ LA MAGIA! Llamamos a tu formulario de edición.
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
      params.add(
        'estado=${Uri.encodeComponent(_estadoGrupoSeleccionadoFiltroAPI!)}',
      );
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

    int activeFilterCount =
        filtrosActivos.entries.where((entry) {
          return entry.value != null &&
              entry.value.toString().toLowerCase() != 'todos';
        }).length;

    return HoverableActionButton(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (modalContext) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return FiltrosGenericosMobile(
                    configuraciones: configuracionesFiltros,
                    valoresIniciales: Map.from(filtrosActivos),
                    // ADAPTADO: Título del modal de filtros.
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

  //</editor-fold>
}
