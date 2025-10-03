// ADAPTADO: Nuevo archivo para la gestión de Clientes.

// Asegúrate de importar los widgets y modelos necesarios
import 'dart:async';
import 'package:finora_app/dialog/cliente_detalle_dialog.dart';
import 'package:finora_app/forms/edit_cliente_form.dart';
import 'package:finora_app/forms/ncliente_form.dart';
import 'package:finora_app/models/clientes.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/cliente_service.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/widgets/filtros_genericos_widget.dart';
import 'package:finora_app/widgets/hoverableActionButton.dart';
import 'package:finora_app/widgets/ordenamiento_genericos.dart';
import 'package:finora_app/widgets/responsive_scaffold_list_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finora_app/ip.dart';
import '../utils/app_logger.dart';


// ADAPTADO: Se renombra la clase principal del widget.
class ClientesScreenMobile extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const ClientesScreenMobile({
    super.key,
    required this.username,
    required this.tipoUsuario,
  });

  @override
  _ClientesScreenMobileState createState() => _ClientesScreenMobileState();
}

// ADAPTADO: Se renombra la clase de estado.
class _ClientesScreenMobileState extends State<ClientesScreenMobile>
    with TickerProviderStateMixin {
  // ADAPTADO: Se cambian las listas y variables de 'Grupo' a 'Cliente'.
  List<Cliente> listaClientes = [];
  List<Cliente> listaFiltrada = [];
  bool isLoading = false;
  bool errorDeConexion = false;
  bool noItemsFound = false; // Renombrado de noGroupsFound
  String _searchQuery = '';
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final ClienteService _clienteService = ClienteService(); // <-- AÑADE ESTA LÍNEA
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String errorMessage = '';

  int currentPage = 1;
  int totalPaginas = 1;
  int totalDatos = 0;

  String _currentSearchQuery = '';
  bool _isSearching = false;

  String? _sortColumnKey;
  bool _sortAscending = true;

  Map<String, dynamic> _filtrosActivos = {};
  late List<ConfiguracionFiltro> _configuracionesFiltros;

  // ADAPTADO: Se cambia el filtro de estado para clientes.
  String? _estadoClienteSeleccionadoFiltroAPI = null;

  // ADAPTADO: Se elimina la lógica para cargar usuarios/asesores ya que el modelo Cliente no lo incluye.

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

  static const String _keySortColumnConfig = 'sort_by_column_config_key';
  static const String _keySortDirectionConfig = 'sort_direction_config_key';

   @override
  void initState() {
    super.initState();
    isLoading = true; // Iniciar en estado de carga

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializarFiltros();

    // ¡¡¡CORRECCIÓN PRINCIPAL AQUÍ!!!
    // Añadimos el listener al ScrollController para detectar el final de la lista.
    _scrollController.addListener(() {
      // Si el usuario está cerca del final de la lista (a 300px), cargamos más datos.
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMoreData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _apiService.setContext(context);
        _fetchData(page: 1); // Llamada inicial para cargar los datos
      }
    });
  }

  // ADAPTADO: Se actualizan las configuraciones de filtros para clientes.
  void _initializarFiltros() {
    _configuracionesFiltros = [
      ConfiguracionFiltro(
        clave: 'tipocliente',
        titulo: 'Tipo de Cliente',
        tipo: TipoFiltro.dropdown,
        opciones: ['Asalariado', 'Independiente', 'Comerciante', 'Jubilado'],
      ),
      ConfiguracionFiltro(
        clave: 'sexo',
        titulo: 'Sexo',
        tipo: TipoFiltro.dropdown,
        opciones: ['Masculino', 'Femenino'],
      ),
      ConfiguracionFiltro(
        clave: 'estado',
        titulo: 'Estado',
        tipo: TipoFiltro.dropdown,
        opciones: ['Disponible', 'En Credito', 'En Grupo'],
      ),
    ];
    _filtrosActivos = {
      for (var config in _configuracionesFiltros) config.clave: null,
    };
  }

  // ADAPTADO: Se actualiza el mapa de campos de ordenamiento para clientes.
  final Map<String, Map<String, dynamic>> _sortableFieldsWithTypes = {
    'Nombre': {
      'api_key': 'nombrecompleto',
      'type': 'text',
      'icon': Icons.sort_by_alpha_rounded,
    },
    'Fecha Creación': {
      'api_key': 'fCreacion',
      'type': 'date',
      'icon': Icons.calendar_today_rounded,
    },
  };

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

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

    /// NUEVO: Método centralizado para obtener datos, ya sea la lista completa o una búsqueda.
  Future<void> _fetchData({required int page, bool loadMore = false}) async {
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      await searchClientes(_currentSearchQuery, page: page, loadMore: loadMore);
    } else {
      await obtenerClientes(page: page, loadMore: loadMore);
    }
  }

  // ADAPTADO: Función renombrada y modificada para obtener Clientes.
  Future<void> obtenerClientes({int page = 1, bool loadMore = false}) async {
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

    String sortQuery = '';
    if (_sortColumnKey != null) {
      sortQuery = '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}';
    }

    String filterQuery = _buildFilterQuery();
    // ADAPTADO: Se cambia el endpoint a /clientes.
    final endpoint =
        '/api/v1/clientes?limit=24&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔄 Obteniendo clientes: $baseUrl$endpoint');

    try {
      // ADAPTADO: Se especifica el tipo Cliente para el parser.
      final response = await _apiService.get<List<Cliente>>(
        endpoint,
        parser:
            (json) =>
                (json as List).map((item) => Cliente.fromJson(item)).toList(),
      );

      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaClientes.addAll(response.data!);
              listaFiltrada.addAll(response.data!);
            } else {
              listaClientes = response.data!;
              listaFiltrada = List.from(listaClientes);
              if (listaClientes.isNotEmpty) {
                _animationController.reset();
                _animationController.forward();
              }
            }
            noItemsFound = listaClientes.isEmpty;
            errorDeConexion = false;

            if (response.headers != null) {
              totalDatos =
                  int.tryParse(
                    response.headers!['x-total-totaldatos'] ?? '0',
                  ) ??
                  0;
              totalPaginas =
                  int.tryParse(
                    response.headers!['x-total-totalpaginas'] ?? '1',
                  ) ??
                  1;
            } else {
              if (!loadMore) totalDatos = 0;
            }
          } else if (!loadMore) {
            listaClientes = [];
            listaFiltrada = [];
            noItemsFound = true;
            totalDatos = 0;
            totalPaginas = 1;
            if (!response.success &&
                response.error != null &&
                response.error!.contains("no se encontraron clientes")) {
              noItemsFound = true;
            }
          }
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.log('❌ Error inesperado obteniendo clientes: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) {
            listaClientes = [];
            listaFiltrada = [];
            totalDatos = 0;
            totalPaginas = 1;
          }
        });
      }
    }
  }

  // ADAPTADO: Función renombrada y modificada para buscar Clientes.
  Future<void> searchClientes(
    String query, {
    int page = 1,
    bool loadMore = false,
  }) async {
    _currentSearchQuery = query;
    _searchQuery = query;

    if (query.trim().isEmpty) {
      _isSearching = false;
      obtenerClientes(page: 1); // Reset
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

    String sortQuery = '';
    if (_sortColumnKey != null) {
      sortQuery = '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}';
    }

    String filterQuery = _buildFilterQuery();
    final encodedQuery = Uri.encodeComponent(query);
    // ADAPTADO: Se cambia el endpoint a /clientes/<busqueda>.
    final endpoint =
        '/api/v1/clientes/$encodedQuery?limit=24&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔍 Buscando clientes: $baseUrl$endpoint');

    try {
      // ADAPTADO: Se especifica el tipo Cliente y se actualiza el parser.
      final response = await _apiService.get<List<Cliente>>(
        endpoint,
        parser: (json) {
          if (json is List) {
            return json.map((item) => Cliente.fromJson(item)).toList();
          } else if (json is Map &&
              json.containsKey('data') &&
              json['data'] is List) {
            final data = json['data'] as List;
            return data.map((item) => Cliente.fromJson(item)).toList();
          } else {
            if (json is Map &&
                json.containsKey('message') &&
                (json['message'] as String).toLowerCase().contains(
                  'no se encontraron clientes',
                )) {
              return <Cliente>[];
            }
            AppLogger.log("Formato de respuesta inesperado en búsqueda: $json");
            return <Cliente>[];
          }
        },
        showErrorDialog: false,
      );

      if (!mounted) return;
      setState(() {
        if (response.success && response.data != null) {
          if (loadMore) {
            listaClientes.addAll(response.data!);
            listaFiltrada.addAll(response.data!);
          } else {
            listaClientes = response.data!;
            listaFiltrada = List.from(listaClientes);
            if (listaClientes.isNotEmpty) {
              _animationController.reset();
              _animationController.forward();
            }
          }
          noItemsFound = listaClientes.isEmpty;

          if (response.headers != null) {
            totalDatos =
                int.tryParse(response.headers!['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers!['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
          } else if (!loadMore) {
            totalDatos = 0;
          }
        } else if (!loadMore) {
          listaClientes = [];
          listaFiltrada = [];
          noItemsFound = true;
          totalDatos = 0;
          totalPaginas = 1;
        }
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      AppLogger.log('❌ Error inesperado en búsqueda de clientes: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) {
            listaClientes = [];
            listaFiltrada = [];
            totalDatos = 0;
            totalPaginas = 1;
          }
        });
      }
    }
  }

   
  // --- Callbacks y Acciones ---

  void _onSearchChanged(String query) {
    _currentSearchQuery = query;
    _isSearching = query.trim().isNotEmpty;
    _fetchData(page: 1);
  }

   
  Future<void> _onRefresh() async {
    await _fetchData(page: 1);
  }

    void _loadMoreData() {
    // Esta función ahora será llamada correctamente por el listener.
    if (currentPage < totalPaginas && !_isLoadingMore) {
      _fetchData(page: currentPage + 1, loadMore: true);
    }
  }

  void _aplicarFiltrosYOrdenamiento() {
    _fetchData(page: 1);
  }

  // ADAPTADO: Acción para agregar un nuevo cliente.
  // POR ESTE NUEVO MÉTODO:
  void _agregarCliente() {
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
          // Obtenemos el ancho y alto disponibles
          final screenWidth = constraints.maxWidth;
          final screenHeight = MediaQuery.of(context).size.height; // Necesitamos la altura total
          
          const double mobileBreakpoint = 768.0;
          
          // Declaramos nuestras variables dinámicas para ancho y ALTO
          double dialogMaxWidth;
          double dialogMaxHeight;

          // Aplicamos la lógica condicional
          if (screenWidth < mobileBreakpoint) {
            // ---- LÓGICA MÓVIL ----
            dialogMaxWidth = screenWidth;
            dialogMaxHeight = screenHeight * 0.95; // Ocupa toda la altura
          } else {
            // ---- LÓGICA DESKTOP ----
            dialogMaxWidth = screenWidth * 0.8;
            if (dialogMaxWidth > 1200) {
              dialogMaxWidth = 1200;
            }
            dialogMaxHeight = screenHeight * 0.92; // Ocupa el 92% de la altura
          }

          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                width: dialogMaxWidth,
                // Usamos la altura dinámica que acabamos de calcular
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: dialogMaxHeight,
                  ),
                  child: nClienteForm(onClienteAgregado: _onRefresh),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ADAPTADO: Acción para editar un cliente.
void _editarCliente(Cliente cliente) {
  // Copiamos la lógica de _agregarCliente para mantener la coherencia.
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
                  constraints: BoxConstraints(
                    maxHeight: dialogMaxHeight,
                  ),
                  // ¡ÚNICO CAMBIO IMPORTANTE!
                  // Llamamos a EditarClienteForm y le pasamos los datos necesarios.
                  child: EditarClienteForm(
                    idCliente: cliente.clienteInfo.idCliente!,
                    onClienteEditado: _onRefresh, // Usamos el callback para refrescar la lista
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



   // --- El método build ahora es SÚPER SIMPLE gracias a ResponsiveScaffoldListView ---
    // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return ResponsiveScaffoldListView<Cliente>(
      // --- Datos y Estado ---
      items: listaClientes, // Se usa la única lista de datos
      isLoading: isLoading,
      isLoadingMore: _isLoadingMore,
      hasError: errorDeConexion,
      noItemsFound: noItemsFound,
      totalItems: totalDatos,
      currentPage: currentPage,
      totalPages: totalPaginas,
      scrollController: _scrollController, // Se pasa el controlador con el listener

      // --- Builders para las tarjetas ---
      cardBuilder: (context, cliente) => _buildStandardClienteCard(cliente, colors),
      tableRowCardBuilder: (context, cliente) => _buildTableRowClienteCard(cliente, colors),
      cardHeight: 180,

      // --- Callbacks para acciones ---
      onRefresh: _onRefresh,
      onLoadMore: _loadMoreData, // El scaffold puede usarlo para un botón opcional
      onSearchChanged: _onSearchChanged,
      onAddItem: _agregarCliente,

      // --- Widgets de la barra de acciones ---
      actionBarContent: _buildStatusFiltersChips(colors),
      filterButton: _buildFilterButton(context),
      sortButton: _buildSortButton(context, colors),

      // --- Textos y animaciones personalizables ---
      appBarTitle: 'Clientes',
      searchHintText: 'Buscar por nombre, apellido...',
      addItemText: 'Agregar Cliente',
      loadingText: 'Cargando clientes...',
      emptyStateTitle: 'No se encontraron clientes',
      emptyStateSubtitle: 'Aún no hay clientes registrados. ¡Agrega uno!',
      emptyStateIcon: Icons.person_search_rounded,
      animationController: _animationController,
      fadeAnimation: _fadeAnimation,
      fabHeroTag: 'fab_clientes', // Etiqueta única para grupos
    );
  }

  
  // --- Constructores de Widgets (Cards, Filtros, etc.) ---

  // NUEVO: Tarjeta vertical para un cliente.
  Widget _buildStandardClienteCard(Cliente cliente, dynamic colors) {
    final fullName = '${cliente.clienteInfo.nombres} ${cliente.clienteInfo.apellidoP}'.trim();
    final esFemenino = cliente.clienteInfo.sexo.toLowerCase() == 'femenino';

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showClienteDetails(cliente),
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
                      decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(cliente.clienteInfo.tipoCliente, style: const TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    _buildPopupMenu(cliente, colors),
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
                              Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(DateFormatters.formatearFechaRelativa(cliente.clienteInfo.fCreacion), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        _buildClienteStatusChip(cliente.clienteInfo.estado),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoChip(Icons.phone_rounded, cliente.clienteInfo.telefono ?? 'N/A', Colors.teal, colors),
                        _buildInfoChip(esFemenino ? Icons.female_rounded : Icons.male_rounded, cliente.clienteInfo.sexo, esFemenino ? Colors.purple : Colors.blue, colors),
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

  // NUEVO: Tarjeta horizontal (fila) para un cliente.
  Widget _buildTableRowClienteCard(Cliente cliente, dynamic colors) {
    final fullName = '${cliente.clienteInfo.nombres} ${cliente.clienteInfo.apellidoP}'.trim();
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => _showClienteDetails(cliente),
          hoverColor: colors.textPrimary.withOpacity(0.04),
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
                        decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(cliente.clienteInfo.tipoCliente, style: const TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(DateFormatters.formatearFechaRelativa(cliente.clienteInfo.fCreacion), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const VerticalDivider(indent: 8, endIndent: 8),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      _buildInfoChip(Icons.phone_rounded, cliente.clienteInfo.telefono ?? 'N/A', Colors.teal, colors),
                      const SizedBox(width: 16),
                      _buildInfoChip(Icons.email_outlined, cliente.clienteInfo.email ?? 'N/A', Colors.blueGrey, colors),
                    ],
                  ),
                ),
                const Spacer(),
                _buildClienteStatusChip(cliente.clienteInfo.estado),
                const SizedBox(width: 10),
                _buildPopupMenu(cliente, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

   // --- Widgets de ayuda (Chips, Popups, etc.) ---
  
  PopupMenuButton<String> _buildPopupMenu(Cliente cliente, dynamic colors) => PopupMenuButton<String>(
    offset: const Offset(0, 40),
    color: colors.backgroundPrimary,
    icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 24),
    onSelected: (value) {
      if (value == 'editar') _editarCliente(cliente);
      if (value == 'eliminar') _eliminarCliente(cliente);
    },
    itemBuilder: (context) => [
      PopupMenuItem(value: 'editar', child: Row(children: const [Icon(Icons.edit_outlined, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Editar')])),
      PopupMenuItem(value: 'eliminar', child: Row(children: const [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 12), Text('Eliminar')])),
    ],
  );

  Widget _buildInfoChip(IconData icon, String text, Color color, dynamic colors) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis),
    ],
  );

  // ADAPTADO: Chip de estado para clientes.
  Widget _buildClienteStatusChip(String estado) {
    final statusConfig = {
      'Disponible': {'color': Colors.green, 'icon': Icons.check_circle_outline_rounded},
      'En Credito': {'color': Colors.red, 'icon': Icons.lock_outline_rounded},
      'En Grupo': {'color': Colors.orange, 'icon': Icons.group_work_outlined},
      'default': {'color': Colors.grey, 'icon': Icons.info_outline_rounded},
    };
    final config = statusConfig[estado] ?? statusConfig['default']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(estado, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  // ADAPTADO: Chips de filtro por estado para clientes.
  Widget _buildStatusFiltersChips(dynamic colors) {
    final estados = ['Todos', 'Disponible', 'En Credito', 'En Grupo'];
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SizedBox(
      height: 32,
      child: ListView( // Usar ListView aquí está bien, el problema no era este.
        scrollDirection: Axis.horizontal,
        children: estados.map((estado) {
          final isSelected = (_estadoClienteSeleccionadoFiltroAPI == null && estado == 'Todos') || (_estadoClienteSeleccionadoFiltroAPI == estado);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              showCheckmark: false,
              label: Text(estado, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _estadoClienteSeleccionadoFiltroAPI = estado == 'Todos' ? null : estado);
                  _aplicarFiltrosYOrdenamiento();
                }
              },
              backgroundColor: themeProvider.colors.backgroundCard,
              selectedColor: Colors.blue.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? Colors.blue : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700]), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.blue : (themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3)), width: isSelected ? 1.5 : 1.0),
              ),
              // --- AÑADE ESTAS DOS LÍNEAS ---
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // <-- AÑADIDO
              visualDensity: VisualDensity.compact,                   // <-- AÑADIDO
            ),
          );
        }).toList(),
      ),
    );
  }

  // ADAPTADO: Lógica para mostrar los detalles de un cliente.
  // REEMPLAZA tu método _showClienteDetails con este
