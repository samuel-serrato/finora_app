// Archivo: lib/dialog/credito_detalle_dialog.dart (o como lo hayas nombrado)

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/dialog/credito/pesta%C3%B1a_control_pagos.dart';
import 'package:finora_app/dialog/credito/pesta%C3%B1a_descargables.dart';
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/creditos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/credito_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';

// 1. EL WIDGET PRINCIPAL DEL DIÁLOGO (AHORA CON LÓGICA DE DATOS)
class CreditoDetalleConTabs extends StatefulWidget {
  // Recibe el ID del crédito que se va a mostrar
  final String folio;
  final VoidCallback? onEstadoCambiado; // <--- AÑADE ESTA LÍNEA

  const CreditoDetalleConTabs({
    super.key,
    required this.folio,
    this.onEstadoCambiado, // <--- AÑADE ESTA LÍNEA
  });

  @override
  State<CreditoDetalleConTabs> createState() => _CreditoDetalleConTabsState();
}

class _CreditoDetalleConTabsState extends State<CreditoDetalleConTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreditoService _creditoService = CreditoService();

  // Estados para manejar la carga de datos
  Credito? _creditoData;
  bool _isLoading = true;
  String? _errorMessage;

  // <<< --- NUEVO ESTADO PARA DESCUENTOS --- >>>
  Map<String, double> _descuentos = {};

  // ▼▼▼ 1. AÑADE LA VARIABLE DE ESTADO DE CARGA AQUÍ ▼▼▼
  bool _isSaving = false;

  // --- 2. AÑADE LAS NUEVAS VARIABLES DE ESTADO ---
  // Lista de estados posibles para el dropdown
  final List<String> _posiblesEstados = const [
    'Activo',
    'Finalizado',
    //'Pagado',
  ];
  // Para manejar la carga mientras se actualiza el estado
  bool _isUpdatingStatus = false;
  // Para guardar el estado actual seleccionado en el dropdown
  String? _selectedEstado;

  // Configuración de estilos para los estados (centralizado)
  final Map<String, Map<String, dynamic>> _statusConfig = const {
    'Activo': {
      'color': Colors.green,
      'icon': Icons.check_circle_outline_rounded,
    },
    'Finalizado': {'color': Colors.red, 'icon': Icons.flag_circle_outlined},
    'Pagado': {'color': Colors.purple, 'icon': Icons.paid_outlined},
    'default': {'color': Colors.grey, 'icon': Icons.info_outline_rounded},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Llamamos a la función para cargar los datos cuando el widget se inicializa
    _fetchData();
  }

  // <<< --- FUNCIÓN DE CARGA MODIFICADA --- >>>
  // En lib/dialog/credito_detalle_dialog.dart, dentro de _CreditoDetalleConTabsState

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Paso 1: Obtener los detalles del crédito
    final creditoResponse = await _creditoService.getCreditoDetalles(
      widget.folio,
    ); // <-- USA 'widget.idcredito'

    if (!mounted) return;

    if (creditoResponse.success && creditoResponse.data != null) {
      _creditoData = creditoResponse.data;

      // --- 3. INICIALIZA EL ESTADO SELECCIONADO ---
      _selectedEstado = _creditoData!.estado;

      // Paso 2: Ahora que tenemos los datos, obtenemos el idgrupos
      final descuentoResponse = await _creditoService.getDescuentosRenovacion(
        _creditoData!.idgrupos,
      );
      if (descuentoResponse.success && descuentoResponse.data != null) {
        _descuentos = descuentoResponse.data!;
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage =
            creditoResponse.error ??
            "No se pudieron cargar los datos del crédito.";
        _isLoading = false;
      });
    }
  }

  // --- 4. AÑADE EL MÉTODO PARA MANEJAR EL CAMBIO DE ESTADO Y EL SNACKBAR ---

  Future<void> _handleStatusChange(String? nuevoEstado) async {
    if (nuevoEstado == null ||
        nuevoEstado == _creditoData!.estado ||
        !mounted) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
      _selectedEstado = nuevoEstado;
    });

    // Usamos el idgrupos del crédito cargado
    final response = await _creditoService.actualizarEstadoCredito(
      _creditoData!.idgrupos,
      nuevoEstado,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _creditoData!.estado = nuevoEstado;
      });
      _showSnackBar(
        'Estado actualizado a "$nuevoEstado" correctamente.',
        isError: false,
      );
      // ¡Llama al callback para refrescar la lista externa!
      widget.onEstadoCambiado?.call();
    } else {
      _showSnackBar(
        response.error ?? 'Error al actualizar el estado.',
        isError: true,
      );
      setState(() {
        _selectedEstado = _creditoData!.estado; // Revertir
      });
    }

    setState(() {
      _isUpdatingStatus = false;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper para formatear números como en tu app de desktop
  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;
    // --- OBTÉN EL USERDATA PROVIDER ---
    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );

    // ▼▼▼ ¡LA MODIFICACIÓN PRINCIPAL ESTÁ AQUÍ! ▼▼▼
    // Envolvemos todo el contenido en un WillPopScope.
    // `onWillPop` es una función asíncrona que debe devolver un `bool`.
    // - `true`: permite que la ruta se cierre (por swipe o botón atrás).
    // - `false`: previene que la ruta se cierre.
    // La lógica es simple: si NO estamos guardando (`!_isSaving`), se puede cerrar.
    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: Container(
        //height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        // Usamos un Stack para poder superponer el overlay de carga.
        child: Stack(
          children: [
            // 1. CONTENIDO PRINCIPAL DEL DIÁLOGO
            Column(
              children: [
                // Handle bar: si estamos guardando, lo hacemos invisible para no incitar al swipe.
                AnimatedOpacity(
                  opacity: _isSaving ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoading
                                      ? 'Cargando...'
                                      : (_creditoData?.nombreGrupo ??
                                          'Sin Nombre'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!_isLoading && _creditoData?.folio != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'Folio: ${_creditoData!.folio}',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!_isLoading && _creditoData != null)
                            //_buildModernStatusChip(_creditoData!.estado),
                            // --- ¡ESTE ES EL CAMBIO! ---
                            _buildStatusWidget(
                              userDataProvider.tipoUsuario,
                              colors,
                            ),
                        ],
                      ),
                      if (!_isLoading && _creditoData != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: _buildQuickStats(themeProvider),
                        ),
                    ],
                  ),
                ),

                // --- CUERPO (INDICADOR DE CARGA O PESTAÑAS) ---
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: colors.brandPrimary,
                            ),
                          )
                          : _errorMessage != null
                          ? _buildErrorState(_errorMessage!)
                          : Column(
                            children: [
                              _buildModernTabBar(),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  // ▼▼▼ OTRA MODIFICACIÓN IMPORTANTE ▼▼▼
                                  // Bloquea el swipe entre pestañas si se está guardando algo.
                                  physics:
                                      _isSaving
                                          ? const NeverScrollableScrollPhysics()
                                          : null,
                                  children: [
                                    _buildGeneralTab(themeProvider),
                                    _buildControlTab(themeProvider),
                                    _buildIntegrantesTab(themeProvider),
                                    _buildDescargablesTab(themeProvider),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),

            // 2. OVERLAY DE CARGA (solo visible si _isSaving es true)
            // Este código ya estaba correcto y no necesita cambios.
            // Funciona en conjunto con WillPopScope para un bloqueo total.
            if (_isSaving)
              Positioned.fill(
                child: Container(
                  // Un borde redondeado para que coincida con el diálogo
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: AbsorbPointer(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF4F46E5)),
                            SizedBox(height: 20),
                            Text(
                              'Guardando cambios...',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- El resto de tus widgets y funciones ---
  // El código de abajo no necesita cambios, ya que los callbacks ya están
  // correctamente definidos y pasados en `_buildControlTab`.

  // Widget para organizar las tarjetas en una fila deslizable
  Widget _buildQuickStats(ThemeProvider themeProvider) {
    // Nos aseguramos de que los datos del crédito no sean nulos
    if (_creditoData == null) return const SizedBox.shrink();
    final credito = _creditoData!;

    return Row(
      // Se quita el SingleChildScrollView
      children: [
        Expanded(
          // Se añade Expanded
          child: _buildStatCard(
            'Autorizado',
            '\$${formatearNumero(credito.montoTotal)}',
            Icons.monetization_on_outlined,
            themeProvider,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          // Se añade Expanded
          child: _buildStatCard(
            'Detalles',
            credito.detalles,
            Icons.description_outlined,
            themeProvider,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          // Se añade Expanded
          child: _buildStatCard(
            'Tipo de Crédito',
            credito.tipo,
            Icons.category_outlined,
            themeProvider,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          // Se añade Expanded
          child: _buildStatCard(
            'Plazo',
            '${credito.plazo} ${credito.tipoPlazo}',
            Icons.schedule_rounded,
            themeProvider,
          ),
        ),
      ],
    );
  }

  // Widget mejorado para las tarjetas individuales
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    ThemeProvider themeProvider,
  ) {
    final colors = themeProvider.colors;
    return Container(
      //width: 100, // Ancho fijo para mantener consistencia
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 4,
      ), // Puedes ajustar el padding si es necesario

      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: colors.brandPrimary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2, // Permite hasta 2 líneas
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper para formatear fechas
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_MX').format(date);
    } catch (e) {
      return isoDate.split(' ')[0];
    }
  }

  /// PESTAÑA 1: INFORMACIÓN GENERAL
  /// PESTAÑA 1: INFORMACIÓN GENERAL (LAYOUT DE CUADRÍCULA PERFECTA)
  Widget _buildGeneralTab(ThemeProvider themeProvider) {
    if (_creditoData == null) return const SizedBox.shrink();

    final credito = _creditoData!;

    // La lista de tarjetas se mantiene igual.
    final List<Widget> sections = [
      _buildDetailSection('Información Principal', Icons.info_outline_rounded, [
        _buildInfoItem('Asesor', credito.asesor, Icons.person_pin_rounded),
        _buildInfoItem(
          'Tipo de Crédito',
          credito.tipo,
          Icons.category_outlined,
        ),
        if (credito.detalles.isNotEmpty)
          _buildInfoItem('Detalles', credito.detalles, Icons.notes_rounded),
        _buildInfoItem(
          'Fecha de Creación',
          (credito.fCreacion),
          Icons.event_rounded,
        ),
      ]),
      _buildDetailSection(
        'Resumen Financiero',
        Icons.account_balance_wallet_rounded,
        [
          _buildInfoItem(
            'Monto Autorizado',
            '\$${formatearNumero(credito.montoTotal)}',
            Icons.monetization_on_outlined,
          ),
          _buildInfoItem(
            'Monto Desembolsado',
            '\$${formatearNumero(credito.montoDesembolsado)}',
            Icons.price_check_rounded,
          ),
          _buildInfoItem(
            'Monto a Recuperar',
            '\$${formatearNumero(credito.montoMasInteres)}',
            Icons.replay_circle_filled_rounded,
          ),
          _buildInfoItem(
            'Interés Mensual',
            '${credito.ti_mensual}%',
            Icons.percent_rounded,
          ),
        ],
      ),
      _buildDetailSection('Condiciones del Crédito', Icons.gavel_rounded, [
        _buildInfoItem(
          'Plazo',
          '${credito.plazo} ${credito.tipoPlazo}',
          Icons.schedule_rounded,
        ),
        _buildInfoItem(
          'Día de Pago',
          credito.diaPago,
          Icons.calendar_today_rounded,
        ),
        _buildInfoItem(
          'Periodo del Crédito',
          credito.fechasIniciofin,
          Icons.date_range_rounded,
        ),
        _buildInfoItem(
          credito.tipoPlazo.toLowerCase() == 'semanal'
              ? 'Pago Semanal'
              : 'Pago Quincenal',
          '\$${formatearNumero(credito.pagoCuota)}',
          Icons.payments_outlined,
        ),
      ]),
      _buildDetailSection(
        'Desglose de Intereses y Capital',
        Icons.pie_chart_outline_rounded,
        [
          _buildInfoItem(
            'Interés Mensual (Monto)',
            '\$${formatearNumero(credito.montoTotal * (credito.ti_mensual / 100))}',
            Icons.attach_money,
          ),
          _buildInfoItem(
            'Interés Global',
            '${credito.interesGlobal}%',
            Icons.language_rounded,
          ),
          _buildInfoItem(
            'Interés Total (Monto)',
            '\$${formatearNumero(credito.interesTotal)}',
            Icons.functions_rounded,
          ),
          _buildInfoItem(
            credito.tipoPlazo.toLowerCase() == 'semanal'
                ? 'Capital Semanal'
                : 'Capital Quincenal',
            '\$${formatearNumero(credito.semanalCapital)}',
            Icons.account_balance,
          ),
          _buildInfoItem(
            'Capital Total',
            '\$${formatearNumero(credito.semanalCapital * credito.plazo)}',
            Icons.summarize_rounded,
          ),
          _buildInfoItem(
            credito.tipoPlazo.toLowerCase() == 'semanal'
                ? 'Interés Semanal'
                : 'Interés Quincenal',
            '\$${formatearNumero(credito.semanalInteres)}',
            Icons.trending_up_rounded,
          ),
        ],
      ),
      _buildDetailSection(
        'Garantía',
        Icons.shield_outlined,
        (credito.montoGarantia > 0)
            ? [
              _buildInfoItem(
                'Garantía (%)',
                credito.garantia,
                Icons.shield_moon_outlined,
              ),
              _buildInfoItem(
                'Monto Garantía',
                '\$${formatearNumero(credito.montoGarantia)}',
                Icons.savings_outlined,
              ),
            ]
            : [
              _buildInfoItem(
                'Estado',
                'Sin garantía',
                Icons.info_outline_rounded,
              ),
            ],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child:
          context.isMobile
              // VISTA MÓVIL: Se mantiene la columna, que es perfecta.
              ? Column(
                children:
                    sections.map((section) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: section,
                      );
                    }).toList(),
              )
              // VISTA TABLET/DESKTOP: El generador de filas de cuadrícula.
              : LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 20.0;
                  // Ajustamos el umbral para 3 columnas.
                  // DESPUÉS (Recomendado)
                  final int crossAxisCount =
                      constraints.maxWidth > kDesktopBreakpoint ? 3 : 2;

                  // 1. Agrupamos las tarjetas en filas.
                  final List<List<Widget>> rows = [];
                  for (int i = 0; i < sections.length; i += crossAxisCount) {
                    int end =
                        (i + crossAxisCount < sections.length)
                            ? i + crossAxisCount
                            : sections.length;
                    rows.add(sections.sublist(i, end));
                  }

                  // 2. Construimos la columna de filas.
                  return Column(
                    children: List.generate(rows.length, (rowIndex) {
                      final List<Widget> rowItems = rows[rowIndex];

                      return Padding(
                        // 3. Añadimos espaciado vertical entre filas, excepto en la última.
                        padding: EdgeInsets.only(
                          bottom: rowIndex < rows.length - 1 ? spacing : 0,
                        ),
                        child: IntrinsicHeight(
                          // <-- Widget clave para igualar alturas
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .stretch, // <-- Clave para que se estiren
                            children: List.generate(crossAxisCount, (
                              itemIndex,
                            ) {
                              // 4. Si hay una tarjeta para esta posición, la mostramos.
                              if (itemIndex < rowItems.length) {
                                return Expanded(
                                  child: Padding(
                                    // 5. Añadimos espaciado horizontal, excepto en el último elemento de la fila.
                                    padding: EdgeInsets.only(
                                      right:
                                          itemIndex < crossAxisCount - 1
                                              ? spacing
                                              : 0,
                                    ),
                                    child: rowItems[itemIndex],
                                  ),
                                );
                              } else {
                                // 6. Si no hay tarjeta (última fila incompleta), añadimos un espaciador.
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right:
                                          itemIndex < crossAxisCount - 1
                                              ? spacing
                                              : 0,
                                    ),
                                    child:
                                        Container(), // Un contenedor vacío que ocupa espacio.
                                  ),
                                );
                              }
                            }),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
    );
  }

  /// PESTAÑA 2: CONTROL DE PAGOS
  Widget _buildControlTab(ThemeProvider themeProvider) {
    if (_creditoData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeProvider.colors.brandPrimary),
            const SizedBox(height: 16),
            Text(
              "Cargando información del crédito...",
              style: TextStyle(color: themeProvider.colors.textSecondary),
            ),
          ],
        ),
      );
    }
    // El código aquí ya es correcto, pasa las funciones que modifican `_isSaving`.
    return ControlPagosTab(
      idCredito: _creditoData!.idcredito,
      montoGarantia: _creditoData!.montoGarantia,
      clientesParaRenovar: _creditoData!.clientesMontosInd,
      pagoCuotaTotal: _creditoData!.pagoCuota,
      // ▼▼▼▼▼▼ AGREGA ESTA LÍNEA AQUÍ ▼▼▼▼▼▼
      montoDesembolsado: _creditoData!.montoDesembolsado,

      // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
      onDataChanged: () {
        AppLogger.log("Callback onDataChanged llamado. Refrescando datos...");
        _fetchData();
      },
      onSaveStarted: () {
        if (mounted) {
          setState(() => _isSaving = true);
        }
      },
      onSaveFinished: () {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      },
    );
  }

  // <<< NUEVA FUNCIÓN HELPER: Para abreviar el tipo de plazo >>>
  String _getPlazoAbbreviation(String tipoPlazo) {
    switch (tipoPlazo.toLowerCase()) {
      case 'semanal':
        return 'Sem.';
      case 'quincenal':
        return 'Qnal.';
      case 'catorcenal':
        return 'Cat.';
      case 'mensual':
        return 'Mens.';
      default:
        // Si es un tipo no esperado, devuelve una abreviatura genérica.
        return tipoPlazo.length > 3
            ? '${tipoPlazo.substring(0, 3)}.'
            : tipoPlazo;
    }
  }

  // --- El resto de tus widgets (Integrantes, Descargables, Helpers) se mantienen igual ---
  // (Omitidos por brevedad, pero deben estar aquí)
  // --- WIDGET PRINCIPAL CON LA LÓGICA RESPONSIVE CORRECTA ---
  Widget _buildIntegrantesTab(ThemeProvider themeProvider) {
    if (_creditoData == null || _creditoData!.clientesMontosInd.isEmpty) {
      return _buildEmptyState(
        'Sin Integrantes',
        'No se encontraron integrantes para este crédito.',
        Icons.people_outline_rounded,
      );
    }

    final plazoAbbr = _getPlazoAbbreviation(_creditoData!.tipoPlazo);

    // --- CÁLCULO DE TOTALES ---
    final clientes = _creditoData!.clientesMontosInd;
    double sumCapitalIndividual = 0;
    double sumMontoDesembolsado = 0;
    double sumPeriodoCapital = 0;
    double sumPeriodoInteres = 0;
    double sumTotalCapital = 0;
    double sumTotalIntereses = 0;
    double sumCapitalMasInteres = 0;
    double sumTotal = 0;

    final garantiaPorcentaje =
        double.tryParse(_creditoData!.garantia.replaceAll('%', '')) ?? 0.0;

    for (var cliente in clientes) {
      final descuento = _descuentos[cliente.idclientes] ?? 0.0;
      final garantiaMonto =
          cliente.capitalIndividual * (garantiaPorcentaje / 100);
      final montoDesembolsadoIndividual =
          cliente.capitalIndividual - descuento - garantiaMonto;

      sumCapitalIndividual += cliente.capitalIndividual;
      sumMontoDesembolsado += montoDesembolsadoIndividual;
      sumPeriodoCapital += cliente.periodoCapital;
      sumPeriodoInteres += cliente.periodoInteres;
      sumTotalCapital += cliente.totalCapital;
      // DESPUÉS (Cálculo corregido para la suma)
      sumTotalIntereses += (cliente.periodoInteres * _creditoData!.plazo);
      sumCapitalMasInteres += cliente.capitalMasInteres;
      sumTotal += cliente.total;
    }
    // <<< NUEVO: Cálculo del total basado en la cuota redondeada >>>
    final sumTotalRedondeado = _creditoData!.pagoCuota * _creditoData!.plazo;

    // --- LÓGICA RESPONSIVE ---
    if (context.isDesktop) {
      // VISTA TABLET Y DESKTOP: Muestra la tabla de datos
      return _buildResponsiveIntegrantesTable(
        clientes: clientes,
        themeProvider: themeProvider,
        plazoAbbr: plazoAbbr,
        sumCapitalIndividual: sumCapitalIndividual,
        sumMontoDesembolsado: sumMontoDesembolsado,
        sumPeriodoCapital: sumPeriodoCapital,
        sumPeriodoInteres: sumPeriodoInteres,
        sumTotalCapital: sumTotalCapital,
        sumTotalIntereses: sumTotalIntereses,
        sumCapitalMasInteres: sumCapitalMasInteres,
        sumTotal: sumTotal,
        // <<< NUEVO: Pasamos los datos de redondeo a la tabla >>>
        pagoCuotaRedondeado: _creditoData!.pagoCuota,
        totalRedondeado: sumTotalRedondeado,
      );
    } else {
      // VISTA MÓVIL: Muestra las tarjetas expandibles
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clientes.length + 1,
        itemBuilder: (context, index) {
          if (index == clientes.length) {
            // La tarjeta de totales ya recibe los datos de redondeo y los maneja internamente.
            return _buildTotalesCard(
              sumCapitalIndividual: sumCapitalIndividual,
              sumMontoDesembolsado: sumMontoDesembolsado,
              sumPeriodoCapital: sumPeriodoCapital,
              sumPeriodoInteres: sumPeriodoInteres,
              sumTotalCapital: sumTotalCapital,
              sumTotalIntereses: sumTotalIntereses,
              sumCapitalMasInteres: sumCapitalMasInteres,
              sumTotal: sumTotal,
              pagoCuotaRedondeado: _creditoData!.pagoCuota,
              totalRedondeado: sumTotalRedondeado,
              themeProvider: themeProvider,
              plazoAbbr: plazoAbbr,
            );
          }
          final cliente = clientes[index];
          return _buildIntegranteCard(cliente, themeProvider, plazoAbbr);
        },
      );
    }
  }

  //==============================================================================
  // <<< INICIO: NUEVA IMPLEMENTACIÓN DE TABLA RESPONSIVA >>>
  //==============================================================================

  // Widget principal que construye la estructura de la tabla responsiva
  //==============================================================================
  // <<< TABLA RESPONSIVA PARA DESKTOP (CON LÓGICA DE REDONDEO) >>>
  //==============================================================================
  // En lib/dialog/credito_detalle_dialog.dart, dentro de _CreditoDetalleConTabsState

  //==============================================================================
  // <<< TABLA RESPONSIVA CORREGIDA PARA MANEJAR OVERFLOW >>>
  //==============================================================================
  Widget _buildResponsiveIntegrantesTable({
    required List<ClienteMonto> clientes,
    required ThemeProvider themeProvider,
    required String plazoAbbr,
    required double sumCapitalIndividual,
    required double sumMontoDesembolsado,
    required double sumPeriodoCapital,
    required double sumPeriodoInteres,
    required double sumTotalCapital,
    required double sumTotalIntereses,
    required double sumCapitalMasInteres,
    required double sumTotal,
    required double pagoCuotaRedondeado,
    required double totalRedondeado,
  }) {
    final colors = themeProvider.colors;
    final garantiaPorcentaje =
        double.tryParse(_creditoData!.garantia.replaceAll('%', '')) ?? 0.0;
    final int flexNombre = 3;
    final int flexMonto = 2;

    final bool mostrarRedondeo = pagoCuotaRedondeado != sumCapitalMasInteres;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          // --- FILA DE ENCABEZADO (queda fija arriba) ---
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: colors.backgroundCardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildHeaderCell(
                  'Nombre',
                  flexNombre,
                  colors,
                  alignment: TextAlign.left,
                ),
                _buildHeaderCell('Autorizado', flexMonto, colors),
                _buildHeaderCell('Desembolsado', flexMonto, colors),
                _buildHeaderCell('Capital $plazoAbbr', flexMonto, colors),
                _buildHeaderCell('Interés $plazoAbbr', flexMonto, colors),
                _buildHeaderCell('Total Capital', flexMonto, colors),
                _buildHeaderCell('Total Intereses', flexMonto, colors),
                _buildHeaderCell('Pago $plazoAbbr', flexMonto, colors),
                _buildHeaderCell('Pago Total', flexMonto, colors),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // --- INICIO DE LA CORRECCIÓN ---
          // Usamos Expanded para que la lista ocupe todo el espacio vertical disponible.
          // ListView.builder es eficiente porque solo construye las filas que son visibles en pantalla.
          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                final descuento = _descuentos[cliente.idclientes] ?? 0.0;
                final garantiaMonto =
                    cliente.capitalIndividual * (garantiaPorcentaje / 100);
                final montoDesembolsado =
                    cliente.capitalIndividual - descuento - garantiaMonto;
                final tieneDescuento = descuento > 0.0 || garantiaMonto > 0.0;

                // El contenedor de cada fila se crea aquí dentro
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.divider, width: 1.0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildDataCell(
                        Text(cliente.nombreCompleto),
                        flexNombre,
                        colors,
                        alignment: Alignment.centerLeft,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.capitalIndividual)}'),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '\$${formatearNumero(montoDesembolsado)}',
                              style: TextStyle(
                                color:
                                    tieneDescuento
                                        ? Colors.green.shade600
                                        : colors.textSecondary,
                                fontWeight:
                                    tieneDescuento
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (tieneDescuento)
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Tooltip(
                                  richMessage: WidgetSpan(
                                    baseline: TextBaseline.alphabetic,
                                    child: _DesgloseTooltipContent(
                                      capitalIndividual:
                                          cliente.capitalIndividual,
                                      garantiaMonto: garantiaMonto,
                                      descuento: descuento,
                                      themeProvider: themeProvider,
                                    ),
                                  ),
                                  waitDuration: Duration.zero,
                                  showDuration: const Duration(seconds: 6),
                                  preferBelow: false,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.periodoCapital)}'),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.periodoInteres)}'),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.totalCapital)}'),
                        flexMonto,
                        colors,
                      ),
                      // DESPUÉS (Cálculo corregido)
                      _buildDataCell(
                        Text(
                          '\$${formatearNumero(cliente.periodoInteres * _creditoData!.plazo)}',
                        ),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.capitalMasInteres)}'),
                        flexMonto,
                        colors,
                      ),
                      _buildDataCell(
                        Text('\$${formatearNumero(cliente.total)}'),
                        flexMonto,
                        colors,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // --- FIN DE LA CORRECCIÓN ---

          // --- FILA DE TOTALES (queda fija abajo) ---
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: colors.brandPrimary.withOpacity(0.08),
              borderRadius:
                  mostrarRedondeo
                      ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                      : BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTotalCell(
                  'Totales',
                  flexNombre,
                  colors,
                  alignment: TextAlign.left,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumCapitalIndividual)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumMontoDesembolsado)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumPeriodoCapital)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumPeriodoInteres)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumTotalCapital)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumTotalIntereses)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumCapitalMasInteres)}',
                  flexMonto,
                  colors,
                ),
                _buildTotalCell(
                  '\$${formatearNumero(sumTotal)}',
                  flexMonto,
                  colors,
                ),
              ],
            ),
          ),

          if (mostrarRedondeo)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  _buildTotalCell(
                    'Redondeado',
                    flexNombre,
                    colors,
                    alignment: TextAlign.left,
                  ),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell('', flexMonto, colors),
                  _buildTotalCell(
                    '\$${formatearNumero(pagoCuotaRedondeado)}',
                    flexMonto,
                    colors,
                  ),
                  _buildTotalCell(
                    '\$${formatearNumero(totalRedondeado)}',
                    flexMonto,
                    colors,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Helpers para construir las celdas de la tabla responsiva ---

  Widget _buildHeaderCell(
    String text,
    int flex,
    AppColors colors, {
    TextAlign alignment = TextAlign.center,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDataCell(
    Widget child,
    int flex,
    AppColors colors, {
    Alignment alignment = Alignment.center,
  }) {
    // El DefaultTextStyle asegura que todos los Text dentro de esta celda tengan el estilo base.
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'TuFuente',
          ), // Asegúrate de usar la fuente correcta
          child: child,
        ),
      ),
    );
  }

  Widget _buildTotalCell(
    String text,
    int flex,
    AppColors colors, {
    TextAlign alignment = TextAlign.center,
  }) {
    bool isLabel = text == 'Totales';
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isLabel ? colors.textPrimary : colors.brandPrimary,
        ),
      ),
    );
  }

  //==============================================================================
  // <<< FIN: NUEVA IMPLEMENTACIÓN DE TABLA RESPONSIVA >>>
  //==============================================================================

  // <<< --- WIDGET DE TABLA MEJORADO PARA DESKTOP --- >>>
  // <<< --- WIDGET DE TABLA MEJORADO CON TODOS LOS DATOS --- >>>
  // <<< WIDGET DE TABLA COMPLETAMENTE REFINADO >>>
  Widget _buildIntegrantesTable({
    required List<ClienteMonto> clientes,
    required ThemeProvider themeProvider,
    required String plazoAbbr,
    // ... todos los parámetros de sumas
    required double sumCapitalIndividual,
    required double sumMontoDesembolsado,
    required double sumPeriodoCapital,
    required double sumPeriodoInteres,
    required double sumTotalCapital,
    required double sumTotalIntereses,
    required double sumCapitalMasInteres,
    required double sumTotal,
  }) {
    final colors = themeProvider.colors;

    // <<< 1. SOLUCIÓN AL ANCHO: Usamos LayoutBuilder para obtener el ancho disponible >>>
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          // <<< Envolvemos la tabla para forzar un ancho mínimo >>>
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              // --- ESTILOS VISUALES RESTAURADOS ---
              headingRowHeight: 50,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 70,
              columnSpacing: 20,
              horizontalMargin: 12,
              // <<< 2. ESTILO MINIMALISTA RESTAURADO >>>
              headingRowColor: MaterialStateProperty.all(
                colors.backgroundCardDark,
              ),
              headingTextStyle: TextStyle(
                color: colors.textPrimary, // Color de texto primario
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              // Se quita el borde para un look más limpio
              // border: TableBorder.all(...)

              // --- Columnas y filas se mantienen igual ---
              columns: [
                DataColumn(label: Center(child: Text('Nombre'))),
                DataColumn(
                  label: Center(child: Text('Autorizado')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Desembolsado')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Capital $plazoAbbr')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Interés $plazoAbbr')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Total Capital')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Total Intereses')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Pago $plazoAbbr')),
                  numeric: true,
                ),
                DataColumn(
                  label: Center(child: Text('Pago Total')),
                  numeric: true,
                ),
              ],
              rows: [
                ...clientes.map((cliente) {
                  // ... (toda la lógica de la fila se mantiene exactamente igual a la versión anterior)
                  final descuento = _descuentos[cliente.idclientes] ?? 0.0;
                  final garantiaPorcentaje =
                      double.tryParse(
                        _creditoData!.garantia.replaceAll('%', ''),
                      ) ??
                      0.0;
                  final garantiaMonto =
                      cliente.capitalIndividual * (garantiaPorcentaje / 100);
                  final montoDesembolsado =
                      cliente.capitalIndividual - descuento - garantiaMonto;
                  final tieneDescuento = descuento > 0.0 || garantiaMonto > 0.0;
                  final dataTextStyle = TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  );

                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 130,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            cliente.nombreCompleto,
                            style: dataTextStyle.copyWith(
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.capitalIndividual)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '\$${formatearNumero(montoDesembolsado)}',
                              style: dataTextStyle.copyWith(
                                color:
                                    tieneDescuento
                                        ? Colors.green.shade600
                                        : colors.textSecondary,
                                fontWeight:
                                    tieneDescuento
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            if (tieneDescuento)
                              Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Tooltip(
                                  richMessage: WidgetSpan(
                                    baseline: TextBaseline.alphabetic,
                                    child: _DesgloseTooltipContent(
                                      capitalIndividual:
                                          cliente.capitalIndividual,
                                      garantiaMonto: garantiaMonto,
                                      descuento: descuento,
                                      themeProvider: themeProvider,
                                    ),
                                  ),
                                  waitDuration: Duration.zero,
                                  showDuration: const Duration(seconds: 6),
                                  preferBelow: false,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.periodoCapital)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.periodoInteres)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.totalCapital)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.totalIntereses)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.capitalMasInteres)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${formatearNumero(cliente.total)}',
                          style: dataTextStyle,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }).toList(),

                // Fila de TOTALES (el helper se actualiza abajo)
                _buildTotalesDataRow(
                  colors: colors,
                  sumCapitalIndividual: sumCapitalIndividual,
                  sumMontoDesembolsado: sumMontoDesembolsado,
                  sumPeriodoCapital: sumPeriodoCapital,
                  sumPeriodoInteres: sumPeriodoInteres,
                  sumTotalCapital: sumTotalCapital,
                  sumTotalIntereses: sumTotalIntereses,
                  sumCapitalMasInteres: sumCapitalMasInteres,
                  sumTotal: sumTotal,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // <<< HELPER DE FILA DE TOTALES CON ESTILO RESTAURADO >>>
  DataRow _buildTotalesDataRow({
    required AppColors colors,
    required double sumCapitalIndividual,
    required double sumMontoDesembolsado,
    required double sumPeriodoCapital,
    required double sumPeriodoInteres,
    required double sumTotalCapital,
    required double sumTotalIntereses,
    required double sumCapitalMasInteres,
    required double sumTotal,
  }) {
    // <<< 2. ESTILO MINIMALISTA RESTAURADO >>>
    final totalsTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: colors.brandPrimary, // Vuelve al color primario
      fontSize: 13,
    );

    return DataRow(
      color: MaterialStateProperty.all(
        colors.brandPrimary.withOpacity(0.08),
      ), // Vuelve al color translúcido
      cells: [
        DataCell(
          Text(
            'Totales',
            style: totalsTextStyle.copyWith(color: colors.textPrimary),
          ),
        ), // 'Totales' en color de texto normal
        DataCell(
          Text(
            '\$${formatearNumero(sumCapitalIndividual)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumMontoDesembolsado)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumPeriodoCapital)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumPeriodoInteres)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumTotalCapital)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumTotalIntereses)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumCapitalMasInteres)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
        DataCell(
          Text(
            '\$${formatearNumero(sumTotal)}',
            style: totalsTextStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // <<< WIDGET ACTUALIZADO: La tarjeta de totales ahora muestra todos los campos >>>
  //==============================================================================
  // <<< TARJETA DE TOTALES PARA MÓVIL (CON LÓGICA DE REDONDEO) >>>
  //==============================================================================
  Widget _buildTotalesCard({
    required double sumCapitalIndividual,
    required double sumMontoDesembolsado,
    required double sumPeriodoCapital,
    required double sumPeriodoInteres,
    required double sumTotalCapital,
    required double sumTotalIntereses,
    required double sumCapitalMasInteres,
    required double sumTotal,
    required double pagoCuotaRedondeado,
    required double totalRedondeado,
    required ThemeProvider themeProvider,
    required String plazoAbbr,
  }) {
    final colors = themeProvider.colors;
    // <<< CAMBIO: La misma condición de redondeo, ahora local a este widget >>>
    final bool mostrarRedondeo = pagoCuotaRedondeado != sumCapitalMasInteres;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.brandPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.brandPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Encabezado de la tarjeta sin cambios)
          Row(
            children: [
              const Icon(
                Icons.functions_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              const Text(
                'Totales del Grupo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white30, height: 24),

          _buildTotalRow(
            'Suma Autorizado',
            '\$${formatearNumero(sumCapitalIndividual)}',
            colors,
          ),
          _buildTotalRow(
            'Suma Desembolsado',
            '\$${formatearNumero(sumMontoDesembolsado)}',
            colors,
          ),
          _buildTotalRow(
            'Suma Pago Total',
            '\$${formatearNumero(sumTotal)}',
            colors,
          ),

          const Divider(color: Colors.white30, height: 24),

          _buildTotalRow(
            'Suma Capital $plazoAbbr',
            '\$${formatearNumero(sumPeriodoCapital)}',
            colors,
          ),
          _buildTotalRow(
            'Suma Interés $plazoAbbr',
            '\$${formatearNumero(sumPeriodoInteres)}',
            colors,
          ),
          _buildTotalRow(
            'Suma Pago $plazoAbbr',
            '\$${formatearNumero(sumCapitalMasInteres)}',
            colors,
          ),

          const Divider(color: Colors.white30, height: 24),

          _buildTotalRow(
            'Suma Total Capital',
            '\$${formatearNumero(sumTotalCapital)}',
            colors,
          ),
          _buildTotalRow(
            'Suma Total Intereses',
            '\$${formatearNumero(sumTotalIntereses)}',
            colors,
          ),

          // <<< NUEVO: Sección condicional de redondeo para la tarjeta móvil >>>
          if (mostrarRedondeo)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white30, height: 20),
                  Text(
                    "Redondeo Aplicado",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTotalRow(
                    'Pago $plazoAbbr Redondeado',
                    '\$${formatearNumero(pagoCuotaRedondeado)}',
                    colors,
                  ),
                  _buildTotalRow(
                    'Pago Total Redondeado',
                    '\$${formatearNumero(totalRedondeado)}',
                    colors,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // <<< NUEVO HELPER (o mantenido si ya lo tenías): Para las filas de la tarjeta de totales >>>
  Widget _buildTotalRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          SelectableText(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets existentes (sin cambios, solo para contexto) ---

  Widget _buildIntegranteCard(
    ClienteMonto cliente,
    ThemeProvider themeProvider,
    String plazoAbbr, // <<< CAMBIO: Nuevo parámetro
  ) {
    // ... tu código existente para _buildIntegranteCard no necesita cambios
    final colors = themeProvider.colors;

    final descuento = _descuentos[cliente.idclientes] ?? 0.0;
    final garantiaPorcentaje =
        double.tryParse(_creditoData!.garantia.replaceAll('%', '')) ?? 0.0;
    final garantiaMonto =
        cliente.capitalIndividual * (garantiaPorcentaje / 100);
    final montoDesembolsado =
        cliente.capitalIndividual - descuento - garantiaMonto;
    final tieneDescuento = descuento > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 16, right: 12),
        leading: CircleAvatar(
          maxRadius: 14,
          backgroundColor: colors.brandPrimary.withOpacity(0.1),
          child: Icon(
            Icons.person_outline_rounded,
            color: colors.brandPrimary,
            size: 20,
          ),
        ),
        title: Text(
          cliente.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 14,
          ),
        ),

        subtitle: Container(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Autorizado:',
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
              Text(
                '\$${formatearNumero(cliente.capitalIndividual)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.backgroundCardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRowIntegrantes(
                    'Monto a Desembolsar',
                    '\$${formatearNumero(montoDesembolsado)}',
                    Icons.price_check_rounded,
                    themeProvider,
                    isWarning: tieneDescuento,
                    // <<< --- AQUÍ ESTÁ EL CAMBIO PRINCIPAL --- >>>
                    tooltipContent:
                        tieneDescuento
                            ? _DesgloseTooltipContent(
                              capitalIndividual: cliente.capitalIndividual,
                              garantiaMonto: garantiaMonto,
                              descuento: descuento,
                              themeProvider: themeProvider,
                            )
                            : null,
                  ),
                  const Divider(height: 16),
                  _buildDetailRowIntegrantes(
                    'Pago por ${plazoAbbr}', // <<< CAMBIO: Etiqueta dinámica
                    '\$${formatearNumero(cliente.capitalMasInteres)}',
                    Icons.payments_outlined,
                    themeProvider,
                  ),
                  _buildDetailRowIntegrantes(
                    'Pago Total',
                    '\$${formatearNumero(cliente.total)}',
                    Icons.functions_rounded,
                    themeProvider,
                  ),
                  const Divider(height: 16),
                  _buildDetailRowIntegrantes(
                    'Capital por ${plazoAbbr}', // <<< CAMBIO: Etiqueta dinámica
                    '\$${formatearNumero(cliente.periodoCapital)}',
                    Icons.account_balance,
                    themeProvider,
                  ),
                  _buildDetailRowIntegrantes(
                    'Interés por ${plazoAbbr}', // <<< CAMBIO: Etiqueta dinámica
                    '\$${formatearNumero(cliente.periodoInteres)}',
                    Icons.trending_up_rounded,
                    themeProvider,
                  ),
                  const Divider(height: 16),
                  _buildDetailRowIntegrantes(
                    'Total Capital',
                    '\$${formatearNumero(cliente.totalCapital)}',
                    Icons.summarize_rounded,
                    themeProvider,
                  ),
                  // DESPUÉS (Cálculo corregido)
                  _buildDetailRowIntegrantes(
                    'Total Intereses',
                    '\$${formatearNumero(cliente.periodoInteres * _creditoData!.plazo)}',
                    Icons.leaderboard_rounded,
                    themeProvider,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // <<< --- MODIFICADO: Ahora acepta un Widget para el tooltip y lo aplica solo al ícono --- >>>
  Widget _buildDetailRowIntegrantes(
    String label,
    String value,
    IconData icon,
    ThemeProvider themeProvider, {
    bool isWarning = false,
    Widget? tooltipContent, // <-- Cambio de String a Widget
  }) {
    final colors = themeProvider.colors;
    final valueColor = isWarning ? Colors.green.shade600 : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.brandPrimary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const Spacer(),
          SelectableText(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: 14,
            ),
          ),

          // --- Lógica del Tooltip completamente nueva ---
          if (tooltipContent != null) const SizedBox(width: 8),
          if (tooltipContent != null)
            Tooltip(
              // La magia está aquí:
              richMessage: WidgetSpan(
                baseline:
                    TextBaseline.alphabetic, // Evita errores de renderizado
                child: tooltipContent,
              ),
              // Estilos del tooltip en sí:
              waitDuration: Duration.zero,
              showDuration: Duration(seconds: 5),
              preferBelow: false, // Intenta mostrarlo arriba
              // Quita la decoración por defecto para que nuestro widget personalizado brille
              decoration: BoxDecoration(color: Colors.transparent),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.green.shade600,
              ),
            ),
        ],
      ),
    );
  }

  /*  Widget _buildDescargablesTab(ThemeProvider themeProvider) {
    return _buildEmptyState(
      'Sin Descargables',
      'Aún no hay documentos o archivos para este crédito.',
      Icons.cloud_download_outlined,
    );
  } */

  Widget _buildDescargablesTab(ThemeProvider themeProvider) {
    // Nos aseguramos de que los datos del crédito estén disponibles
    // antes de mostrar las opciones de descarga.
    if (_creditoData == null) {
      return const Center(child: Text("Cargando datos del crédito..."));
    }

    // Retornamos nuestro nuevo widget, pasándole los datos del crédito.
    return PaginaDescargablesMobile(credito: _creditoData!);
  }

  Widget _buildErrorState(String message) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.brandPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Aquí van el resto de tus widgets helper: _buildModernTabBar, _buildDetailSection, _buildInfoItem, _buildEmptyState, _buildModernStatusChip, etc.)
  // NO los repito para no hacer el código tan largo, pero deben estar aquí.
  // ...
  Widget _buildModernTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 8),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Control'),
          Tab(text: 'Integrantes'),
          Tab(text: 'Descargas'),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData titleIcon,
    List<Widget> items,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: colors.brandPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    bool isExpanded = false,
  }) {
    final colors = Provider.of<ThemeProvider>(context, listen: false).colors;
    // Ahora no se oculta aquí, la lógica está en el constructor de la lista
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment:
            isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 0),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: isExpanded ? 1.4 : 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.brandPrimary.withOpacity(0.1),
              ),
              child: Icon(icon, size: 48, color: colors.brandPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Al final de la clase _CreditoDetalleConTabsState

  /// Widget que decide si mostrar el chip estático o el dropdown editable.
  Widget _buildStatusWidget(String tipoUsuario, dynamic colors) {
    if (tipoUsuario == 'Admin') {
      return _buildAdminStatusDropdown(colors);
    }
    return _buildModernStatusChip(_creditoData!.estado);
  }

  /// Widget reutilizable para el contenido (Icono + Texto).
  Widget _buildStatusRow(String estado) {
    final config = _statusConfig[estado] ?? _statusConfig['default']!;
    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          estado,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// El NUEVO dropdown para administradores con estilo de chip.
  Widget _buildAdminStatusDropdown(dynamic colors) {
    final config = _statusConfig[_selectedEstado] ?? _statusConfig['default']!;
    final color = config['color'] as Color;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedEstado,
              onChanged: _isUpdatingStatus ? null : _handleStatusChange,
              dropdownColor: colors.backgroundCard,
              selectedItemBuilder: (context) {
                return _posiblesEstados.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: _buildStatusRow(item),
                  );
                }).toList();
              },
              items:
                  _posiblesEstados.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: _buildStatusRow(value),
                    );
                  }).toList(),
              icon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_drop_down_rounded, color: color),
              ),
              isDense: true,
            ),
          ),
        ),
        if (_isUpdatingStatus)
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
          ),
      ],
    );
  }

  // 3. REFACTORIZA TU ANTIGUO `_buildModernStatusChip` PARA USAR LA LÓGICA CENTRALIZADA
  Widget _buildModernStatusChip(String estado) {
    final config = _statusConfig[estado] ?? _statusConfig['default']!;
    final color = config['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: _buildStatusRow(estado), // Reutilizamos el nuevo widget
    );
  }
}

