// Las importaciones y la definición de la clase se mantienen igual
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:finora_app/dialog/credito_detalle.dart';
import 'package:finora_app/forms/ncredito_form.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/models/fecha_pago.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/credito_service.dart';
import 'package:finora_app/utils/date_formatters.dart';
import 'package:finora_app/widgets/filtros_genericos_widget.dart';
import 'package:finora_app/widgets/hoverableActionButton.dart';
import 'package:finora_app/widgets/ordenamiento_genericos.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora_app/screens/login.dart';

import '../utils/app_logger.dart';

class SeguimientoScreenMobile extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const SeguimientoScreenMobile({
    super.key,
    required this.username,
    required this.tipoUsuario,
  });

  @override
  _SeguimientoScreenMobileState createState() =>
      _SeguimientoScreenMobileState();
}

class _SeguimientoScreenMobileState extends State<SeguimientoScreenMobile>
    with TickerProviderStateMixin {
  // ... TODA TU LÓGICA, VARIABLES DE ESTADO Y FUNCIONES (initState, obtenerCreditos, searchCreditos, etc.)
  // NO NECESITAN NINGÚN CAMBIO. Las dejo colapsadas para mayor claridad.
  List<Credito> listaCreditos = [];
  List<Credito> listaFiltrada = [];
  bool isLoading = false;
  bool errorDeConexion = false;
  bool noCreditsFound = false;
  String _searchQuery = ''; // Se mantiene para la búsqueda por texto en API
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final CreditoService _creditoService = CreditoService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false; // Para el spinner de "Cargar más"
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
  String? _estadoCreditoSeleccionadoFiltroAPI = 'Activo';
  List<Usuario> _usuarios = [];
  bool _isLoadingUsuarios = false;
  int? _userSelectedCrossAxisCount; // null = automático, 1, 2, 3 = fijo
  static const double mobileLayoutBreakpoint = 750.0;
  bool _isButtonHovered = false; // <-- AÑADE ESTA LÍNEA

  final Map<String, String> _sortableFields = {
    'Nombre': 'nombre',
    'Monto Autorizado': 'montoautorizado',
    'Interés.': 'interes',
    'Monto a Recuperar': 'montorecuperar',
    'Monto Ficha': 'pagoperiodo',
    'Fecha Creación': 'fCreacion',
  };
  Map<String, String> _getDirectionDisplayLabels(String? fieldType) {
    String ascText = 'Ascendente';
    String descText = 'Descendente';
    switch (fieldType) {
      case 'number':
        ascText += ' (de menor a mayor)';
        descText += ' (de mayor a menor)';
        break;
      case 'date':
        ascText += ' (más antiguo primero)';
        descText += ' (más reciente primero)';
        break;
      case 'text':
        ascText += ' (A-Z)';
        descText += ' (Z-A)';
        break;
      default:
        ascText += ' (de menor a mayor)';
        descText += ' (de mayor a menor)';
        break;
    }
    return {'Ascendente': ascText, 'Descendente': descText};
  }

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
        obtenerCreditos();
        obtenerUsuariosCampo();
      }
    });

    // ---> CAMBIO IMPORTANTE <---
    // Escuchador del scroll para cargar más datos. Ahora es más crucial
    // ya que no usamos Slivers para detectar el final.
    _scrollController.addListener(() {
      // Si el usuario está cerca del final de la lista (90% del scroll)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _loadMoreData(); // Llama a la misma función de cargar más
      }
    });
  }

  void _initializarFiltros() {
    _configuracionesFiltros = [
      ConfiguracionFiltro(
        clave: 'tipogrupo',
        titulo: 'Tipo de Crédito',
        tipo: TipoFiltro.dropdown,
        opciones: [
          'Grupal',
          'Individual',
          'Automotriz',
          'Empresarial',
          'Todos',
        ],
      ),
      ConfiguracionFiltro(
        clave: 'frecuencia',
        titulo: 'Frecuencia',
        tipo: TipoFiltro.dropdown,
        opciones: ['Semanal', 'Quincenal', 'Mensual', 'Bimestral', 'Todos'],
      ),
      ConfiguracionFiltro(
        clave: 'diapago',
        titulo: 'Día de Pago',
        tipo: TipoFiltro.dropdown,
        opciones: [
          'Lunes',
          'Martes',
          'Miércoles',
          'Jueves',
          'Viernes',
          'Sábado',
          'Domingo',
          'Todos',
        ],
      ),
      ConfiguracionFiltro(
        clave: 'numPago',
        titulo: 'Número de Pago',
        tipo: TipoFiltro.dropdown,
        opciones: [
          ...List.generate(20, (index) => (index + 1).toString()),
          'Todos',
        ],
      ),
      ConfiguracionFiltro(
        clave: 'estadopago',
        titulo: 'Estado de Pago',
        tipo: TipoFiltro.dropdown,
        opciones: ['Pagado', 'Pendiente', 'Retraso', 'Desembolso', 'Todos'],
      ),
      ConfiguracionFiltro(
        clave: 'asesor',
        titulo: 'Asesor',
        tipo: TipoFiltro.dropdown, // Asumiendo una lista finita de asesores
        opciones: [], // Opciones de ejemplo
      ),
    ];
    _filtrosActivos = {
      for (var config in _configuracionesFiltros) config.clave: null,
    };
  }

  final Map<String, Map<String, dynamic>> _sortableFieldsWithTypes = {
    'Nombre': {
      'api_key': 'nombre',
      'type': 'text',
      'icon': Icons.sort_by_alpha_rounded,
    },
    'Monto Autorizado': {
      'api_key': 'montoautorizado',
      'type': 'number',
      'icon': Icons.attach_money_rounded,
    },
    'Interés': {
      'api_key': 'interes',
      'type': 'number',
      'icon': Icons.percent_rounded,
    },
    'Monto a Recuperar': {
      'api_key': 'montorecuperar',
      'type': 'number',
      'icon': Icons.trending_up_rounded,
    },
    'Monto Ficha': {
      'api_key': 'pagoperiodo',
      'type': 'number',
      'icon': Icons.payments_rounded,
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

  Future<void> obtenerCreditos({int page = 1, bool loadMore = false}) async {
    if (!mounted || (loadMore && _isLoadingMore)) return;
    setState(() {
      if (loadMore) {
        _isLoadingMore = true; // Activa el spinner de "cargar más"
      } else {
        isLoading = true; // Activa el spinner de carga principal
        errorDeConexion = false;
        noCreditsFound = false;
      }
      currentPage = page;
    });
    String sortQuery = '';
    if (_sortColumnKey != null) {
      sortQuery = '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}';
    }
    String filterQuery = _buildFilterQuery();
    final endpoint =
        '/api/v1/creditos?limit=12&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔄 Obteniendo créditos: $baseUrl$endpoint');
    try {
      final response = await _apiService.get<List<Credito>>(
        endpoint,
        parser:
            (json) =>
                (json as List).map((item) => Credito.fromJson(item)).toList(),
      );
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            if (loadMore) {
              listaCreditos.addAll(response.data!);
              listaFiltrada.addAll(response.data!);
            } else {
              listaCreditos = response.data!;
              listaFiltrada = List.from(listaCreditos);
              if (listaCreditos.isNotEmpty) {
                _animationController.reset();
                _animationController.forward();
              }
            }
            noCreditsFound = listaCreditos.isEmpty;
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
              AppLogger.log('📊 Headers: totalDatos: $totalDatos, totalPaginas: $totalPaginas',
              );
            } else {
              if (!loadMore) totalDatos = 0;
            }
          } else if (!loadMore) {
            listaCreditos = [];
            listaFiltrada = [];
            noCreditsFound = true;
            totalDatos = 0;
            totalPaginas = 1;
            if (!response.success &&
                response.error != null &&
                response.error!.contains("no se encontraron créditos")) {
              noCreditsFound = true;
            }
          }
          isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.log('❌ Error inesperado obteniendo créditos: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) {
            listaCreditos = [];
            listaFiltrada = [];
            totalDatos = 0;
            totalPaginas = 1;
          }
        });
      }
    }
  }

  void _actualizarOpcionesUsuarios() {
    final filtroUsuario = _configuracionesFiltros.firstWhere(
      (config) => config.clave == 'asesor',
    );
    filtroUsuario.opciones =
        _usuarios.map((usuario) => usuario.nombreCompleto).toList();
  }

  Future<void> obtenerUsuariosCampo() async {
    setState(() {
      _isLoadingUsuarios = true;
    });
    final response = await _apiService.get<List<Usuario>>(
      '/api/v1/usuarios/tipo/campo',
      parser: (json) => (json as List).map((e) => Usuario.fromJson(e)).toList(),
    );
    if (!mounted) return;
    setState(() {
      _isLoadingUsuarios = false;
      if (response.success) {
        _usuarios = response.data ?? [];
        _actualizarOpcionesUsuarios();
      } else {
        errorMessage = response.error ?? 'Error al cargar usuarios';
      }
    });
  }

  Future<void> searchCreditos(
    String query, {
    int page = 1,
    bool loadMore = false,
  }) async {
    _currentSearchQuery = query;
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _isSearching = false;
      obtenerCreditos(page: 1); // Reset
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
        noCreditsFound = false;
      }
      currentPage = page;
    });
    String sortQuery = '';
    if (_sortColumnKey != null) {
      sortQuery = '&${_sortColumnKey}=${_sortAscending ? 'AZ' : 'ZA'}';
    }
    String filterQuery = _buildFilterQuery();
    final encodedQuery = Uri.encodeComponent(query);
    final endpoint =
        '/api/v1/creditos/$encodedQuery?limit=12&page=$page$sortQuery${filterQuery.isNotEmpty ? '&$filterQuery' : ''}';
    AppLogger.log('🔍 Buscando: $baseUrl$endpoint');
    try {
      final response = await _apiService.get<List<Credito>>(
        endpoint,
        parser: (json) {
          if (json is List) {
            return json.map((item) => Credito.fromJson(item)).toList();
          } else if (json is Map &&
              json.containsKey('data') &&
              json['data'] is List) {
            final data = json['data'] as List;
            return data.map((item) => Credito.fromJson(item)).toList();
          } else {
            if (json is Map &&
                json.containsKey('message') &&
                (json['message'] as String).toLowerCase().contains(
                  'no se encontraron créditos',
                )) {
              return <Credito>[];
            }
            AppLogger.log("Formato de respuesta inesperado en búsqueda: $json");
            return <Credito>[];
          }
        },
        showErrorDialog: false,
      );
      if (!mounted) return;
      setState(() {
        if (response.success && response.data != null) {
          if (loadMore) {
            listaCreditos.addAll(response.data!);
            listaFiltrada.addAll(response.data!);
          } else {
            listaCreditos = response.data!;
            listaFiltrada = List.from(listaCreditos);
            if (listaCreditos.isNotEmpty) {
              _animationController.reset();
              _animationController.forward();
            }
          }
          noCreditsFound = listaCreditos.isEmpty;
          if (response.headers != null) {
            totalDatos =
                int.tryParse(response.headers!['x-total-totaldatos'] ?? '0') ??
                0;
            totalPaginas =
                int.tryParse(
                  response.headers!['x-total-totalpaginas'] ?? '1',
                ) ??
                1;
            AppLogger.log(
              '📊 Headers (search): totalDatos: $totalDatos, totalPaginas: $totalPaginas',
            );
          } else if (!loadMore) {
            totalDatos = 0;
          }
        } else if (!loadMore) {
          listaCreditos = [];
          listaFiltrada = [];
          noCreditsFound = true;
          totalDatos = 0;
          totalPaginas = 1;
        }
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      AppLogger.log('❌ Error inesperado en búsqueda: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _isLoadingMore = false;
          errorDeConexion = true;
          if (!loadMore) {
            listaCreditos = [];
            listaFiltrada = [];
            totalDatos = 0;
            totalPaginas = 1;
          }
        });
      }
    }
  }

  void _loadMoreData() {
    if (currentPage < totalPaginas && !_isLoadingMore) {
      if (_isSearching && _currentSearchQuery.isNotEmpty) {
        searchCreditos(
          _currentSearchQuery,
          page: currentPage + 1,
          loadMore: true,
        );
      } else {
        obtenerCreditos(page: currentPage + 1, loadMore: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    currentPage = 1;
    totalPaginas = 1;
    totalDatos = 0;
    listaCreditos.clear();
    listaFiltrada.clear();
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      await searchCreditos(_currentSearchQuery, page: 1);
    } else {
      await obtenerCreditos(page: 1);
    }
  }

  // =========================================================================
  // ====================== INICIO DE LA ZONA REFACTORIZADA ======================
  // =========================================================================

  // =========================================================================
  // ====================== INICIO DE LA ZONA REFACTORIZADA ======================
  // =========================================================================

  // REEMPLAZA TU MÉTODO build POR ESTE

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // --- CAMBIO 1: ENVOLVEMOS EL SCAFFOLD EN UN LAYOUTBUILDER ---
    // Esto nos da las dimensiones de la pantalla para decidir qué layout usar.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinamos si es layout de escritorio basado en el ancho.
        final bool isDesktopLayout =
            constraints.maxWidth > mobileLayoutBreakpoint;

        return Scaffold(
          backgroundColor: colors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: colors.backgroundPrimary,
            surfaceTintColor: colors.backgroundPrimary,
            elevation: 1.0,
            shadowColor: Colors.black.withOpacity(0.1),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                80.0,
              ), // Aumentamos un poco la altura para que quepa todo cómodamente
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Este método ya es responsivo gracias al cambio anterior
                  _buildSearchAndFilters(colors),
                  _buildResultsCountInfo(colors),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.blue,
            backgroundColor: colors.backgroundCard,
            child: _buildContent(colors),
          ),

          // --- CAMBIO 2: HACEMOS EL FAB CONDICIONAL ---
          // Si es layout de escritorio, el FAB es null (no aparece).
          // Si no, se muestra el FAB de siempre.
          floatingActionButton:
              isDesktopLayout ? null : _buildModernFAB(colors),
        );
      },
    );
  }

  // AÑADE ESTE MÉTODO DE AYUDA
  // Crea un item para nuestra fila, con una etiqueta y un valor.
  Widget _buildTableRowItem(
    String label,
    String value, {
    IconData? icon,
    Color valueColor = Colors.black, // Color por defecto
    FontWeight fontWeight = FontWeight.bold,
    dynamic colors, // Pasa los colores del tema
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textSecondary.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: valueColor, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // AÑADE ESTE MÉTODO PRINCIPAL PARA EL NUEVO LAYOUT
  // Este es el widget que construye la tarjeta en formato de fila.
  // REEMPLAZA tu método _buildTableRowCardContent con esta versión completa
  Widget _buildTableRowCardContent(Credito credito, dynamic colors) {
    // Función para obtener el color del estado de pago (la mantienes igual)
    Color getEstadoPagoColor(String? estado) {
      switch (estado?.toLowerCase()) {
        case 'pagado':
          return Colors.green;
        case 'pendiente':
          return Colors.orange;
        case 'retraso':
          return Colors.red;
        case 'desembolso':
          return Colors.blue.shade500;
        default:
          return colors.textSecondary;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --- COLUMNA 1: Identificación y Tags ---
        Expanded(
          flex: 3, // Ajusta el flex para dar espacio adecuado
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tags de Tipo y Plazo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      credito.tipo,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      credito.tipoPlazo,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Nombre y Fecha
              Text(
                credito.nombreGrupo,
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
                DateFormatters.formatearFechaRelativa(credito.fCreacion),
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 20, indent: 16, endIndent: 16),

        // --- COLUMNA 2: Métricas Financieras ---
        Expanded(
          flex: 4, // Más espacio para los números
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTableRowItem(
                'Autorizado',
                '\$${formatearNumero(credito.montoTotal ?? 0.0)}',
                colors: colors,
                valueColor: Colors.blue.shade600,
              ),
              _buildTableRowItem(
                'A Recuperar',
                '\$${formatearNumero(credito.montoMasInteres ?? 0.0)}',
                colors: colors,
                valueColor: Colors.green.shade600,
              ),
              _buildTableRowItem(
                'Interés',
                '${credito.ti_mensual?.toStringAsFixed(2) ?? 'N/A'}%',
                icon: Icons.percent_rounded,
                colors: colors,
                valueColor: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 20, indent: 16, endIndent: 16),

        // --- COLUMNA 3: Detalles de Pago ---
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTableRowItem(
                'Día Pago',
                credito.diaPago ?? 'N/A',
                icon: Icons.calendar_today_rounded,
                colors: colors,
                valueColor: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              // Recreamos el item interactivo para el número de pago
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (credito.fechas.isNotEmpty) {
                      _showPaymentScheduleSheet(context, credito);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _buildTableRowItem(
                      'Pagos',
                      credito.periodoPagoActual ?? credito.numPago ?? 'N/A',
                      icon: Icons.format_list_numbered_rounded,
                      colors: colors,
                      valueColor:
                          credito.fechas.isNotEmpty
                              ? Colors.blueAccent
                              : colors
                                  .textPrimary, // Color azul si es interactivo
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- COLUMNA 4: Moratorios (condicional) ---
        if (credito.estadoCredito?.moratorios != null &&
            credito.estadoCredito!.moratorios > 0) ...[
          const VerticalDivider(width: 20, indent: 16, endIndent: 16),
          _buildTableRowItem(
           /*  'Moratorios (${credito.estadoCredito?.diferenciaEnDias ?? 0}d)',
            '\$${formatearNumero(credito.estadoCredito?.moratorios ?? 0.0)}', */
            'Moratorios Acumulados', '\$${formatearNumero(credito.estadoCredito?.acumulado ?? 0.0)}',
            icon: Icons.warning_amber_rounded,
            colors: colors,
            valueColor: Colors.red.shade600,
          ),
        ],

        const Spacer(), // Empuja lo siguiente al final
        // --- COLUMNA FINAL: Estatus y Acciones ---
        Row(
          children: [
            _buildModernStatusChip(credito.estado),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: getEstadoPagoColor(
                  credito.estadoInterno,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                credito.estadoInterno ?? 'N/A',
                style: TextStyle(
                  color: getEstadoPagoColor(credito.estadoInterno),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              color: colors.backgroundPrimary,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textSecondary,
                size: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (String value) {
                switch (value) {
                  case 'editar':
                    // Tu lógica para editar
                    break;
                  case 'eliminar':
                    // Llama al diálogo de confirmación
                    _mostrarDialogoConfirmacionEliminar(
                      credito.idcredito,
                      credito.nombreGrupo,
                    );
                    break;
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.edit_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Row(
                        children: const [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ],
    );
  }

  // AÑADE ESTE MÉTODO (CON EL CONTENIDO QUE YA TENÍAS)
  Widget _buildStandardCardContent(Credito credito, dynamic colors) {
    // Aquí va el Column que cortaste del método _buildModernCreditCardWithoutMargins
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    credito.tipo,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                    credito.tipoPlazo,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Transform.translate(
              offset: const Offset(12, -10),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 40),
                color: colors.backgroundPrimary,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: colors.textSecondary,
                  size: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (String value) {
                  switch (value) {
                    case 'editar':
                      // Tu lógica para editar
                      break;
                    case 'eliminar':
                      // Llama al diálogo de confirmación
                      _mostrarDialogoConfirmacionEliminar(
                        credito.idcredito,
                        credito.nombreGrupo,
                      );
                      break;
                  }
                },
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'eliminar',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credito.nombreGrupo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colors.textPrimary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatters.formatearFechaRelativa(credito.fCreacion),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _buildModernStatusChip(credito.estado),
          ],
        ),
        const SizedBox(height: 16),
        _buildAmountSection(credito),
        const SizedBox(height: 12),
        _buildCompactInfo(credito),
        if (credito.estadoCredito?.acumulado != null &&
            credito.estadoCredito!.acumulado > 0) ...[
          const SizedBox(height: 12),
          _buildWarningSection(credito),
        ],
      ],
    );
  }

  // Pega este nuevo método en tu clase
  Widget _buildLayoutControlButton(BuildContext context, dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Elige el ícono a mostrar basado en la selección actual
    IconData iconData;
    if (_userSelectedCrossAxisCount == null ||
        _userSelectedCrossAxisCount! > 1) {
      iconData = Icons.grid_view_rounded;
    } else {
      iconData = Icons.view_list_rounded;
    }

    // --- INICIO DE CAMBIOS PARA HOVER ---

    // 1. Determina los colores y sombras basados en el estado de hover
    final Color backgroundColor =
        _isButtonHovered // <-- USA LA VARIABLE DE ESTADO
            ? (isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200)
            : themeProvider.colors.backgroundCard;

    final List<BoxShadow> boxShadow = [
      BoxShadow(
        color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(
          _isButtonHovered ? 0.15 : 0.1,
        ), // <-- Sombra dinámica
        blurRadius: _isButtonHovered ? 12 : 8, // <-- Blur dinámico
        offset: Offset(0, _isButtonHovered ? 4 : 2), // <-- Offset dinámico
      ),
    ];

    // --- FIN DE CAMBIOS PARA HOVER ---

    return PopupMenuButton<int>(
      tooltip: '',
      offset: const Offset(0, 35),
      onSelected: (int value) {
        setState(() {
          if (value == 0) {
            _userSelectedCrossAxisCount = null;
          } else {
            _userSelectedCrossAxisCount = value;
          }
        });
      },
      color: colors.backgroundPrimary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      // 2. Envuelve el Container con un MouseRegion
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (_) => setState(
              () => _isButtonHovered = true,
            ), // <-- Actualiza estado al entrar
        onExit:
            (_) => setState(
              () => _isButtonHovered = false,
            ), // <-- Actualiza estado al salir

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor, // <-- USA EL COLOR DINÁMICO
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color:
                  isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3),
              width: 1.3,
            ),
            boxShadow: boxShadow, // <-- USA LA SOMBRA DINÁMICA
          ),
          child: Icon(
            iconData,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),

      itemBuilder:
          (context) => [
            _buildPopupMenuItem(
              1,
              '1 Columna',
              Icons.view_list_rounded,
              colors,
            ),
            _buildPopupMenuItem(
              2,
              '2 Columnas',
              Icons.grid_view_rounded,
              colors,
            ),
            _buildPopupMenuItem(
              3,
              '3 Columnas',
              Icons.view_quilt_rounded,
              colors,
            ),
            const PopupMenuDivider(),
            _buildPopupMenuItem(
              0,
              'Automático',
              Icons.dynamic_feed_rounded,
              colors,
            ),
          ],
    );
  }

  // Un helper para crear los items del menú de forma consistente
  PopupMenuItem<int> _buildPopupMenuItem(
    int value,
    String text,
    IconData icon,
    dynamic colors,
  ) {
    final bool isSelected =
        (_userSelectedCrossAxisCount == value) ||
        (_userSelectedCrossAxisCount == null && value == 0);

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

  /// ESTE ES EL NUEVO MÉTODO CENTRAL PARA EL LAYOUT
  /// Utiliza LayoutBuilder para crear una rejilla responsiva.
  // Pega este método actualizado en tu clase, reemplazando la versión anterior.

  // Pega este método actualizado en tu clase, reemplazando la versión anterior.

  // Pega este método actualizado, reemplazando el tuyo.
  // Reemplaza tu método _buildContent con esta versión actualizada
  // Reemplaza tu método _buildContent con esta versión final
  // Reemplaza tu método _buildContent con esta versión mejorada
  Widget _buildContent(dynamic colors) {
    // Las secciones de carga, error y estado vacío no cambian.
    if (isLoading && listaFiltrada.isEmpty) {
      return Center(child: _buildModernLoading());
    }
    if (errorDeConexion && listaFiltrada.isEmpty) {
      return _buildErrorState();
    }
    if (noCreditsFound || (listaFiltrada.isEmpty && !isLoading)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildEmptyState(),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        const double horizontalPadding = 16.0;
        const double crossAxisSpacing = 16.0;
        final bool isDesktopLayout = screenWidth > mobileLayoutBreakpoint;

        int crossAxisCount;
        if (isDesktopLayout && _userSelectedCrossAxisCount != null) {
          crossAxisCount = _userSelectedCrossAxisCount!;
        } else if (isDesktopLayout) {
          const double cardIdealWidth = 380.0;
          crossAxisCount = (screenWidth / cardIdealWidth).floor();
          if (crossAxisCount == 0) crossAxisCount = 1;
        } else {
          crossAxisCount = 1;
        }

        // --- LÓGICA DE ALTURA Y LAYOUT (ACTUALIZADA) ---
        const double standardCardHeight = 440.0;
        // Aumentamos la altura para la vista de tabla para que quepa todo.
        // Puedes ajustar este valor si lo necesitas.
        const double tableRowCardHeight = 100.0;

        final bool useTableRowLayout = isDesktopLayout && crossAxisCount == 1;
        final double desiredCardHeight =
            useTableRowLayout ? tableRowCardHeight : standardCardHeight;

        final double totalHorizontalGaps =
            (horizontalPadding * 2) + (crossAxisSpacing * (crossAxisCount - 1));
        final double cardWidth =
            (screenWidth - totalHorizontalGaps) / crossAxisCount;
        final double dynamicAspectRatio = cardWidth / desiredCardHeight;

        return GridView.builder(
          // ... (el resto del GridView.builder se queda igual) ...
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            80,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: 16.0,
            childAspectRatio: dynamicAspectRatio,
          ),
          itemCount: listaFiltrada.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == listaFiltrada.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final credito = listaFiltrada[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index /
                              (listaFiltrada.isEmpty
                                  ? 1
                                  : listaFiltrada.length)) *
                          0.5,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: _buildModernCreditCardWithoutMargins(
                  credito: credito,
                  isTableRowLayout: useTableRowLayout,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Crea una copia de tu `_buildModernCreditCard` pero sin el `margin` exterior.
  // El GridView se encargará del espaciado.
  // REEMPLAZA TU MÉTODO _buildModernCreditCardWithoutMargins
  Widget _buildModernCreditCardWithoutMargins({
    required Credito credito,
    required bool isTableRowLayout, // Acepta el nuevo parámetro
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

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
          onTap: () => _showModernCreditoDetails(context, credito.folio),
          child: Padding(
            // Padding diferente para cada layout para un mejor ajuste
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isTableRowLayout ? 12 : 20,
            ),
            // --- ¡AQUÍ ESTÁ LA MAGIA! ---
            // Se decide qué layout construir basado en el flag
            child:
                isTableRowLayout
                    ? _buildTableRowCardContent(credito, colors)
                    : _buildStandardCardContent(credito, colors),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ======================= FIN DE LA ZONA REFACTORIZADA ========================
  // =========================================================================

  // El resto de los métodos (_buildResultsCountInfo, _buildModernCreditCard, _buildLoadMoreIndicator, etc.)
  // se mantienen EXACTAMENTE IGUAL, ya que son independientes de la estructura de scroll.
  // Los pego a continuación sin cambios.
  Widget _buildResultsCountInfo(dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    String textoAMostrar;
    Color colorTexto = colors.textSecondary.withOpacity(0.9);

    if (isLoading) {
      if (_isSearching && _currentSearchQuery.isNotEmpty) {
        textoAMostrar = 'Buscando "${_currentSearchQuery}"...';
        colorTexto = colors.textSecondary.withOpacity(0.8);
      } else {
        textoAMostrar = 'Cargando créditos...';
        colorTexto = colors.textSecondary.withOpacity(0.8);
      }
    } else if (errorDeConexion && listaFiltrada.isEmpty) {
      textoAMostrar = 'Error al cargar créditos';
      colorTexto = colors.error.withOpacity(0.8);
    } else if (noCreditsFound && totalDatos == 0) {
      if (_isSearching && _currentSearchQuery.isNotEmpty) {
        textoAMostrar =
            'No se encontraron resultados para "${_currentSearchQuery}"';
      } else {
        textoAMostrar = 'No hay créditos disponibles';
      }
      colorTexto = colors.textSecondary.withOpacity(0.8);
    } else if (listaFiltrada.isNotEmpty && totalDatos > 0) {
      int itemsMostrados = listaFiltrada.length;
      textoAMostrar = 'Mostrando $itemsMostrados de $totalDatos créditos';
    } else {
      textoAMostrar = ' '; // Espacio para mantener altura
    }

    return Container(
      height: 25, // Altura fija
      padding: const EdgeInsets.only(
        top: 0.0,
        left: 18.0,
        right: 16.0,
        bottom: 10.0,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Align(
          key: ValueKey(textoAMostrar), // Key única para la animación
          alignment: Alignment.centerLeft,
          child: Text(
            textoAMostrar,
            style: TextStyle(
              color: colorTexto,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Widget para el botón de "Agregar" que se mostrará en la vista de escritorio.
  Widget _buildAddButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return ElevatedButton.icon(
      onPressed: _agregarCredito, // <--- CAMBIO AQUÍ
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Agregar Crédito'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.backgroundButton,
        foregroundColor: colors.whiteWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
      ),
    );
  }

  // Reemplaza tu método _buildSearchAndFilters con esta versión
  // Reemplaza tu método _buildSearchAndFilters con esta versión actualizada
  // REEMPLAZA TU MÉTODO _buildSearchAndFilters POR ESTE

  Widget _buildSearchAndFilters(dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentColors = themeProvider.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopLayout =
            constraints.maxWidth > mobileLayoutBreakpoint;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: currentColors.backgroundPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: currentColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: currentColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar por folio, nombre...',
                    hintStyle: TextStyle(
                      color: currentColors.textSecondary.withOpacity(0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: currentColors.textSecondary.withOpacity(0.7),
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: currentColors.textSecondary.withOpacity(
                                  0.7,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _isSearching = false;
                                _currentSearchQuery = '';
                                obtenerCreditos();
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _timer?.cancel();
                    _timer = Timer(const Duration(milliseconds: 700), () {
                      if (value.trim().isNotEmpty) {
                        searchCreditos(value);
                      } else {
                        _isSearching = false;
                        _currentSearchQuery = '';
                        obtenerCreditos();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              // --- CAMBIO PRINCIPAL AQUÍ ---
              // Esta Row ahora contiene la lógica para mostrar el botón de agregar.
              Row(
                children: [
                  // Botones de la izquierda
                  _buildFilterButton(context),
                  const SizedBox(width: 8),
                  _buildSortButton(context, currentColors),

                  if (isDesktopLayout) ...[
                    const SizedBox(width: 8),
                    _buildLayoutControlButton(context, currentColors),
                  ],

                  const SizedBox(width: 8),

                  // Este Widget tomará todo el espacio del medio
                  Expanded(child: _buildStatusFiltersChips(currentColors)),

                  // --- LÓGICA PARA EL BOTÓN DE AGREGAR ---
                  // Si es layout de escritorio, mostramos el botón.
                  // El `Expanded` anterior lo empujará hasta la derecha.
                  if (isDesktopLayout) ...[
                    const SizedBox(width: 16), // Espacio de separación
                    _buildAddButton(context), // Nuestro nuevo botón
                  ],
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _buildStatusFiltersChips(dynamic colors) {
    final estados = ['Todos', 'Activo', 'Finalizado', 'En Mora'];
    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              estados
                  .map((estado) => _buildFilterChip(estado, colors))
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String estado, dynamic colors) {
    final bool isSelected =
        (_estadoCreditoSeleccionadoFiltroAPI == null && estado == 'Todos') ||
        (_estadoCreditoSeleccionadoFiltroAPI == estado);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        showCheckmark: false,
        label: Text(estado, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              if (estado == 'Todos') {
                _estadoCreditoSeleccionadoFiltroAPI = null;
              } else {
                _estadoCreditoSeleccionadoFiltroAPI = estado;
              }
            });
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
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, // Reduce el área de toque
        visualDensity: VisualDensity.compact, // Hace el chip más compacto
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Muestra el botón solo si hay más páginas por cargar y no estamos en una carga inicial
    if (currentPage < totalPaginas && !isLoading) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 60.0,
          right: 60,
          top: 10.0,
          bottom: 20,
        ),
        child: ElevatedButton(
          onPressed: _loadMoreData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cargar más'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Los siguientes métodos permanecen sin cambios
  Widget _buildModernCreditCard(Credito credito) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    void _editarCredito(Credito credito) {
      AppLogger.log('Editando crédito: ${credito.folio}');
    }

    void _eliminarCredito(String folio) {
      AppLogger.log('Eliminando crédito: $folio');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          onTap: () => _showModernCreditoDetails(context, credito.folio),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            credito.tipo,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            credito.tipoPlazo,
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Transform.translate(
                      offset: const Offset(12, -10),
                      child: PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        color: colors.backgroundPrimary,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: colors.textSecondary,
                          size: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        onSelected: (String value) {
                          switch (value) {
                            case 'editar':
                              _editarCredito(credito);
                              break;
                            case 'eliminar':
                              _eliminarCredito(credito.folio);
                              break;
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'editar',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'eliminar',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Eliminar'),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credito.nombreGrupo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatters.formatearFechaRelativa(
                              credito.fCreacion,
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildModernStatusChip(credito.estado),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAmountSection(credito),
                const SizedBox(height: 12),
                _buildCompactInfo(credito),
                if (credito.estadoCredito?.moratorios != null &&
                    credito.estadoCredito!.moratorios > 0) ...[
                  const SizedBox(height: 12),
                  _buildWarningSection(credito),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo(Credito credito) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.smallCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactInfoItem(
              Icons.percent_rounded,
              '${credito.ti_mensual?.toStringAsFixed(2) ?? 'N/A'}%',
              Colors.indigo,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildCompactInfoItem(
              Icons.calendar_today_rounded,
              credito.diaPago ?? 'N/A',
              Colors.teal,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  if (credito.fechas.isNotEmpty) {
                    _showPaymentScheduleSheet(context, credito);
                  }
                },
                child: _buildCompactInfoItem(
                  Icons.format_list_numbered_rounded,
                  credito.periodoPagoActual ?? credito.numPago ?? 'N/A',
                  Colors.orange,
                  isInteractive: credito.fechas.isNotEmpty,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem(
    IconData icon,
    String value,
    Color color, {
    bool isInteractive = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isInteractive ? Colors.blueAccent : color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isInteractive ? Colors.blueAccent : colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isInteractive) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.blueAccent.withOpacity(0.7),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.shade300,
    );
  }

  void _showPaymentScheduleSheet(BuildContext context, Credito credito) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(modalContext).pop();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.5,
              maxChildSize: 0.6,
              builder: (_, controller) {
                return _buildPaymentScheduleContent(
                  context,
                  credito,
                  controller,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentScheduleContent(
    BuildContext context,
    Credito credito,
    ScrollController scrollController,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    final paidCount =
        credito.fechas
            .where((p) => p.estado.toLowerCase().contains('pagado'))
            .length;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Column(
              children: [
                Text(
                  'Cronograma de Pagos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pagados: ${credito.numPago}',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: credito.fechas.length,
              itemBuilder: (context, index) {
                final fechaPago = credito.fechas[index];
                return _buildPaymentScheduleItem(
                  fechaPago,
                  credito.periodoPagoActual,
                  isDarkMode,
                  colors,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScheduleItem(
    FechaPago fechaPago,
    String? periodoPagoActual,
    bool isDarkMode,
    dynamic colors,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (fechaPago.estado.toLowerCase()) {
      case 'pagado':
      case 'pagado para renovacion':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
      case 'en abonos':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'atraso':
      case 'retraso':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'proximo':
        statusColor = Colors.blue;
        statusIcon = Icons.upcoming;
        break;
      case 'pagado con retraso':
        statusColor = Colors.purple;
        statusIcon = Icons.history_toggle_off_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    final bool isCurrentPayment =
        periodoPagoActual?.contains(' ${fechaPago.numPago} ') ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isCurrentPayment ? statusColor.withOpacity(0.1) : colors.smallCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCurrentPayment
                  ? statusColor.withOpacity(0.5)
                  : colors.smallCardBorder.withOpacity(0.3),
          width: isCurrentPayment ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago ${fechaPago.numPago}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fechaPago.fechaPago,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              fechaPago.estado,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFechaCorta(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yy', 'es_MX').format(fecha);
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(fecha);
    }
  }

  Widget _buildAmountSection(Credito credito) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAmountItem(
                  'Autorizado',
                  credito.montoTotal ?? 0.0,
                  Icons.account_balance_wallet_rounded,
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 35,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(
                child: _buildAmountItem(
                  'A Recuperar',
                  credito.montoMasInteres ?? 0.0,
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.payments_rounded,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Monto ficha: \$${formatearNumero(credito.pagoCuota ?? 0.0)}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoPagoColor(
                      credito.estadoInterno,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getEstadoPagoColor(
                        credito.estadoInterno,
                      ).withOpacity(0.7),
                    ),
                  ),
                  child: Text(
                    credito.estadoInterno ?? 'Sin estado',
                    style: TextStyle(
                      color: _getEstadoPagoColor(credito.estadoInterno),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoPagoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'retraso':
        return Colors.red;
      case 'desembolso':
        return Colors.blue.shade500;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAmountItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${formatearNumero(amount)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection(Credito credito) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.moratoriosCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.moratoriosCardBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* Text(
                  'Moratorios: ${credito.estadoCredito?.diferenciaEnDias ?? 0} días',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ), */
                Text(
                  'Moratorios acumulados: \$${formatearNumero(credito.estadoCredito?.acumulado ?? 0.0)}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
      'Finalizado': {'color': Colors.red, 'icon': Icons.flag_circle_outlined},
      'En Mora': {'color': Colors.orange, 'icon': Icons.warning_amber_rounded},
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

  // --- NUEVO MÉTODO UNIFICADO PARA AGREGAR CRÉDITO ---
  // --- MÉTODO FINAL Y REFACTORIZADO PARA AGREGAR CRÉDITO ---
  void _agregarCredito() {
    // Usamos el context del Navigator para obtener la pantalla completa.
    final fullScreenContext = Navigator.of(context).context;
    final fullScreenWidth = MediaQuery.of(fullScreenContext).size.width;
    final fullScreenHeight = MediaQuery.of(fullScreenContext).size.height;

    const double mobileBreakpoint =
        768.0; // Mantenemos el breakpoint que preferías
    double dialogMaxWidth;
    double dialogMaxHeight;

    if (fullScreenWidth < mobileBreakpoint) {
      dialogMaxWidth = fullScreenWidth;
      dialogMaxHeight = fullScreenHeight * 0.95;
    } else {
      dialogMaxWidth = fullScreenWidth * 0.8;
      if (dialogMaxWidth > 1200) {
        dialogMaxWidth = 1200;
      }
      dialogMaxHeight = fullScreenHeight * 0.92;
    }

    showModalBottomSheet(
      context: context, // El context original se usa para lanzar el modal
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: dialogMaxWidth),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dialogMaxHeight),
            child: nCreditoForm(onCreditoAgregado: obtenerCreditos),
          ),
        );
      },
    );
  }

  Future<void> _eliminarCredito(String idCredito) async {
    // 1. Mostrar SnackBar de carga (esto se mantiene igual)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 20),
            Text('Eliminando crédito...'),
          ],
        ),
        duration: const Duration(minutes: 1),
      ),
    );

    // ¡TODA LA LÓGICA ANTERIOR (try/catch con http, token, json.decode) SE VA!
    // La llamada ahora es limpia y directa a nuestro servicio.
    final response = await _creditoService.eliminarCredito(idCredito);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 3. Manejar la respuesta del servicio
    if (response.success) {
      // Éxito: refrescamos la lista y mostramos un mensaje.
      obtenerCreditos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Crédito eliminado exitosamente',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
    // NO NECESITAMOS UN `else` para el error.
    // Tu ApiService ya está configurado para mostrar los diálogos de error
    // (sesión expirada, error del servidor, etc.) automáticamente.
    // ¡El código de la UI se mantiene limpio!
  }

  Future<void> _mostrarDialogoConfirmacionEliminar(
    String idCredito,
    String nombreCredito,
  ) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente el crédito "$nombreCredito"?\n\nEsta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      // Llama a nuestra nueva y limpia función de eliminación
      _eliminarCredito(idCredito);
    }
  }

  Widget _buildModernFAB(dynamic colorsInstance) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return FloatingActionButton(
      heroTag: null,
      onPressed: _agregarCredito, // <--- CAMBIO AQUÍ
      child: const Icon(Icons.add_rounded),
      backgroundColor: colors.backgroundButton,
      foregroundColor: colors.whiteWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildModernLoading() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando créditos...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off_rounded,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron créditos',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching ||
                      _filtrosActivos.values.any(
                        (v) =>
                            v != null && v.toString().toLowerCase() != 'todos',
                      ) ||
                      _estadoCreditoSeleccionadoFiltroAPI != null
                  ? 'Prueba ajustando los filtros o la búsqueda.'
                  : 'Aún no hay créditos registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.blue,
      backgroundColor: colors.backgroundCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error de conexión',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Desliza hacia abajo para recargar o toca el botón.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- VERSIÓN ACTUALIZADA Y RESPONSIVA ---
  // Archivo: lib/screens/seguimiento_screen_mobile.dart

  // Archivo: lib/screens/seguimiento_screen_mobile.dart

  // Método para el diálogo de DETALLES
  void _showModernCreditoDetails(BuildContext context, String folio) {
    // Usamos el context del Navigator para obtener la pantalla completa.
    final fullScreenContext = Navigator.of(context).context;
    final fullScreenWidth = MediaQuery.of(fullScreenContext).size.width;

    const double mobileBreakpoint = 750.0;
    double dialogMaxWidth;

    if (fullScreenWidth < mobileBreakpoint) {
      dialogMaxWidth = fullScreenWidth;
    } else {
      // Aplicamos la misma lógica en ambos para consistencia
      dialogMaxWidth = fullScreenWidth * 0.85;
      if (dialogMaxWidth > 1600) {
        dialogMaxWidth = 1600;
      }
    }

    showModalBottomSheet(
      context: context, // El context original se usa para lanzar el modal
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: dialogMaxWidth),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(fullScreenContext).size.height * 0.92,
            ),
            child: CreditoDetalleConTabs(folio: folio),
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return buildFilterButtonMobile(
      context,
      _filtrosActivos,
      _configuracionesFiltros,
      (filtrosAplicados) {
        setState(() {
          _filtrosActivos = Map<String, dynamic>.from(filtrosAplicados);
        });
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

  void _aplicarFiltrosYOrdenamiento() {
    if (_isSearching && _currentSearchQuery.isNotEmpty) {
      searchCreditos(_currentSearchQuery, page: 1);
    } else {
      obtenerCreditos(page: 1);
    }
  }

  String _buildFilterQuery() {
    List<String> queryParams = [];
    if (_estadoCreditoSeleccionadoFiltroAPI != null) {
      queryParams.add(
        'estadocredito=${Uri.encodeComponent(_estadoCreditoSeleccionadoFiltroAPI!)}',
      );
    }
    _filtrosActivos.forEach((key, value) {
      if (key == 'estadocredito') return;
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString().toLowerCase() != 'todos') {
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
                  Map<String, dynamic> valoresInicialesParaModal = Map.from(
                    filtrosActivos,
                  );
                  return FiltrosGenericosMobile(
                    configuraciones: configuracionesFiltros,
                    valoresIniciales: valoresInicialesParaModal,
                    titulo: 'Filtros de Créditos',
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

  String formatearNumero(double numero) {
    final formatCurrency = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '',
      decimalDigits: numero % 1 == 0 ? 0 : 2,
    );
    return formatCurrency.format(numero);
  }
}