// Archivo: lib/screens/clientes_screen_mobile.dart

void _showClienteDetails(Cliente cliente) {
  // Obtenemos el ancho total de la pantalla ANTES de llamar al BottomSheet.
  final fullScreenWidth = MediaQuery.of(context).size.width;

  // Definimos las constantes y calculamos el ancho del diálogo aquí mismo.
  const double mobileBreakpoint = 600.0; // Breakpoint para Clientes
  double dialogMaxWidth;

  if (fullScreenWidth < mobileBreakpoint) {
    // En móvil, el diálogo ocupa todo el ancho.
    dialogMaxWidth = fullScreenWidth;
  } else {
    // --- EN ESCRITORIO ---
    // ¡ESTE ES EL ÚNICO NÚMERO QUE DEBES AJUSTAR!
    // Define el ancho como un porcentaje de la pantalla.
    dialogMaxWidth = fullScreenWidth * 0.8; // <-- Cambia este valor si lo necesitas
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
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: ClienteDetalleDialog(idCliente: cliente.clienteInfo.idCliente!),
        ),
      );
    },
  );
}

  Widget _buildSortButton(BuildContext context, dynamic colors) {
    // Este widget no necesita cambios internos, ya que se adapta a través
    // de las variables de estado que ya hemos modificado (_sortableFieldsWithTypes, etc.)
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final selectedFieldInfo = _getSelectedFieldInfo();

    return HoverableActionButton(
      onTap: () => _showSortOptionsUsingGenericWidget(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selectedFieldInfo != null
                ? selectedFieldInfo['icon']
                : Icons.tune,
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

  String? _getFieldTypeForSortableField(String? fieldDisplayName) {
    if (fieldDisplayName == null || fieldDisplayName == 'Ninguno') return null;
    return _sortableFieldsWithTypes[fieldDisplayName]?['type'];
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

// Este método muestra el diálogo de confirmación. Tu versión actual está perfecta.
void _eliminarCliente(Cliente cliente) {
  // Asegúrate de que el idCliente no sea nulo antes de proceder
  if (cliente.clienteInfo.idCliente == null) {
    // Opcional: mostrar un snackbar si el ID es nulo por alguna razón
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: ID de cliente no encontrado.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${cliente.clienteInfo.nombres} ${cliente.clienteInfo.apellidoP}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo de confirmación
              _confirmarEliminacion(cliente); // Llama a la lógica de eliminación
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

  // ESTE ES EL MÉTODO CLAVE QUE DEBES REEMPLAZAR
// Usa tu nueva arquitectura de servicios y maneja los estados de carga y error.
// clientes.dart -> dentro de _ClientesScreenMobileState

Future<void> _confirmarEliminacion(Cliente cliente) async {
  if (cliente.clienteInfo.idCliente == null) return;
  final String idCliente = cliente.clienteInfo.idCliente!;

  // 1. Muestra el diálogo de carga
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

 try {
    // 2. Llamamos al servicio sin que muestre su diálogo de error
    final response = await _clienteService.eliminarCliente(
      idCliente,
      showErrorDialog: false, 
    );

      // 3. Cerramos el diálogo de carga (CircularProgressIndicator)
    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;

     // 4. Procesamos el resultado
    if (response.success) {
      // Éxito: Mostramos un SnackBar verde
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente eliminado correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Opcional: para que flote
        ),
      );
      obtenerClientes(); // Y refrescamos la lista
    } else {
      // ¡CAMBIO AQUÍ! En lugar del dialog, mostramos un SnackBar de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Ocurrió un error al intentar eliminar.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // Opcional: para que flote
        ),
      );
    }
  } catch (e) {
    // Manejo de errores de conexión u otros inesperados
    if (mounted) Navigator.of(context).pop(); // Asegurarnos de cerrar el diálogo de carga
    if (!mounted) return;
    
    AppLogger.log('Error de excepción al eliminar cliente: $e');
    // ¡CAMBIO AQUÍ TAMBIÉN! Usamos SnackBar para errores de conexión
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error de conexión. Inténtalo de nuevo.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating, // Opcional: para que flote
      ),
    );
  }
}

  Widget sexoBadge(String sexo) {
    final bool esFemenino = sexo.toLowerCase() == 'femenino';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (esFemenino ? Colors.purple : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        sexo,
        style: TextStyle(
          color: esFemenino ? Colors.purple : Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Widget de ayuda para las filas de información en la card (sin cambios)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required dynamic colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
        setState(() {
          _filtrosActivos.clear();
          for (var config in _configuracionesFiltros) {
            _filtrosActivos[config.clave] = null;
          }
        });
        _aplicarFiltrosYOrdenamiento();
      },
    );
  }

  /* void _aplicarFiltrosYOrdenamiento() {
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      searchClientes(_currentSearchQuery, page: 1);
    } else {
      obtenerClientes(page: 1);
    }
  } */

  // ADAPTADO: La query de filtros ahora usa los parámetros de los clientes.
  String _buildFilterQuery() {
    List<String> queryParams = [];

    if (_estadoClienteSeleccionadoFiltroAPI != null) {
      queryParams.add(
        'estado=${Uri.encodeComponent(_estadoClienteSeleccionadoFiltroAPI!)}',
      );
    }

    _filtrosActivos.forEach((key, value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString().toLowerCase() != 'todos') {
        // Asume que la clave del filtro ('tipoclientes', 'sexo') es la misma que el parámetro de la API.
        queryParams.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });

    return queryParams.join('&');
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
        filtrosActivos.entries
            .where(
              (entry) =>
                  entry.value != null &&
                  entry.value.toString().toLowerCase() != 'todos',
            )
            .length;

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
                    titulo: 'Filtros de Clientes',
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
}