// <<< --- NUEVO WIDGET: El contenido personalizado para el tooltip de desglose --- >>>
class _DesgloseTooltipContent extends StatelessWidget {
  final double capitalIndividual;
  final double garantiaMonto;
  final double descuento;
  final ThemeProvider themeProvider;

  const _DesgloseTooltipContent({
    Key? key,
    required this.capitalIndividual,
    required this.garantiaMonto,
    required this.descuento,
    required this.themeProvider,
  }) : super(key: key);

  // Helper para las filas del desglose
  Widget _buildDesgloseRow(
    String label,
    String value,
    bool isDarkMode, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = themeProvider.isDarkMode;
    final double montoDesembolsado =
        capitalIndividual - garantiaMonto - descuento;

    // Este es el contenedor que le da el estilo al tooltip
    return Container(
      padding: EdgeInsets.all(12),
      constraints: BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Desglose del Desembolso",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Divider(
            color: isDarkMode ? Colors.white30 : Colors.black26,
            height: 15,
          ),
          _buildDesgloseRow(
            "Monto Autorizado",
            "\$${formatearNumero(capitalIndividual)}",
            isDarkMode,
          ),
          _buildDesgloseRow(
            "(-) Garantía",
            "-\$${formatearNumero(garantiaMonto)}",
            isDarkMode,
          ),
          _buildDesgloseRow(
            "(-) Descuento",
            "-\$${formatearNumero(descuento)}",
            isDarkMode,
          ),
          Divider(
            color: isDarkMode ? Colors.white30 : Colors.black26,
            height: 10,
          ),
          _buildDesgloseRow(
            "(=) Total a Recibir",
            "\$${formatearNumero(montoDesembolsado)}",
            isDarkMode,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // Helper para formatear números como en tu app de desktop
  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }
}
