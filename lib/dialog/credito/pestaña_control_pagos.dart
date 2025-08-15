import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/models/cliente_monto.dart';
import 'package:finora_app/models/credito_totales.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/widgets/AdvancedOptionsSheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// --- IMPORTACIONES NECESARIAS ---
import 'package:finora_app/models/pago.dart';
// <-- IMPORTA EL MODELO DEL CLIENTE PARA RENOVACIÓN
import 'package:finora_app/services/pago_service.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:provider/provider.dart';

import '../../utils/app_logger.dart';

class ControlPagosTab extends StatefulWidget {
  // --- PARÁMETROS FINALES Y COMPLETOS ---
  final String idCredito;
  final double montoGarantia;
  final List<ClienteMonto> clientesParaRenovar;
  final double pagoCuotaTotal;
  final VoidCallback onDataChanged; // Callback para notificar al padre

  // ▼▼▼ AÑADE ESTOS 2 PARÁMETROS NUEVOS ▼▼▼
  final VoidCallback onSaveStarted;
  final VoidCallback onSaveFinished;
  // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲

  const ControlPagosTab({
    Key? key,
    required this.idCredito,
    required this.montoGarantia,
    required this.clientesParaRenovar,
    required this.pagoCuotaTotal,
    required this.onDataChanged,
    // ▼▼▼ AÑADE ESTOS 2 PARÁMETROS NUEVOS AL CONSTRUCTOR ▼▼▼
    required this.onSaveStarted,
    required this.onSaveFinished,
    // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲
  }) : super(key: key);

  @override
  _ControlPagosTabState createState() => _ControlPagosTabState();
}

// --- Pega este código completo reemplazando tu clase _ControlPagosTabState ---

class _ControlPagosTabState extends State<ControlPagosTab>
    with TickerProviderStateMixin {
  final PagoService _pagoService = PagoService();
  late Future<ApiResponse<List<Pago>>> _pagosFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _totalSemanasDelCredito = 0;

  // --- ESTADO PARA LA UI ---
  List<Pago> _pagosActuales = [];
  // <-- CAMBIO CLAVE (1/3): Añadimos una lista para guardar el estado original de los pagos.
  List<Pago> _pagosOriginales = [];

  final Set<int> _semanasModificadas = {};
  final Map<int, DateTime> _fechasPagoSeleccionadas = {};

  final Map<int, DateTime> _fechaNuevoAbono = {};

  // --- ESTADO PARA CÁLCULOS EN TIEMPO REAL ---
  final Map<int, TextEditingController> _montoParcialControllers = {};
  final Map<int, double> _saldosCalculados = {};
  final Map<int, TextEditingController> _nuevoAbonoControllers = {};
  final Map<int, bool> _mostrandoFormularioAbono = {};
  final Map<int, double> _saldoRestanteCalculado = {};

  bool _isSaving = false;

  final Map<int, double> _saldosFavorEnTiempoReal = {};
  final Map<int, double> _saldosContraEnTiempoReal = {};

  final AppColors colors = AppColors();

  @override
  void initState() {
    super.initState();
    _recargarPagos();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _recargarPagos() {
    if (mounted) {
      setState(() {
        _saldosFavorEnTiempoReal.clear();
        _saldosContraEnTiempoReal.clear();
        _montoParcialControllers.forEach((_, c) => c.clear());
        _nuevoAbonoControllers.forEach((_, c) => c.clear());
        _semanasModificadas.clear();
        _pagosFuture = _pagoService.getCalendarioPagos(widget.idCredito);
        // dentro de la función _recargarPagos(), añade esta línea
        _fechasPagoSeleccionadas.clear();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _montoParcialControllers.forEach((_, controller) => controller.dispose());
    _nuevoAbonoControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // =======================================================================
  // =======================================================================
  //               AQUÍ COMIENZAN LOS WIDGETS Y LA LÓGICA
  //              (No es necesario cambiar nada debajo de esta línea,
  //               solo he añadido los nuevos widgets para la vista de escritorio)
  // =======================================================================
  // =======================================================================

  // =======================================================================
  // INICIO: LÓGICA PRINCIPAL DE CONSTRUCCIÓN DE UI (BUILD)
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    const double bottomBarHeight = 20.0;
    const double bottomBarMargin = 40.0;
    const double requiredListPadding = bottomBarHeight + (bottomBarMargin * 2);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          FutureBuilder<ApiResponse<List<Pago>>>(
            future: _pagosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                );
              }
              // ▼▼▼ REEMPLAZA TU LÓGICA DE ASIGNACIÓN CON ESTO ▼▼▼
              if (_pagosOriginales.isEmpty && snapshot.data!.data!.isNotEmpty) {
                // Creamos copias independientes ("clones") para evitar que la
                // lista original se contamine con los cambios de la UI.
                _pagosOriginales =
                    snapshot.data!.data!.map((pago) => pago.clone()).toList();
                _pagosActuales =
                    snapshot.data!.data!.map((pago) => pago.clone()).toList();
              } else if (_pagosActuales.isEmpty &&
                  snapshot.data!.data!.isNotEmpty) {
                // Esto es para las recargas, para que la UI se actualice pero
                // sin sobreescribir la copia original de seguridad.
                _pagosActuales =
                    snapshot.data!.data!.map((pago) => pago.clone()).toList();
              }
              // ▲▲▲ FIN DEL REEMPLAZO ▲▲▲
              if (_pagosActuales.isEmpty) return _buildEmptyState();

              if (_pagosActuales.isNotEmpty) {
                _totalSemanasDelCredito = _pagosActuales
                    .map((p) => p.semana)
                    .reduce((a, b) => a > b ? a : b);
              }

              _animationController.forward();

              // ==================================================
              // INICIO DEL CAMBIO: LÓGICA RESPONSIVA
              // ==================================================
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Definimos un punto de quiebre. Si el ancho es mayor, usamos la vista de escritorio.
                  const double desktopBreakpoint = 900.0;
                  final bool isDesktop =
                      constraints.maxWidth > desktopBreakpoint;

                  // Añadimos el padding inferior para dejar espacio a la barra de totales
                  final contentPadding = EdgeInsets.fromLTRB(
                    isDesktop ? 20 : 16,
                    15,
                    isDesktop ? 20 : 16,
                    requiredListPadding,
                  );

                  if (isDesktop) {
                    // --- VISTA DE ESCRITORIO (TABLA) ---
                    return _buildDesktopLayout(
                      _pagosActuales,
                      isDarkMode,
                      contentPadding,
                    );
                  } else {
                    // --- VISTA MÓVIL (TARJETAS) ---
                    return _buildMobileLayout(
                      _pagosActuales,
                      isDarkMode,
                      contentPadding,
                    );
                  }
                },
              );
              // ==================================================
              // FIN DEL CAMBIO: LÓGICA RESPONSIVA
              // ==================================================
            },
          ),
          Positioned(
            bottom: bottomBarMargin,
            left: 16,
            right: 16,
            child: FutureBuilder<ApiResponse<List<Pago>>>(
              future: _pagosFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.success) {
                  return const SizedBox.shrink();
                }

                final pagos = snapshot.data!.data!;
                final CreditoTotales totales = _calcularTotales(pagos);

                return Row(
                  children: [
                    Expanded(
                      child: _buildTotalesFlotantes(totales, isDarkMode),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      onPressed: _isSaving ? null : _guardarCambios,
                      backgroundColor:
                          _isSaving ? Colors.grey[600] : AppColors.primary,
                      foregroundColor: Colors.white,
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.save_alt),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      const SizedBox(height: 20),
                      Text(
                        'Guardando cambios...',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =======================================================================
  // INICIO: NUEVOS WIDGETS PARA LA VISTA DE ESCRITORIO
  // =======================================================================

  /// Construye la vista de tabla para pantallas grandes.
  /// Construye la vista de tabla para pantallas grandes.
  Widget _buildDesktopLayout(
    List<Pago> pagos,
    bool isDarkMode,
    EdgeInsets padding,
  ) {
    // ▼▼▼ AÑADIMOS ESTA LÍNEA ▼▼▼
    // Calculamos el saldo a favor total para pasarlo a cada fila.
    final double saldoFavorTotalAcumulado = pagos.fold(
      0.0,
      (sum, pago) => sum + (pago.saldoRestante ?? 0.0),
    );
    // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲

    return ListView(
      padding: padding,
      children: [
        _buildDesktopHeader(isDarkMode),
        const SizedBox(height: 8),
        // ▼▼▼ CAMBIO AQUÍ ▼▼▼
        ...pagos.map((pago) {
          // Si es la semana 0, construimos una fila especial
          if (pago.semana == 0) {
            return _buildDesembolsoRow(pago, isDarkMode);
          }
          // De lo contrario, la fila de pago normal
          return _buildDesktopPaymentRow(
            pago,
            isDarkMode,
            saldoFavorTotalAcumulado,
          );
        }),
        // ▲▲▲ FIN DEL CAMBIO ▲▲▲
      ],
    );
  }

  /// Construye una fila informativa para el desembolso inicial en la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildDesembolsoRow(Pago pago, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    TextStyle cellTextStyle = TextStyle(
      fontSize: 12, // Mantenemos el tamaño de fuente consistente
      color: colors.textSecondary,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: colors.disabledCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withOpacity(0.5)),
      ),
      // ▼▼▼ ESTRUCTURA DE ROW CORREGIDA PARA ALINEARSE ▼▼▼
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna 'NO.' (flex: 1)
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(Icons.start, color: Colors.teal, size: 18),
            ),
          ),
          // Columna 'VENCIMIENTO' (flex: 2)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatearFecha(pago.fechaPago), // Fecha del desembolso
                  style: cellTextStyle.copyWith(),
                ),
              ),
            ),
          ),
          // Columna 'A PAGAR' (flex: 3)
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Desembolso Inicial', style: cellTextStyle),
              ),
            ),
          ),
          // Rellenos que coinciden con la fila de pago normal
          const SizedBox(width: 16),
          Expanded(flex: 3, child: SizedBox.shrink()), // Tipo Pago
          Expanded(flex: 3, child: SizedBox.shrink()), // Monto Pagado
          Expanded(flex: 2, child: SizedBox.shrink()), // Fecha Pago
          const SizedBox(width: 16),
          Expanded(flex: 2, child: SizedBox.shrink()), // S. Favor
          Expanded(flex: 2, child: SizedBox.shrink()), // S. Contra
          Expanded(flex: 2, child: SizedBox.shrink()), // Moratorios
          const SizedBox(width: 48), // Espacio para opciones
        ],
      ),
    );
  }

  /// Construye el encabezado de la tabla de escritorio.
  Widget _buildDesktopHeader(bool isDarkMode) {
    // 1. Estilo mejorado con letter-spacing para mejor legibilidad.
    TextStyle headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white70 : Colors.grey[600],
      letterSpacing: 0.5, // Le da un poco de aire a las letras
    );

    Widget buildHeaderCell(
      String text, {
      int flex = 2,
      // 2. Usamos TextAlign para un centrado más predecible que AlignmentGeometry.
      TextAlign textAlign = TextAlign.left,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            text.toUpperCase(),
            style: headerStyle,
            textAlign: textAlign,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        //color: isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 3. Ajustamos los valores de flex y textAlign para cada columna
          buildHeaderCell('NO.', flex: 1, textAlign: TextAlign.center),
          buildHeaderCell('VENCIMIENTO', flex: 3, textAlign: TextAlign.center),
          buildHeaderCell('A PAGAR', flex: 2, textAlign: TextAlign.right),
          const SizedBox(width: 8),
          buildHeaderCell('TIPO PAGO', flex: 4, textAlign: TextAlign.center),
          buildHeaderCell('MONTO PAGADO', flex: 4, textAlign: TextAlign.center),
          buildHeaderCell('FECHA PAGO', flex: 3, textAlign: TextAlign.center),
          const SizedBox(width: 8),
          buildHeaderCell('S. FAVOR', flex: 2, textAlign: TextAlign.right),
          buildHeaderCell('S. CONTRA', flex: 2, textAlign: TextAlign.right),
          buildHeaderCell('MORATORIOS', flex: 3, textAlign: TextAlign.right),
          // Espacio para el botón de opciones
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Construye una fila de la tabla de escritorio para un pago.
  /// Construye una fila de la tabla de escritorio para un pago.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Construye una fila de la tabla de escritorio para un pago.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Construye una fila de la tabla de escritorio para un pago.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Construye una fila de la tabla de escritorio para un pago.
  Widget _buildDesktopPaymentRow(
    Pago pago,
    bool isDarkMode,
    double saldoFavorTotalAcumulado,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // ... (el resto de tu lógica de isFinished se mantiene igual)
    final double deudaTotalOriginal =
        pago.capitalMasInteres +
        pago.moratoriosPagados +
        (pago.moratorios?.moratorios ?? 0.0);
    final double totalAbonado = pago.sumaDepositoMoratorisos;
    final bool matematicamentePagado =
        totalAbonado >= (deudaTotalOriginal - 0.01);
    final List<String> estadosFinalesApi = [
      'pagado',
      'pagado con retraso',
      'pagado para renovacion',
      'garantia pagada',
      'retraso',
    ];
    final bool apiDiceFinalizado = estadosFinalesApi.contains(
      pago.estado?.toLowerCase() ?? '',
    );
    final bool isFinished = matematicamentePagado || apiDiceFinalizado;

    final cardColor = isFinished ? colors.disabledCard : colors.backgroundCard;

    TextStyle cellTextStyle = TextStyle(
      fontSize: 13,
      color: colors.textPrimary,
    );
    TextStyle moneyTextStyle = TextStyle(
      fontSize: 13,
      color: colors.textPrimary,
      fontWeight: FontWeight.w500,
    );

    final int numeroDeIndicadores = _calcularIndicadoresActivos(
      pago,
      saldoFavorTotalAcumulado,
    );
    final double deudaSemana =
        pago.capitalMasInteres + (pago.moratorios?.moratorios ?? 0.0);
    final double cubiertoPorDepositos = pago.sumaDepositoMoratorisos;
    final double cubiertoPorRenovaciones = pago.renovacionesPendientes.fold(
      0.0,
      (sum, r) => sum + (r.descuento ?? 0.0),
    );
    final double favorUtilizadoSemana = pago.favorUtilizado ?? 0.0;
    final double totalCubiertoSemana =
        cubiertoPorDepositos + cubiertoPorRenovaciones + favorUtilizadoSemana;
    double saldoContraCalculado = deudaSemana - totalCubiertoSemana;
    if (saldoContraCalculado < 0.01) {
      saldoContraCalculado = 0.0;
    }

    final double moratorioGenerado = pago.moratorios?.moratorios ?? 0.0;
    final double moratorioPagado = pago.moratoriosPagados;
    final bool moratorioEstaTotalmentePagado =
        moratorioPagado >= (moratorioGenerado - 0.01);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 'NO.'
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '${pago.semana}/$_totalSemanasDelCredito',
                style: cellTextStyle,
              ),
            ),
          ),
          // 'VENCIMIENTO'
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                formatearFecha(pago.fechaPago),
                style: cellTextStyle.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          // 'A PAGAR'
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatearNumero(pago.capitalMasInteres),
                  style: moneyTextStyle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 'TIPO PAGO'
          Expanded(
            flex: 4,
            child: _buildDesktopPaymentTypeSelector(
              pago,
              isDarkMode,
              isFinished,
            ),
          ),
          // 'MONTO PAGADO'
          Expanded(
            flex: 4,
            child: _buildDesktopMontoInput(pago, isDarkMode, isFinished),
          ),

          // 'FECHA PAGO'
          // ▼▼▼ CAMBIO PRINCIPAL AQUÍ ▼▼▼
          // Hemos añadido 'pago.tipoPago == 'Garantía'' a la condición
          // para que el selector de fecha también aparezca en este caso.
          Expanded(
            flex: 3,
            child: Center(
              child:
                  (pago.tipoPago == 'Completo' ||
                          pago.tipoPago == 'Monto Parcial' ||
                          pago.tipoPago == 'Garantía') // <-- CAMBIO AÑADIDO
                      ? Builder(
                        builder: (context) {
                          String fechaMostrada;
                          if (isFinished && pago.abonos.isNotEmpty) {
                            final ultimoAbono = pago.abonos.last;
                            fechaMostrada = formatearFecha(
                              ultimoAbono['fechaDeposito'],
                            );
                          } else {
                            fechaMostrada = formatearFecha(
                              _fechasPagoSeleccionadas[pago.semana] ??
                                  DateTime.now(),
                            );
                          }

                          return TextButton(
                            onPressed:
                                isFinished
                                    ? null
                                    : () => _seleccionarFecha(context, pago),
                            child: Text(
                              fechaMostrada,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    isFinished
                                        ? Colors.green
                                        : (isDarkMode
                                            ? Colors.white
                                            : Color(0xFF4F46E5)),
                              ),
                            ),
                          );
                        },
                      )
                      : SizedBox.shrink(),
            ),
          ),
          // ▲▲▲ FIN DEL CAMBIO ▲▲▲
          const SizedBox(width: 8),

          // Celda "S. FAVOR"
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Builder(
                  builder: (context) {
                    final double original = pago.saldoFavorOriginalGenerado;
                    final double restante = pago.saldoRestante ?? 0.0;
                    final bool fueUsado = restante < original;
                    if (original <= 0.01) {
                      return Text(
                        formatearNumero(pago.saldoRestante),
                        style: moneyTextStyle.copyWith(
                          color:
                              pago.saldoRestante > 0
                                  ? Colors.green
                                  : colors.textSecondary,
                        ),
                      );
                    }
                    if (fueUsado && restante <= 0.01) {
                      return Tooltip(
                        message:
                            'Se utilizaron \$${formatearNumero(original)} de este saldo a favor.',
                        child: Text(
                          formatearNumero(original),
                          style: moneyTextStyle.copyWith(
                            color: colors.textSecondary.withOpacity(0.7),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      );
                    }
                    if (fueUsado && restante > 0.01) {
                      final double usado = original - restante;
                      return Tooltip(
                        message:
                            'Se utilizaron \$${formatearNumero(usado)} de este saldo a favor.',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatearNumero(restante),
                              style: moneyTextStyle.copyWith(
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '(de ${formatearNumero(original)})',
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Text(
                      formatearNumero(pago.saldoRestante),
                      style: moneyTextStyle.copyWith(
                        color:
                            pago.saldoRestante > 0
                                ? Colors.green
                                : colors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Celda "S. CONTRA"
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatearNumero(saldoContraCalculado),
                  style: moneyTextStyle.copyWith(
                    color:
                        saldoContraCalculado > 0
                            ? Colors.red
                            : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

          // 'MORATORIOS'
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  formatearNumero(moratorioGenerado),
                  style: moneyTextStyle.copyWith(
                    color:
                        moratorioGenerado <= 0
                            ? colors.textSecondary
                            : moratorioEstaTotalmentePagado
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ),
            ),
          ),
          // Botón de "más opciones"
          SizedBox(
            width: 48,
            child: Badge(
              isLabelVisible: numeroDeIndicadores > 0,
              backgroundColor: colors.brandPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              label: Text(
                '$numeroDeIndicadores',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              offset: const Offset(4, -4),
              child: IconButton(
                icon: Icon(Icons.more_vert, color: colors.textSecondary),
                tooltip: 'Más opciones',
                onPressed:
                    () => _showAdvancedOptions(context, pago.idfechaspagos!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown de tipo de pago adaptado para la vista de escritorio.
  /// Dropdown de tipo de pago adaptado para la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Dropdown de tipo de pago adaptado para la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Dropdown de tipo de pago adaptado para la vista de escritorio.
  Widget _buildDesktopPaymentTypeSelector(
    Pago pago,
    bool isDarkMode,
    bool isFinished,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    if (isFinished) {
      // --- INICIO DE LA CORRECCIÓN DE PRIORIDAD PARA DESKTOP ---
      String textoMostrado;
      Color colorTexto =
          themeProvider.isDarkMode ? Colors.white70 : Colors.black87;

      // PRIORIDAD #1: Si es 'En Abonos', esa es la etiqueta.
      if (pago.tipoPago?.toLowerCase() == 'en abonos') {
        textoMostrado = 'En Abonos';
        colorTexto = Colors.blue; // Color consistente para abonos.
      }
      // PRIORIDAD #2: Si no, pero fue con garantía, mostramos 'Garantía'.
      else if (_fuePagadoConGarantia(pago)) {
        textoMostrado = 'Garantía';
        colorTexto = Colors.pink;
      }
      // PRIORIDAD #3: Como última opción, el tipo de pago que sea.
      else {
        textoMostrado = pago.tipoPago ?? 'N/A';
      }

      return Center(
        child: Text(
          textoMostrado,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorTexto,
          ),
        ),
      );
      // --- FIN DE LA CORRECCIÓN DE PRIORIDAD PARA DESKTOP ---
    }

    // La lógica del dropdown para pagos pendientes no cambia.
    final List<String> opcionesDisponibles = [
      'Completo',
      'Monto Parcial',
      'En Abonos',
      if (pago.semana >= _totalSemanasDelCredito - 1) 'Garantía',
    ];
    final String? valorActual =
        opcionesDisponibles.contains(pago.tipoPago) ? pago.tipoPago : null;

    return DropdownButtonFormField<String?>(
      value: valorActual,
      hint: const Text('Seleccionar', style: TextStyle(fontSize: 12)),
      isExpanded: true,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        fillColor: Colors.transparent,
      ),
      dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      items:
          opcionesDisponibles
              .map(
                (label) => DropdownMenuItem(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                  value: label,
                ),
              )
              .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          pago.tipoPago = value;
          pago.fechaPago = DateTime.now().toIso8601String();
          _semanasModificadas.add(pago.semana);
        });
      },
    );
  }

  // 2. AHORA, REEMPLAZA TAMBIÉN ESTA FUNCIÓN
  /// Campo de entrada de monto o botón adaptado para la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Campo de entrada de monto o botón adaptado para la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Campo de entrada de monto o botón adaptado para la vista de escritorio.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Campo de entrada de monto o botón adaptado para la vista de escritorio.
  Widget _buildDesktopMontoInput(Pago pago, bool isDarkMode, bool isFinished) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    // --- INICIO DE LA CORRECCIÓN DE PRIORIDAD PARA DESKTOP ---

    // PRIORIDAD #1: Si el tipo de pago es 'En Abonos', mostramos los botones.
    if (pago.tipoPago?.toLowerCase() == 'en abonos') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón de "Agregar Abono", deshabilitado si ya está finalizado.
          ElevatedButton(
            onPressed:
                isFinished
                    ? null
                    : () => _showAbonosDialog(
                      context,
                      pago,
                      mostrarFormularioInicial: true,
                    ),
            child: Icon(Icons.add, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              //tooltip: 'Agregar Abono',
            ),
          ),
          SizedBox(width: 8),
          // Botón de "Ver Abonos", siempre habilitado.
          OutlinedButton(
            onPressed:
                () => _showAbonosDialog(
                  context,
                  pago,
                  mostrarFormularioInicial: false,
                ),
            child: Icon(Icons.visibility, size: 16),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              //tooltip: 'Ver Abonos',
            ),
          ),
        ],
      );
    }

    // PRIORIDAD #2: Si no fue 'En Abonos', pero sí con garantía, mostramos el desglose.
    if (isFinished && _fuePagadoConGarantia(pago)) {
      final double montoUtilizado = pago.capitalMasInteres;
      final double garantiaTotal = widget.montoGarantia;

      return Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
            children: [
              TextSpan(text: 'Usó '),
              TextSpan(
                text: '\$${formatearNumero(montoUtilizado)}',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' de '),
              TextSpan(
                text: '\$${formatearNumero(garantiaTotal)}',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' de Garantía'),
            ],
          ),
        ),
      );
    }

    // --- FIN DE LA CORRECCIÓN ---

    // Si no fue ninguna de las anteriores, la lógica original continúa.
    if (isFinished) {
      return Center(
        child: Text(
          formatearNumero(pago.sumaDepositoMoratorisos),
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      );
    }

    // El switch para los pagos pendientes que no son 'En Abonos'.
    switch (pago.tipoPago) {
      case 'Monto Parcial':
        final controller = _montoParcialControllers.putIfAbsent(
          pago.semana,
          () => TextEditingController(),
        );
        return TextField(
          controller: controller,
          textAlign: TextAlign.center,
          onChanged:
              (value) => setState(() => _semanasModificadas.add(pago.semana)),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.grey[800],
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '\$ ',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );

      case 'Completo':
        return Center(
          child: Text(
            formatearNumero(pago.capitalMasInteres),
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );

      case 'Garantía':
        return Center(
          child: Text(
            formatearNumero(widget.montoGarantia),
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // =======================================================================
  // INICIO: WIDGETS PARA LA VISTA MÓVIL (SIN CAMBIOS)
  // =======================================================================

  /// Construye la vista de tarjetas para pantallas pequeñas.
  Widget _buildMobileLayout(
    List<Pago> pagos,
    bool isDarkMode,
    EdgeInsets padding,
  ) {
    final double saldoFavorTotalAcumulado = pagos.fold(
      0.0,
      (sum, pago) => sum + (pago.saldoRestante ?? 0.0),
    );
    // DENTRO DE: Widget _buildMobileLayout(...)
    return ListView.builder(
      padding: padding,
      itemCount: pagos.length,
      itemBuilder: (context, index) {
        final pago = pagos[index];
        // ▼▼▼ CAMBIO AQUÍ ▼▼▼
        if (pago.semana == 0) {
          // Si es la semana 0, mostramos la tarjeta de desembolso
          return _buildDesembolsoCard(pago, isDarkMode);
        }
        // De lo contrario, la tarjeta de pago normal
        return _buildModernPaymentCard(
          pago,
          isDarkMode,
          saldoFavorTotalAcumulado,
        );
        // ▲▲▲ FIN DEL CAMBIO ▲▲▲
      },
    );
  }

  // AÑADE ESTA NUEVA FUNCIÓN A TU CLASE

  /// Construye una tarjeta informativa para el desembolso inicial (semana 0).
  Widget _buildDesembolsoCard(Pago pago, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.disabledCard, // Usamos el color de tarjeta deshabilitada
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          // Indicador visual
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.teal, // Un color distintivo para el desembolso
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desembolso del Crédito',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_available, // Icono de evento completado
                      size: 12,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Fecha: ${formatearFecha(pago.fechaPago)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Icono de desembolso
          Icon(Icons.start, color: Colors.teal, size: 28),
        ],
      ),
    );
  }

  // A PARTIR DE AQUÍ, EL RESTO DE TU CÓDIGO (FUNCIONES Y WIDGETS)
  // SE MANTIENE EXACTAMENTE IGUAL.
  // ... (Pega todo tu código original desde _calcularTotales hasta el final)

  // En tu clase _ControlPagosTabState

  // En: tu clase _ControlPagosTabState

  // Pega esta función completa para reemplazar la tuya

  CreditoTotales _calcularTotales(List<Pago> pagos) {
    AppLogger.log('--- [DEBUG] INICIANDO CÁLCULO DE TOTALES ---');

    // --- INICIALIZAMOS TODOS LOS ACUMULADORES ---
    double totalMonto = 0.0;
    double totalRealIngresado = 0.0;
    double totalGarantiasAplicadas = 0.0;
    double totalRenovacionesAplicadas = 0.0;
    double totalFavorUtilizado = 0.0;
    double totalSaldoFavor = 0.0;
    double saldoFavorHistoricoTotal = 0.0;
    double totalSaldoContra = 0.0;
    double totalDeudaPendiente = 0.0;

    double totalMoratoriosGenerados = 0.0;
    double totalMoratoriosPagados = 0.0;

    for (final pago in pagos) {
      if (pago.semana == 0) continue;

      AppLogger.log('\n--- [DEBUG] Procesando Semana ${pago.semana} ---');

      totalMonto += pago.capitalMasInteres;
      totalSaldoFavor += pago.saldoRestante ?? 0.0;
      saldoFavorHistoricoTotal += pago.saldoFavorOriginalGenerado;
      totalFavorUtilizado += pago.favorUtilizado?.toDouble() ?? 0.0;

      // Bucle de abonos (aquí está la clave)
      for (var abono in pago.abonos) {
        AppLogger.log(
          '  [DEBUG] Abono encontrado: $abono',
        ); // <--- MUESTRA EL MAPA COMPLETO

        final double deposito =
            double.tryParse(abono['deposito']?.toString() ?? '0') ?? 0.0;

        final String esGarantia = abono['garantia']?.toString() ?? 'No';
        final String esMoratorio =
            abono['moratorio']?.toString() ?? 'No'; // <--- Leemos el campo

        // Imprimimos los valores que estamos a punto de comparar
        AppLogger.log(
          '    [DEBUG] Valores leídos -> esGarantia: "$esGarantia", esMoratorio: "$esMoratorio"',
        );

        if (esGarantia == 'Si') {
          AppLogger.log(
            '    [DEBUG] DECISIÓN: Es Garantía. Sumando $deposito a totalGarantiasAplicadas.',
          );
          totalGarantiasAplicadas += deposito;
        } else if (esMoratorio == 'Si') {
          AppLogger.log(
            '    [DEBUG] DECISIÓN: Es Moratorio. IGNORANDO $deposito para totalRealIngresado.',
          );
          // No hacemos nada, que es lo que queremos
        } else {
          AppLogger.log(
            '    [DEBUG] DECISIÓN: Es pago normal. Sumando $deposito a totalRealIngresado.',
          );
          totalRealIngresado += deposito;
        }
        AppLogger.log(
          '    [DEBUG] >> totalRealIngresado actual: $totalRealIngresado',
        );
      }

      // El resto de tu lógica...
      for (var renovacion in pago.renovacionesPendientes) {
        totalRenovacionesAplicadas += renovacion.descuento ?? 0.0;
      }

      double deudaSemana = pago.capitalMasInteres;
      double cubiertoPorDepositos = pago.sumaDepositoMoratorisos;
      double cubiertoPorRenovaciones = pago.renovacionesPendientes.fold(
        0.0,
        (sum, r) => sum + (r.descuento ?? 0.0),
      );
      double favorUtilizadoSemana = pago.favorUtilizado?.toDouble() ?? 0.0;
      double totalCubiertoSemana =
          cubiertoPorDepositos + cubiertoPorRenovaciones + favorUtilizadoSemana;
      double deficitSemana = deudaSemana - totalCubiertoSemana;

      if (deficitSemana > 0.01) {
        totalSaldoContra += deficitSemana;
      }

      if (pago.moratorioDesabilitado != "Si") {
        totalMoratoriosGenerados += pago.moratorios?.moratorios ?? 0.0;
      }
      totalMoratoriosPagados += pago.moratoriosPagados;
    }

    double totalPagoActual =
        totalRealIngresado +
        totalGarantiasAplicadas +
        totalRenovacionesAplicadas +
        totalFavorUtilizado;

    final double totalMoratoriosPendientes = (totalMoratoriosGenerados -
            totalMoratoriosPagados)
        .clamp(0, double.infinity);
    final double saldoContraCombinado =
        totalSaldoContra + totalMoratoriosPendientes;

    AppLogger.log('\n--- [DEBUG] CÁLCULO FINALIZADO ---');
    AppLogger.log(
      '  [DEBUG] Total Real Ingresado (Final): $totalRealIngresado',
    );
    AppLogger.log(
      '  [DEBUG] Total Garantías Aplicadas (Final): $totalGarantiasAplicadas',
    );
    AppLogger.log('  [DEBUG] Total Pago Actual (Final): $totalPagoActual');
    AppLogger.log('--------------------------------------\n');

    return CreditoTotales(
      totalMonto: totalMonto,
      totalPagoActual: totalPagoActual,
      totalRealIngresado: totalRealIngresado,
      totalSaldoFavor: totalSaldoFavor,
      saldoFavorHistoricoTotal: saldoFavorHistoricoTotal,
      totalSaldoContraActivo: saldoContraCombinado,
      totalSaldoContraPotencial: saldoContraCombinado,
      totalDeudaPendiente: totalDeudaPendiente,
      hayGarantiaAplicada: totalGarantiasAplicadas > 0,
      totalMoratoriosGenerados: totalMoratoriosGenerados,
      totalMoratoriosPagados: totalMoratoriosPagados,
      totalMoratorios: totalMoratoriosPendientes,
    );
  }

  // (Aquí continúa el resto de tu código sin cambios...)
  // ...
  // ... Pega aquí todo desde _mostrarDetallesCompletos hasta el final de la clase
  // ...
  // En: tu clase _ControlPagosTabState

  void _mostrarDetallesCompletos(
    BuildContext context,
    CreditoTotales totales,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? Color(0xFF121212) : Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Resumen de Totales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                _buildDetalleRow(
                  'Total a Pagar (meta):',
                  '\$${formatearNumero(totales.totalMonto)}',
                  isDarkMode,
                ),
                Divider(height: 24),

                _buildDetalleRow(
                  'Total Ingresado (real):',
                  '\$${formatearNumero(totales.totalRealIngresado)}',
                  isDarkMode,
                  valueColor: Colors.blue.shade300,
                ),
                _buildDetalleRow(
                  '  ↳ Total Aplicado a Deudas:',
                  '\$${formatearNumero(totales.totalPagoActual)}',
                  isDarkMode,
                  valueColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),

                Divider(height: 24),

                _buildDetalleRow(
                  'Saldo a Favor (disponible):',
                  '\$${formatearNumero(totales.totalSaldoFavor)}',
                  isDarkMode,
                  valueColor: Colors.green,
                ),
                _buildDetalleRow(
                  '  ↳ Generado históricamente:',
                  '\$${formatearNumero(totales.saldoFavorHistoricoTotal)}',
                  isDarkMode,
                  valueColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),

                Divider(height: 24),

                _buildDetalleRow(
                  'Saldo en Contra (deuda):',
                  '\$${formatearNumero(totales.totalSaldoContraActivo)}',
                  isDarkMode,
                  valueColor: Colors.red,
                ),
                _buildDetalleRow(
                  '  ↳ Deuda Potencial Total:',
                  '\$${formatearNumero(totales.totalSaldoContraPotencial)}',
                  isDarkMode,
                  valueColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),

                // ▼▼▼ CAMBIO: DESGLOSE DE MORATORIOS ▼▼▼
                Divider(height: 24, indent: 20, endIndent: 20),

                _buildDetalleRow(
                  'Moratorios Generados:',
                  '\$${formatearNumero(totales.totalMoratoriosGenerados)}',
                  isDarkMode,
                  valueColor:
                      totales.totalMoratoriosGenerados > 0
                          ? Colors.orange.shade700
                          : null,
                ),
                _buildDetalleRow(
                  'Moratorios Pagados:',
                  '\$${formatearNumero(totales.totalMoratoriosPagados)}',
                  isDarkMode,
                  valueColor:
                      totales.totalMoratoriosPagados > 0 ? Colors.green : null,
                ),
                _buildDetalleRow(
                  'Moratorios Pendientes:',
                  '\$${formatearNumero(totales.totalMoratorios)}',
                  isDarkMode,
                  valueColor: totales.totalMoratorios > 0 ? Colors.red : null,
                ),

                // ▲▲▲ FIN DEL CAMBIO ▲▲▲
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(
    String label,
    String value,
    bool isDarkMode, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un widget flotante que muestra el saldo a favor total.
  // Pega estas dos funciones en tu _ControlPagosTabState,
  // reemplazando las versiones anteriores.

  // Pega esta función reemplazando la anterior
  // En: tu clase _ControlPagosTabState

  Widget _buildTotalesFlotantes(CreditoTotales totales, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return GestureDetector(
      onTap: () {
        _mostrarDetallesCompletos(context, totales, isDarkMode);
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildItemFlotante(
                label: 'Monto a Pagar',
                valor: totales.totalMonto,
                color: Colors.blue.shade300,
              ),
              _buildDivisor(),
              _buildItemFlotante(
                label: 'Pagado',
                valor: totales.totalPagoActual,
                color: Colors.green.shade300,
              ),
              _buildDivisor(),
              _buildItemFlotante(
                label: 'A Favor',
                valor: totales.totalSaldoFavor,
                color:
                    totales.totalSaldoFavor > 0
                        ? Colors.green.shade500
                        : Colors.grey,
              ),
              _buildDivisor(),
              _buildItemFlotante(
                label: 'En Contra',
                valor: totales.totalSaldoContraActivo,
                color:
                    totales.totalSaldoContraActivo > 0
                        ? Colors.red.shade400
                        : Colors.grey,
              ),
              _buildDivisor(),

              // ▼▼▼ CAMBIO: SE REEMPLAZA EL TOTAL DE MORATORIOS ▼▼▼
              _buildItemFlotante(
                label: 'Mora Pagada',
                valor: totales.totalMoratoriosPagados,
                color:
                    totales.totalMoratoriosPagados > 0
                        ? Colors.green.shade400
                        : Colors.grey,
              ),
              _buildDivisor(),
              _buildItemFlotante(
                label: 'Mora Pendiente',
                // Usamos el campo que ahora representa los pendientes
                valor: totales.totalMoratorios,
                color:
                    totales.totalMoratorios > 0
                        ? Colors.red.shade400
                        : Colors.grey,
              ),
              // ▲▲▲ FIN DEL CAMBIO ▲▲▲
            ],
          ),
        ),
      ),
    );
  }

  // Función auxiliar para construir cada ítem
  Widget _buildItemFlotante({
    required String label,
    required double valor,
    required Color color,
  }) {
    return Padding(
      // Añadimos padding para que no se peguen al deslizar
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          SizedBox(height: 2),
          Text(
            '\$${formatearNumero(valor)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Creamos un widget para el divisor para no repetir código
  Widget _buildDivisor() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // ▼▼▼ CAMBIO AQUÍ (2/4): LA NUEVA FUNCIÓN PARA SELECCIONAR FECHA ▼▼▼
  /// Muestra un DatePicker y actualiza la fecha del pago seleccionado.
  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA ▼▼▼
  /// Muestra un DatePicker y actualiza la fecha del pago seleccionado.
  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA ▼▼▼
  /// Muestra un DatePicker y guarda la fecha seleccionada en un mapa temporal.
  Future<void> _seleccionarFecha(BuildContext context, Pago pago) async {
    // 1. Determina la fecha inicial para el calendario.
    //    Si ya se seleccionó una fecha para esta semana, la usa. Si no, usa la de hoy.
    final DateTime fechaInicial =
        _fechasPagoSeleccionadas[pago.semana] ?? DateTime.now();

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial, // <-- Usa nuestra fecha inicial calculada
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Selecciona la fecha del pago',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF4F46E5)),
            ),
          ),
          child: child!,
        );
      },
    );

    // 2. Si el usuario seleccionó una fecha, la guardamos en nuestro mapa.
    if (fechaSeleccionada != null) {
      setState(() {
        // NO modificamos pago.fechaPago.
        _fechasPagoSeleccionadas[pago.semana] = fechaSeleccionada;
        // Marcamos esta semana como modificada para que se guarde.
        _semanasModificadas.add(pago.semana);
      });
    }
  }
  // ▲▲▲ FIN DEL CAMBIO ▲▲▲

  bool _fuePagadoConGarantia(Pago pago) {
    // Si no hay abonos, no pudo ser con garantía.
    if (pago.abonos.isEmpty) {
      return false;
    }
    // Buscamos si ALGÚN abono tiene la marca de garantía.
    return pago.abonos.any((abono) {
      final esGarantia = (abono['garantia'] as String?)?.toLowerCase() == 'si';
      return esGarantia;
    });
  }

  // --- FUNCIONES HELPER ---
  String formatearFecha(Object? fecha) {
    try {
      if (fecha is String && fecha.isNotEmpty) {
        final parsedDate = DateTime.parse(fecha);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      } else if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy').format(fecha);
      }
    } catch (e) {
      AppLogger.log('Error formateando la fecha: $e');
    }
    return 'Fecha no válida';
  }

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(numero);
  }

  // --- REEMPLAZA TU FUNCIÓN _guardarCambios CON ESTA VERSIÓN FINAL ---

  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA ▼▼▼
  // Esta función ya está correcta, solo asegúrate de tener esta versión.
  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA ▼▼▼
  // --- Pega esta función completa reemplazando tu _guardarCambios actual ---

  // En: lib/dialog/credito/pestaña_control_pagos.dart (dentro de _ControlPagosTabState)

  // --- Pega esta función completa ---

  // <-- CAMBIO CLAVE (3/3): REEMPLAZA TU _guardarCambios CON ESTA VERSIÓN
  Future<void> _guardarCambios() async {
    // 1. FILTRADO INICIAL: Obtener los pagos que el usuario ha tocado en la UI.
    final List<Pago> pagosModificadosUI =
        _pagosActuales
            .where((pago) => _semanasModificadas.contains(pago.semana))
            .toList();

    if (pagosModificadosUI.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios nuevos para guardar.')),
      );
      return;
    }

    // Limpiamos los SnackBars anteriores.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Notificamos al padre que la operación ha comenzado (activa overlay de carga).
    widget.onSaveStarted();

    try {
      // 2. PREPARAR PAYLOAD FINAL: Usamos la función helper con la lógica robusta.
      // Esta función reemplaza el `for` loop y el `switch` que tenías antes.
      final List<Map<String, dynamic>> payloadFinal = _generarPayloadDePagos(
        pagosModificadosUI,
        _pagosOriginales, // Pasamos la lista original para comparar.
      );

      // Si después de la lógica detallada no hay nada que enviar (ej: se revirtió un cambio), salimos.
      if (payloadFinal.isEmpty) {
        AppLogger.log('Payload final vacío. No se enviará nada a la API.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectaron cambios válidos para guardar.'),
          ),
        );
        return; // El bloque `finally` se encargará de ocultar el overlay.
      }

      AppLogger.log('\n✅ Payload final robusto, listo para enviar:');
      AppLogger.log(payloadFinal);

      // 3. EJECUTAR LLAMADA A LA API
      final List<Future> operations = [
        _pagoService.guardarPagosMultiples(
          idCredito: widget.idCredito,
          pagosModificados: payloadFinal,
        ),
        Future.delayed(const Duration(milliseconds: 800)),
      ];
      final results = await Future.wait(operations);
      final ApiResponse<void> response = results[0];

      // 4. MANEJAR EL RESULTADO
      if (response.success) {
        _semanasModificadas.clear();
        _montoParcialControllers.forEach((_, c) => c.clear());
        _nuevoAbonoControllers.forEach((_, c) => c.clear());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cambios guardados exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onDataChanged();
        _recargarPagos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error del servidor: ${response.error ?? "Desconocido"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar los cambios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // 5. FINALIZAR: Notificamos al padre que la operación ha terminado.
      widget.onSaveFinished();
    }
  }

  /// =======================================================================
  /// FUNCIÓN HELPER CON LA LÓGICA DE NEGOCIO ROBUSTA
  /// Esta es la nueva función que contiene la inteligencia de cálculo.
  /// =======================================================================
  /// =======================================================================
  /// FUNCIÓN HELPER CON LA LÓGICA DE NEGOCIO ROBUSTA
  /// Esta es la nueva función que contiene la inteligencia de cálculo.
  /// =======================================================================
  List<Map<String, dynamic>> _generarPayloadDePagos(
    List<Pago> pagosModificados,
    List<Pago> pagosOriginales,
  ) {
    AppLogger.log('--- Iniciando generación de Payload Robusto ---');
    List<Map<String, dynamic>> pagosJson = [];

    for (final pagoActual in pagosModificados) {
      AppLogger.log(
        '\n--- Procesando Semana ${pagoActual.semana} (ID: ${pagoActual.idfechaspagos}) ---',
      );

      // Buscar el estado original del pago para calcular lo ya pagado.
      final pagoOriginal = pagosOriginales.firstWhere(
        (p) => p.idfechaspagos == pagoActual.idfechaspagos,
        orElse: () => pagoActual,
      );

      // --- CÁLCULO DE DEUDA REAL (CON LA CORRECCIÓN) ---
      // ▼▼▼ INICIO DE LA CORRECCIÓN CLAVE ▼▼▼
      // Reemplazamos el casteo `as num?` por `double.tryParse` para manejar
      // de forma segura los valores que puedan venir como String desde la API.
      final double paidCapital = pagoOriginal.abonos.fold(
        0.0,
        (sum, a) =>
            sum + (double.tryParse(a['deposito']?.toString() ?? '0') ?? 0.0),
      );
      final double paidMoratorio = pagoOriginal.abonos.fold(
        0.0,
        (sum, a) =>
            sum + (double.tryParse(a['moratorio']?.toString() ?? '0') ?? 0.0),
      );
      // ▲▲▲ FIN DE LA CORRECCIÓN CLAVE ▲▲▲

      AppLogger.log(
        'Pagado previamente: Capital=\$$paidCapital, Moratorio=\$$paidMoratorio',
      );

      final double capitalPendiente =
          (pagoActual.capitalMasInteres) - paidCapital;
      final double moratorioPendiente =
          (pagoActual.moratorios?.moratorios ?? 0.0) - paidMoratorio;

      AppLogger.log(
        'Pendiente Real: Capital=\$$capitalPendiente, Moratorio=\$$moratorioPendiente',
      );

      // ▼▼▼ CON ESTA LÓGICA NUEVA ▼▼▼
      final String fechaPagoEfectiva =
          (_fechasPagoSeleccionadas[pagoActual.semana] ?? DateTime.now())
              .toIso8601String();
      // ▲▲▲ FIN DE LA LÓGICA NUEVA ▲▲▲

      final String tipoLower = pagoActual.tipoPago?.toLowerCase() ?? '';

      switch (tipoLower) {
        case 'completo':
          AppLogger.log('Tipo: Completo');
          pagosJson.add({
            "idfechaspagos": pagoActual.idfechaspagos,
            "fechaPago": fechaPagoEfectiva,
            "tipoPago": "Completo",
            "montoaPagar": pagoActual.capitalMasInteres,
            "deposito": capitalPendiente.clamp(0.0, double.infinity),
            "moratorio": moratorioPendiente.clamp(0.0, double.infinity),
            "saldofavor": 0.0,
          });
          break;

        case 'monto parcial':
          AppLogger.log('Tipo: Monto Parcial');
          final controller = _montoParcialControllers[pagoActual.semana];
          final double montoDepositado =
              double.tryParse(controller?.text ?? '0') ?? 0.0;

          double aplicadoCapital = montoDepositado.clamp(0.0, capitalPendiente);
          double remanente = montoDepositado - aplicadoCapital;
          double aplicadoMoratorio = remanente.clamp(0.0, moratorioPendiente);
          double saldoFavorGenerado = remanente - aplicadoMoratorio;

          pagosJson.add({
            "idfechaspagos": pagoActual.idfechaspagos,
            "fechaPago": fechaPagoEfectiva,
            "tipoPago": "Monto Parcial",
            "montoaPagar": pagoActual.capitalMasInteres,
            "deposito": aplicadoCapital,
            "moratorio": aplicadoMoratorio,
            "saldofavor": saldoFavorGenerado.clamp(0.0, double.infinity),
          });
          break;

        case 'garantía':
          AppLogger.log('Tipo: Garantía con monto \$${widget.montoGarantia}');
          final double montoDepositado = widget.montoGarantia;

          double aplicadoCapital = montoDepositado.clamp(0.0, capitalPendiente);
          double remanente = montoDepositado - aplicadoCapital;
          double aplicadoMoratorio = remanente.clamp(0.0, moratorioPendiente);
          double saldoFavorGenerado = remanente - aplicadoMoratorio;

          pagosJson.add({
            "idfechaspagos": pagoActual.idfechaspagos,
            "fechaPago": fechaPagoEfectiva,
            "tipoPago": "Garantia",
            "montoaPagar": pagoActual.capitalMasInteres,
            "deposito": aplicadoCapital,
            "moratorio": aplicadoMoratorio,
            "saldofavor": saldoFavorGenerado.clamp(0.0, double.infinity),
          });
          break;

        case 'en abonos':
          AppLogger.log('Tipo: En Abonos');
          final List<Map<String, dynamic>> nuevosAbonos =
              pagoActual.abonos
                  .where(
                    (abono) =>
                        abono['idpagos'] == null ||
                        abono['idpagos'].toString().isEmpty,
                  )
                  .toList();

          if (nuevosAbonos.isEmpty) {
            AppLogger.log(
              'No hay nuevos abonos para la semana ${pagoActual.semana}, omitiendo.',
            );
            continue;
          }

          double capitalAcumulado = paidCapital;
          double moratorioAcumulado = paidMoratorio;

          for (var abono in nuevosAbonos) {
            AppLogger.log('\n--- Procesando nuevo abono ---');
            double montoAbono =
                double.tryParse(abono['deposito']?.toString() ?? '0') ?? 0.0;
            AppLogger.log('Monto de este abono: $montoAbono');

            String fechaAbono =
                abono['fechaDeposito'] ?? DateTime.now().toIso8601String();

            double capPendienteAbono =
                (pagoActual.capitalMasInteres) - capitalAcumulado;
            AppLogger.log(
              'Capital pendiente (antes de este abono): $capPendienteAbono',
            );

            final double moratoriosTotales =
                (pagoActual.moratorios?.moratorios ?? 0.0) + moratorioAcumulado;
            double morPendienteAbono = moratoriosTotales - moratorioAcumulado;
            AppLogger.log(
              'Moratorio pendiente (antes de este abono): $morPendienteAbono',
            );

            // --- VALIDACIÓN Y APLICACIÓN CON CLAMPS DE SEGURIDAD ---
            double aplicadoCapital = montoAbono.clamp(
              0.0,
              capPendienteAbono.clamp(0.0, double.infinity),
            );
            double remanente = montoAbono - aplicadoCapital;
            double aplicadoMoratorio = remanente.clamp(
              0.0,
              morPendienteAbono.clamp(0.0, double.infinity),
            );
            double saldoFavorGenerado = remanente - aplicadoMoratorio;

            // --- CONSTRUCCIÓN DEL PAYLOAD PARA ESTE ABONO ---
            final payloadAbono = {
              "idfechaspagos": pagoActual.idfechaspagos,
              "fechaPago": fechaAbono,
              "tipoPago": "En Abonos",
              "montoaPagar": pagoActual.capitalMasInteres,
              "deposito": aplicadoCapital.clamp(0, double.infinity),
              "moratorio": aplicadoMoratorio.clamp(0, double.infinity),
              "saldofavor": saldoFavorGenerado.clamp(0, double.infinity),
            };

            AppLogger.log('--- Payload a enviar para este abono ---');
            AppLogger.log(payloadAbono);
            AppLogger.log('--------------------------------------');

            pagosJson.add(payloadAbono);

            capitalAcumulado += aplicadoCapital;
            moratorioAcumulado += aplicadoMoratorio;
          }
          break;
      }
    }
    AppLogger.log('--- Generación de Payload Robusto Finalizada ---');
    return pagosJson;
  }
  // (El resto de los widgets _build... no necesitan cambios estructurales,
  // pero los he dejado completos para que tengas todo el archivo)

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(
              'Error al cargar los pagos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              onPressed: _recargarPagos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey, size: 80),
          SizedBox(height: 16),
          Text(
            'No se encontraron pagos',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'No hay un calendario de pagos para este crédito.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDarkMode,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white60 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    List<Pago> listaDePagos,
    bool isDarkMode,
    double saldoFavorTotalAcumulado,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: listaDePagos.length,
      itemBuilder: (context, index) {
        final pago = listaDePagos[index];
        if (pago.semana == 0) return SizedBox.shrink();
        return _buildModernPaymentCard(
          pago,
          isDarkMode,
          saldoFavorTotalAcumulado,
        );
      },
    );
  }

  Widget _buildModernPaymentCard(
    Pago pago,
    bool isDarkMode,
    double saldoFavorTotalAcumulado,
  ) {
    final String estadoActual = pago.estado ?? 'Pendiente';
    final statusDetails = _getStatusDetails(estadoActual);
    final Color statusColor = statusDetails['color'];
    final IconData statusIcon = statusDetails['icon'];
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // +++ LÓGICA FINAL isFinished v7 - COMBINANDO CÁLCULO Y ESTADOS API +++

    // --- CÁLCULO MATEMÁTICO ---
    // 1. Reconstruimos la deuda total original de la semana.
    final double deudaTotalOriginal =
        pago.capitalMasInteres +
        pago.moratoriosPagados +
        (pago.moratorios?.moratorios ?? 0.0);

    // 2. Comparamos con el total abonado.
    final double totalAbonado = pago.sumaDepositoMoratorisos;
    final bool matematicamentePagado =
        totalAbonado >= (deudaTotalOriginal - 0.01);

    // --- ESTADOS EXPLÍCITOS DE LA API ---
    // 3. Creamos una lista con los estados que FORZAN la condición de "finalizado".
    //    Añadimos 'retraso' según tu petición.
    final List<String> estadosFinalesApi = [
      'pagado',
      'pagado con retraso',
      'pagado para renovacion',
      'garantia pagada',
      'retraso', // <-- AÑADIDO SEGÚN TU REQUISITO
    ];
    final bool apiDiceFinalizado = estadosFinalesApi.contains(
      pago.estado?.toLowerCase() ?? '',
    );

    // --- CONDICIÓN FINAL ---
    // 4. El pago está finalizado si la matemática lo confirma O si la API lo fuerza.
    final bool isFinished = matematicamentePagado || apiDiceFinalizado;

    // Opcional: AppLogger.log de debugging final para confirmar
    AppLogger.log('--- DEBUG v7 SEMANA ${pago.semana} ---');
    AppLogger.log(
      'Deuda Total: $deudaTotalOriginal | Total Abonado: $totalAbonado',
    );
    AppLogger.log('¿Matemáticamente Pagado?: $matematicamentePagado');
    AppLogger.log(
      'Estado API: "${pago.estado}", ¿API lo fuerza como finalizado?: $apiDiceFinalizado',
    );
    AppLogger.log('Resultado Final isFinished: $isFinished');
    AppLogger.log('----------------------------------');

    // +++ FIN DEL BLOQUE +++

    final cardColor =
        isFinished ? (colors.disabledCard) : (colors.backgroundCard);

    // El resto de la función no necesita cambios, solo se beneficia de la nueva variable 'isFinished'
    return TweenAnimationBuilder<double>(
      // ... (el resto de tu código de TweenAnimationBuilder se mantiene igual)
      duration: Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.only(
                  top: 8,
                  bottom: 8,
                  left: 20,
                  right: 6,
                ),
                childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                title: _buildCardHeader(
                  pago,
                  isDarkMode,
                  estadoActual,
                  statusColor,
                  isFinished,
                ),
                trailing: _buildTrailingIcon(
                  isFinished,
                  statusIcon,
                  statusColor,
                  pago,
                  saldoFavorTotalAcumulado,
                ),
                onExpansionChanged: (expanded) {
                  if (!expanded) {
                    setState(() {
                      _saldosCalculados.remove(pago.semana);
                      _montoParcialControllers[pago.semana]?.clear();
                    });
                  }
                },
                children: [_buildExpandedContent(pago, isDarkMode, isFinished)],
              ),
            ),
          ),
        );
      },
    );
  }

  // <-- CAMBIO: Añadimos una nueva función auxiliar para el icono
  /// Devuelve un icono representando el tipo de pago realizado.
  Widget _buildPaymentTypeIcon(String? tipoPago) {
    IconData iconData;
    String tooltipMessage;
    Color iconColor;

    switch (tipoPago) {
      case 'Completo':
        // Opciones: Icons.check_circle, Icons.done_all, Icons.verified, Icons.task_alt
        iconData = Icons.paid;
        tooltipMessage = 'Pago Completo';
        iconColor = Colors.teal;

        break;

      case 'En Abonos':
        // Opciones: Icons.schedule, Icons.layers, Icons.timeline, Icons.view_list
        iconData = Icons.layers;
        tooltipMessage = 'Pagado en Abonos';
        iconColor = Colors.blue;

        break;

      case 'Monto Parcial':
        // Opciones: Icons.pie_chart_outline, Icons.donut_small, Icons.circle_outlined, Icons.radio_button_unchecked
        iconData = Icons.pie_chart;
        tooltipMessage = 'Pago Parcial';
        iconColor = Colors.orange;

        break;

      case 'Garantía':
        // Opciones: Icons.security, Icons.verified_user, Icons.lock, Icons.safety_check
        iconData = Icons.security;
        tooltipMessage = 'Pagado con Garantía';
        iconColor = Colors.pink;

        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Tooltip(
        message: tooltipMessage,
        child: Icon(iconData, size: 16, color: iconColor),
      ),
    );
  }

  // <-- CAMBIO: Modificamos la firma y el cuerpo de _buildCardHeader
  Widget _buildCardHeader(
    Pago pago,
    bool isDarkMode,
    String estado,
    Color statusColor,
    bool isFinished,
  ) {
    // Tu código de debug existente...
    if (pago.semana == 15 || pago.semana == 16) {
      AppLogger.log('--- DEBUG PAGO SEMANA ${pago.semana} ---');
      AppLogger.log('1. isFinished: $isFinished (viene de estado: "$estado");');
      AppLogger.log('2. pago.tipoPago: "${pago.tipoPago}"');
      AppLogger.log(
        '3. pago.abonos (los datos de los depósitos);: ${pago.abonos}',
      );
      AppLogger.log(
        '4. ¿Se usó garantía? (resultado de la función): ${_fuePagadoConGarantia(pago)}',
      );
      AppLogger.log('-------------------------------------');
    }

    return Row(
      children: [
        _buildStatusIndicator(statusColor),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pago ${pago.semana}/$_totalSemanasDelCredito',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    // Añadido Expanded para evitar overflow
                    child: Text(
                      'Vence: ${formatearFecha(pago.fechaPago)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Cambiado la estructura de la columna derecha
        Expanded(
          // Añadido Expanded para limitar el ancho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatearNumero(pago.capitalMasInteres),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              // Mejorado el Row para el chip y el ícono
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Chip con Flexible para evitar overflow
                  _buildCompactStatusChip(estado, statusColor),
                  SizedBox(width: 4),
                  // Ícono de tipo de pago
                  if (isFinished)
                    if (pago.tipoPago == 'Completo' &&
                        _fuePagadoConGarantia(pago))
                      _buildPaymentTypeIcon('Garantía')
                    else
                      _buildPaymentTypeIcon(pago.tipoPago),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- El resto de tus funciones permanece igual ---

  Widget _buildStatusIndicator(Color color) {
    return Container(
      width: 4,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /*  Widget _buildStatusChip(String estado, Color color) {
  return Flexible( // Cambiado de Container a Flexible
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reducido padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 7, // Reducido de 8 a 7
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3, // Reducido de 0.5 a 0.3
        ),
        overflow: TextOverflow.ellipsis, // Añadido para cortar texto largo
        maxLines: 1, // Forzar una sola línea
      ),
    ),
  );
} */

  Widget _buildCompactStatusChip(String estado, Color color) {
    // Mapeo de estados a versiones cortas
    String estadoCorto = estado.toUpperCase();

    switch (estado.toLowerCase()) {
      case 'garantia':
        estadoCorto = 'GARANTÍA';
        break;
      case 'garantia pagada':
        estadoCorto = 'GARANTÍA PAGADA';
        break;
      case 'pagado para renovacion':
        estadoCorto = 'RENOVACIÓN';
        break;
      case 'pagado con retraso':
        estadoCorto = 'RETRASO';
        break;
      case 'pendiente':
        estadoCorto = 'PENDIENTE';
        break;
      case 'en abonos':
        estadoCorto = 'ABONOS';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estadoCorto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // En tu widget _ControlPagosTabState (o donde tengas esta función)

  // En tu widget _ControlPagosTabState (o donde tengas esta función)

  Widget _buildTrailingIcon(
    bool isFinished,
    IconData icon,
    Color color,
    Pago pago,
    double saldoFavorTotalAcumulado,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    final int numeroDeIndicadores = _calcularIndicadoresActivos(
      pago,
      saldoFavorTotalAcumulado,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono de estado (sin cambios)
        if (isFinished)
          Icon(icon, color: color, size: 22)
        else
          Icon(
            Icons.expand_more,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
          ),

        // Botón de "más opciones" con el Badge modificado
        Container(
          height: 32,
          width: 32,
          child: Badge(
            isLabelVisible: numeroDeIndicadores > 0,
            backgroundColor: colors.brandPrimary,

            // ▼▼▼ CAMBIOS PARA EL TAMAÑO ▼▼▼

            // 1. AJUSTAR EL PADDING DEL BADGE
            // El padding por defecto es `EdgeInsets.symmetric(horizontal: 4)`.
            // Lo reducimos para que el círculo sea más pequeño.
            // Prueba con diferentes valores hasta que te guste.
            padding: const EdgeInsets.symmetric(horizontal: 5),

            // 2. PERSONALIZAR EL TEXTO DEL LABEL
            // Envolvemos el número en un Text widget con un TextStyle.
            label: Text(
              '$numeroDeIndicadores',
              style: const TextStyle(
                fontSize: 10, // Un tamaño de fuente más pequeño.
                color: Colors.white, // Aseguramos que el texto sea blanco.
                fontWeight: FontWeight.bold, // Opcional: para que se lea mejor.
              ),
            ),

            // ▲▲▲ FIN DE LOS CAMBIOS DE TAMAÑO ▲▲▲

            // Ajustamos el offset para que el badge más pequeño siga viéndose bien.
            // Quizás necesites reajustar estos valores.
            offset: const Offset(0, -5),

            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed:
                  () => _showAdvancedOptions(context, pago.idfechaspagos!),
              icon: Icon(
                Icons.more_vert,
                color: colors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Widget _buildExpandedContent(Pago pago, bool isDarkMode, bool isFinished) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Línea divisoria (sin cambios)
        Container(
          height: 1,
          color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
          margin: EdgeInsets.only(top: 6, bottom: 16),
        ),

        // --- INICIO DE LA INTEGRACIÓN ---
        // 2. Aquí llamamos a nuestro nuevo widget de saldo a favor.
        //    Si no hay saldo que mostrar, devolverá un SizedBox.shrink() y no afectará el layout.
        _buildSaldoFavorInfo(pago, isDarkMode),
        // --- FIN DE LA INTEGRACIÓN ---

        // 3. El resto de los controles de pago (sin cambios)
        _buildPaymentTypeSelector(pago, isDarkMode, isFinished),
        SizedBox(height: 20),
        _buildDynamicPaymentArea(pago, isDarkMode, isFinished),
      ],
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Widget _buildPaymentTypeSelector(
    Pago pago,
    bool isDarkMode,
    bool isFinished,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // Si el pago está verdaderamente finalizado, mostramos la info de solo lectura.
    if (isFinished) {
      // --- INICIO DE LA CORRECCIÓN DE PRIORIDAD ---
      String valorMostrado;

      // PRIORIDAD #1: Si el tipo de pago oficial es "En Abonos", esa es la etiqueta.
      if (pago.tipoPago?.toLowerCase() == 'en abonos') {
        valorMostrado = 'En Abonos';
      }
      // PRIORIDAD #2: Si no es en abonos, PERO se usó garantía, mostramos "Garantía".
      else if (_fuePagadoConGarantia(pago)) {
        valorMostrado = 'Garantía';
      }
      // PRIORIDAD #3: Como última opción, mostramos lo que sea que diga el tipo de pago.
      else {
        valorMostrado = pago.tipoPago ?? 'No especificado';
      }
      // --- FIN DE LA CORRECCIÓN DE PRIORIDAD ---

      return _buildReadOnlyField(
        label: 'Tipo de Pago Realizado',
        value: valorMostrado,
        icon: Icons.payment,
        isDarkMode: isDarkMode,
      );
    }

    // Si NO está finalizado, el Dropdown para que el usuario interactúe no cambia.
    final List<String> opcionesDisponibles = [
      'Completo',
      'Monto Parcial',
      'En Abonos',
      if (pago.semana >= _totalSemanasDelCredito - 1) 'Garantía',
    ];

    String? valorActual =
        opcionesDisponibles.contains(pago.tipoPago) ? pago.tipoPago : null;
    if (pago.tipoPago?.toLowerCase() == 'garantia' &&
        !opcionesDisponibles.contains('Garantía')) {
      valorActual = 'En Abonos';
    }

    return DropdownButtonFormField<String?>(
      value: valorActual,
      hint: Text(
        'Seleccionar Pago:',
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
        ),
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        filled: true,
        fillColor: colors.backgroundCardDark,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
      items:
          opcionesDisponibles
              .map(
                (label) => DropdownMenuItem(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  value: label,
                ),
              )
              .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          pago.tipoPago = value;
          pago.fechaPago = DateTime.now().toIso8601String();
          _semanasModificadas.add(pago.semana);
        });
      },
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: colors.disabledCard,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[400], size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Widget _buildDynamicPaymentArea(Pago pago, bool isDarkMode, bool isFinished) {
    // --- INICIO DE LA CORRECCIÓN DE PRIORIDAD ---

    // PRIORIDAD #1: ¿El pago fue 'En Abonos'?
    // Si es así, SIEMPRE mostramos el área de abonos, sin importar nada más.
    // Esto cumple con tu requisito de "aunque tenga garantia".
    if (pago.tipoPago?.toLowerCase() == 'en abonos') {
      return _buildEnAbonosArea(pago, isDarkMode, isFinished);
    }

    // PRIORIDAD #2: Si no fue 'En Abonos', ahora sí revisamos si se usó garantía.
    if (isFinished && _fuePagadoConGarantia(pago)) {
      return _buildGarantiaArea(pago, isDarkMode, isFinished);
    }

    // PRIORIDAD #3: Si no fue ninguna de las anteriores, usamos el switch para los demás casos.
    switch (pago.tipoPago?.toLowerCase()) {
      case 'completo':
        return _buildCompletoArea(pago, isDarkMode, isFinished);
      case 'monto parcial':
        return _buildMontoParcialArea(pago, isDarkMode, isFinished);
      case 'garantía':
        // Este caso sigue siendo útil para cuando se SELECCIONA 'Garantía' antes de guardar.
        return _buildGarantiaArea(pago, isDarkMode, isFinished);
      case null:
      default:
        // Fallback: si no hay tipo pero está finalizado y tiene abonos, lo tratamos como 'En Abonos'.
        if (isFinished && pago.abonos.isNotEmpty) {
          return _buildEnAbonosArea(pago, isDarkMode, isFinished);
        }
        return SizedBox.shrink();
    }
    // --- FIN DE LA CORRECCIÓN DE PRIORIDAD ---
  }

  Widget _buildCompletoArea(Pago pago, bool isDarkMode, bool isFinished) {
    if (isFinished) {
      // Buscar la fecha del pago en los abonos si existe
      String fechaPago = formatearFecha(pago.fechaPago);

      // Si hay abonos, usar la fecha del último abono como fecha de pago real
      if (pago.abonos.isNotEmpty) {
        final ultimoAbono = pago.abonos.last;
        if (ultimoAbono['fechaDeposito'] != null) {
          fechaPago = formatearFecha(ultimoAbono['fechaDeposito']);
        }
      }

      return Column(
        children: [
          _buildReadOnlyField(
            label: 'Monto Completo Pagado',
            value: formatearNumero(pago.sumaDepositoMoratorisos ?? 0.0),
            icon: Icons.paid,
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 24),
          _buildReadOnlyField(
            label: 'Pagado el',
            value: fechaPago,
            icon: Icons.event_available,
            isDarkMode: isDarkMode,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pago Completo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Monto total a pagar',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatearNumero(pago.capitalMasInteres),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildDateSelector(pago, isDarkMode, isFinished),
      ],
    );
  }

  // --- CAMBIO PRINCIPAL AQUÍ ---
  // --- REEMPLAZA TU FUNCIÓN CON ESTA VERSIÓN ACTUALIZADA ---
  // DENTRO DE: _ControlPagosTabState

  Widget _buildMontoParcialArea(Pago pago, bool isDarkMode, bool isFinished) {
    // ==========================================================
    // <<< INICIO DE LA CORRECCIÓN >>>
    // ==========================================================
    if (isFinished) {
      // Para pagos finalizados, mostramos un resumen limpio SIN el chip de saldo.
      // La información del saldo ya está en la tarjeta _buildSaldoFavorInfo.

      String fechaPago = formatearFecha(pago.fechaPago);
      if (pago.abonos.isNotEmpty) {
        final ultimoAbono = pago.abonos.last;
        if (ultimoAbono['fechaDeposito'] != null) {
          fechaPago = formatearFecha(ultimoAbono['fechaDeposito']);
        }
      }

      return Column(
        children: [
          // 1. Mostramos el monto total que se pagó.
          _buildReadOnlyField(
            label: 'Monto Parcial Pagado',
            value: formatearNumero(pago.sumaDepositoMoratorisos),
            icon: Icons.pie_chart,
            isDarkMode: isDarkMode,
          ),

          // 2. ¡ELIMINADO! Ya no mostramos el _buildSaldoChip aquí.
          SizedBox(height: 24),

          // 3. Mostramos la fecha del pago.
          _buildReadOnlyField(
            label: 'Pagado el',
            value: fechaPago,
            icon: Icons.event_available,
            isDarkMode: isDarkMode,
          ),
        ],
      );
    }
    // ==========================================================
    // <<< FIN DE LA CORRECCIÓN >>>
    // ==========================================================

    // --- El resto de la función (para cuando el pago está PENDIENTE) no necesita cambios ---
    final controller = _montoParcialControllers.putIfAbsent(
      pago.semana,
      () => TextEditingController(),
    );

    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: (value) {
            // --- INICIO DE LA LÓGICA ADAPTADA ---
            final montoIngresado =
                double.tryParse(value.replaceAll(",", "")) ?? 0.0;
            // ▼▼▼ CAMBIO AQUÍ: LA DEUDA AHORA INCLUYE MORATORIOS ▼▼▼
            final deudaTotalSemana =
                pago.capitalMasInteres + (pago.moratorios?.moratorios ?? 0.0);
            // ▲▲▲ FIN DEL CAMBIO ▲▲▲

            final diferencia = montoIngresado - deudaTotalSemana;

            setState(() {
              _saldosCalculados[pago.semana] = diferencia;

              // ▼▼▼ AÑADE ESTE AppLogger.log AQUÍ ▼▼▼
              AppLogger.log(
                "------------------------------------------------------",
              );
              AppLogger.log("📱 CÁLCULO LOCAL 📱 El usuario está escribiendo.");
              AppLogger.log(
                "Semana ${pago.semana} -> Monto ingresado: $montoIngresado",
              );
              AppLogger.log(
                "El mapa local de saldos ahora es: $_saldosCalculados",
              );
              AppLogger.log(
                "------------------------------------------------------",
              );
              // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲
            });
          },
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.grey[800],
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: 'Monto a Pagar',
            labelStyle: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor: isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
          ),
        ),
        SizedBox(height: 16),
        // ==========================================================
        // <<< INICIO DE LA MEJORA CLAVE >>>
        // ==========================================================
        // Usamos un AnimatedSwitcher para mostrar el saldo solo cuando se interactúa
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            );
          },
          child:
              (_montoParcialControllers[pago.semana]?.text.isNotEmpty ?? false)
                  ? _buildSaldoCalculadoDisplay(pago) // El widget que ya tenías
                  : SizedBox.shrink(), // Cuando está vacío, no muestra nada
        ),

        // ==========================================================
        // <<< FIN DE LA MEJORA CLAVE >>>
        // ==========================================================
        SizedBox(height: 16),
        _buildDateSelector(pago, isDarkMode, isFinished),
      ],
    );
  }

  // --- NUEVO: Widget para mostrar el saldo calculado ---
  // --- REEMPLAZA TU FUNCIÓN _buildSaldoCalculadoDisplay CON ESTA VERSIÓN ADAPTADA ---
  Widget _buildSaldoCalculadoDisplay(Pago pago) {
    // <<< LÓGICA ADAPTADA >>>
    // Leemos de los mapas de tiempo real.
    final double? saldoFavor = _saldosFavorEnTiempoReal[pago.semana];
    final double? saldoContra = _saldosContraEnTiempoReal[pago.semana];
    final controllerText = _montoParcialControllers[pago.semana]?.text ?? '';

    if (controllerText.isEmpty) {
      return SizedBox.shrink();
    }

    double? saldo;
    bool esFavor = false;

    if (saldoFavor != null && saldoFavor > 0.01) {
      saldo = saldoFavor;
      esFavor = true;
    } else if (saldoContra != null && saldoContra > 0.01) {
      saldo = saldoContra;
      esFavor = false;
    } else {
      return SizedBox.shrink(); // No mostrar nada si el saldo es cero o no hay interacción.
    }

    final String texto = esFavor ? 'Saldo a Favor' : 'Saldo en Contra';
    final Color color = esFavor ? Colors.green : Colors.red;
    final IconData icono =
        esFavor ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    // El resto del widget es visual y no cambia
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey(
          saldo,
        ), // Clave para que AnimatedSwitcher sepa que el contenido cambió
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  texto,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              formatearNumero(
                saldo.abs(),
              ), // .abs() para mostrar siempre un número positivo
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CAMBIO PRINCIPAL AQUÍ ---
  Widget _buildEnAbonosArea(Pago pago, bool isDarkMode, bool isFinished) {
    // Calcular el total abonado previamente
    final double totalAbonado = pago.abonos.fold<double>(
      0.0,
      (sum, abono) =>
          sum + (double.tryParse(abono['deposito']?.toString() ?? '0') ?? 0.0),
    );

    // Determinar si se debe mostrar el formulario de nuevo abono
    final bool mostrarFormulario =
        _mostrandoFormularioAbono[pago.semana] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen del total abonado (lo mostramos siempre)
        if (pago.abonos.isNotEmpty) ...[
          _buildResumenAbonos(
            pago,
            totalAbonado,
            isDarkMode,
            isFinished,
          ), // <-- Pasa el flag
          SizedBox(height: 16),
        ],

        // --- NUEVO: Lógica para alternar entre botones y formulario ---
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child:
              mostrarFormulario && !isFinished
                  ? _buildFormularioNuevoAbono(
                    pago,
                    totalAbonado,
                    isDarkMode,
                  ) // El formulario
                  : _buildBotonesAccionAbonos(pago, isFinished), // Los botones
        ),
      ],
    );
  }

  // ▼▼▼ AÑADE ESTA NUEVA FUNCIÓN A TU CLASE ▼▼▼
  /// Muestra un DatePicker para seleccionar la fecha de un nuevo abono.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Future<void> _seleccionarFechaAbono(
    BuildContext context,
    int semana,
    StateSetter? setStateInDialog, // <-- 1. NUEVO PARÁMETRO
  ) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNuevoAbono[semana] ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Fecha del Abono',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      // 2. LÓGICA DE ACTUALIZACIÓN
      if (setStateInDialog != null) {
        // Si estamos dentro de un diálogo, usamos su StateSetter
        setStateInDialog(() {
          _fechaNuevoAbono[semana] = fechaSeleccionada;
        });
      } else {
        // Si no (caso de la vista móvil original), usamos el setState de la página
        setState(() {
          _fechaNuevoAbono[semana] = fechaSeleccionada;
        });
      }
    }
  }
  // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲

  // --- NUEVO: Widget extraído para los botones de acción ---
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Widget _buildBotonesAccionAbonos(Pago pago, bool isFinished) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                isFinished
                    ? null
                    : () {
                      // ▼▼▼ CAMBIO AQUÍ ▼▼▼
                      _showAbonosDialog(
                        context,
                        pago,
                        mostrarFormularioInicial: true,
                      );
                    },
            icon: Icon(Icons.add_circle_outline, size: 18),
            label: Text('Agregar Abono', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // ▼▼▼ CAMBIO AQUÍ ▼▼▼
              _showAbonosDialog(context, pago, mostrarFormularioInicial: false);
            },
            icon: Icon(Icons.list_alt_rounded, size: 18),
            label: Text('Ver Abonos', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: BorderSide(color: Colors.blue),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- NUEVO: Widget para el resumen de abonos ---
  // --- REEMPLAZA TU FUNCIÓN CON ESTA VERSIÓN ACTUALIZADA ---
  // En: tu clase _ControlPagosTabState

  Widget _buildResumenAbonos(
    Pago pago,
    double totalAbonado,
    bool isDarkMode,
    bool isFinished,
  ) {
    // <-- Firma actualizada
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    final double saldo = totalAbonado - pago.capitalMasInteres;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.calculate_rounded, color: Colors.blueGrey[400], size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Abonado',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              Text(
                '${pago.abonos.length} abono${pago.abonos.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$ ${formatearNumero(totalAbonado)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),

            // --- INICIO DE LA CORRECCIÓN CLAVE ---
            // Solo muestra el chip si el pago NO está finalizado Y el saldo es significativo.
            if (!isFinished && saldo.abs() > 0.01) ...[
              SizedBox(height: 4),
              _buildSaldoChip(saldo),
            ],
            // --- FIN DE LA CORRECCIÓN CLAVE ---
          ],
        ),
      ],
    );
  }

  // --- AÑADE ESTA NUEVA FUNCIÓN AUXILIAR DENTRO DE TU CLASE _ControlPagosTabState ---
  Widget _buildSaldoChip(double saldo) {
    final bool esFavor = saldo >= 0;
    final Color color = esFavor ? Colors.green : Colors.red;
    final String texto = esFavor ? 'A FAVOR' : 'RESTANTE';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esFavor ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            '$texto: \$${formatearNumero(saldo.abs())}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildFormularioNuevoAbono(
    Pago pago,
    double totalAbonado,
    bool isDarkMode, {
    VoidCallback? onAbonoGuardado,
    StateSetter? setStateInDialog,
  }) {
    final controller = _nuevoAbonoControllers.putIfAbsent(
      pago.semana,
      () => TextEditingController(),
    );

    if (_fechaNuevoAbono[pago.semana] == null) {
      _fechaNuevoAbono[pago.semana] = DateTime.now();
    }

    // ▼▼▼ FUNCIÓN HELPER INTERNA ▼▼▼
    // Creamos una función que sabe cómo actualizar el estado, ya sea
    // del diálogo o de la página principal.
    void updateState(VoidCallback fn) {
      if (setStateInDialog != null) {
        setStateInDialog(fn);
      } else {
        setState(fn);
      }
    }
    // ▲▲▲ FIN DE LA FUNCIÓN HELPER ▲▲▲

    return Container(
      key: ValueKey('form_abono_${pago.semana}'),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1F1F1F) : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Registrar Nuevo Abono",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.blue[800],
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (value) {
              // ▼▼▼ USAMOS NUESTRA FUNCIÓN HELPER AQUÍ ▼▼▼
              updateState(() {
                final montoNuevo = double.tryParse(value) ?? 0.0;

                // ▼▼▼ CAMBIO AQUÍ: LA DEUDA AHORA INCLUYE MORATORIOS ▼▼▼
                final deudaTotalConMoratorios =
                    (pago.capitalMasInteres) +
                    (pago.moratorios?.moratorios ?? 0.0);
                final saldoRestante =
                    deudaTotalConMoratorios - totalAbonado - montoNuevo;
                // ▲▲▲ FIN DEL CAMBIO ▲▲▲

                _saldoRestanteCalculado[pago.semana] = saldoRestante;
              });
            },
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.grey[800],
              fontSize: 14,
            ),
            decoration: InputDecoration(
              // ... (el resto de la decoración no cambia)
              labelText: 'Monto del Abono',
              labelStyle: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              prefixText: '\$ ',
              prefixStyle: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Fecha del Abono',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  // La llamada aquí se mantiene igual porque ya se la pasamos al datepicker
                  onPressed:
                      () => _seleccionarFechaAbono(
                        context,
                        pago.semana,
                        setStateInDialog,
                      ),
                  child: Text(
                    formatearFecha(_fechaNuevoAbono[pago.semana]),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(sizeFactor: animation, child: child),
              );
            },
            child:
                (_nuevoAbonoControllers[pago.semana]?.text.isNotEmpty ?? false)
                    ? _buildSaldoRestanteDisplay(pago)
                    : SizedBox.shrink(),
          ),
          SizedBox(height: 16),
          Row(
            // ... (los botones de guardar/cancelar no cambian)
            children: [
              Expanded(
                child: ElevatedButton(
                  // ▼▼▼ REEMPLAZA SOLO EL 'onPressed' DEL BOTÓN DE GUARDAR ABONO ▼▼▼
                  onPressed: () {
                    final montoTexto = controller.text;
                    if (montoTexto.isEmpty ||
                        (double.tryParse(montoTexto) ?? 0) <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Por favor, ingresa un monto válido.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final fechaDelAbono =
                        _fechaNuevoAbono[pago.semana] ?? DateTime.now();
                    final nuevoAbono = {
                      'deposito': montoTexto,
                      'fechaDeposito': fechaDelAbono.toIso8601String(),
                      'garantia': 'No',
                    };

                    // Usamos la función helper para actualizar el estado correctamente
                    void updateState(VoidCallback fn) {
                      if (setStateInDialog != null) {
                        setStateInDialog(fn);
                      } else {
                        setState(fn);
                      }
                    }

                    updateState(() {
                      pago.abonos.add(nuevoAbono);
                      // pago.fechaPago = fechaDelAbono.toIso8601String(); // <-- LÍNEA ELIMINADA/COMENTADA
                      _semanasModificadas.add(pago.semana);

                      // Limpiamos los campos para el próximo abono
                      controller.clear();
                      _fechaNuevoAbono.remove(pago.semana);
                      _saldoRestanteCalculado.remove(pago.semana);
                    });

                    // Si hay un callback para cerrar el diálogo, lo llamamos
                    if (onAbonoGuardado != null) {
                      onAbonoGuardado();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Abono agregado localmente. ¡No olvides guardar los cambios!',
                          style: TextStyle(color: colors.blacBlack),
                        ),
                        backgroundColor: const Color(0xFFFFD500),
                        duration: Duration(seconds: 5),
                      ),
                    );
                  },
                  child: Text('Guardar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NUEVO: Widget para mostrar el saldo restante calculado ---
  Widget _buildSaldoRestanteDisplay(Pago pago) {
    final double? saldoRestante = _saldoRestanteCalculado[pago.semana];
    final controllerText = _nuevoAbonoControllers[pago.semana]?.text ?? '';

    // No mostrar si no se ha escrito nada
    if (saldoRestante == null || controllerText.isEmpty) {
      return SizedBox.shrink();
    }

    final Color color = saldoRestante > 0 ? Colors.red : Colors.green;
    final String texto =
        saldoRestante > 0 ? 'Saldo Restante' : '¡Cubierto! (Saldo a favor)';

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            formatearNumero(saldoRestante.abs()),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAbonosRow(double totalAbonado, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: colors.divider, height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calculate_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'TOTAL ABONADO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  letterSpacing: 0.8,
                ),
              ),
              Spacer(),
              Text(
                '\$ ${formatearNumero(totalAbonado)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Devuelve un pequeño chip visual para indicar que un abono fue con garantía.
  Widget _buildGarantiaChip() {
    return Container(
      margin: const EdgeInsets.only(top: 6), // Espacio para separarlo del monto
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Usamos el mismo color rosa/magenta para mantener la consistencia
        color: Colors.pink.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Importante: para que no ocupe toda la fila
        children: [
          Icon(Icons.security, color: Colors.pink, size: 12),
          SizedBox(width: 4),
          Text(
            'CON GARANTÍA',
            style: TextStyle(
              color: Colors.pink,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoratorioChip() {
    return Container(
      margin: const EdgeInsets.only(top: 6), // Espacio para separarlo
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Usamos un color naranja para diferenciarlo
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Importante para que no ocupe toda la fila
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 12),
          SizedBox(width: 4),
          Text(
            'PAGO MORATORIO',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  void _showAbonosDialog(
    BuildContext context,
    Pago pago, {
    bool mostrarFormularioInicial = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    _mostrandoFormularioAbono.remove(pago.semana);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInDialog) {
            // --- INICIO DE LA CORRECCIÓN CLAVE ---
            // Esta es la lógica correcta para determinar si un pago está finalizado.
            // La usamos aquí para ser consistentes con el resto de la app.
            // +++ CÓDIGO NUEVO Y CORREGIDO +++
            // +++ LÓGICA FINAL isFinished v7 - COMBINANDO CÁLCULO Y ESTADOS API +++

            // --- CÁLCULO MATEMÁTICO ---
            // 1. Reconstruimos la deuda total original de la semana.
            final double deudaTotalOriginal =
                pago.capitalMasInteres +
                pago.moratoriosPagados +
                (pago.moratorios?.moratorios ?? 0.0);

            // 2. Comparamos con el total abonado.
            final double totalAbonado = pago.sumaDepositoMoratorisos;
            final bool matematicamentePagado =
                totalAbonado >= (deudaTotalOriginal - 0.01);

            // --- ESTADOS EXPLÍCITOS DE LA API ---
            // 3. Creamos una lista con los estados que FORZAN la condición de "finalizado".
            //    Añadimos 'retraso' según tu petición.
            final List<String> estadosFinalesApi = [
              'pagado',
              'pagado con retraso',
              'pagado para renovacion',
              'garantia pagada',
              'retraso', // <-- AÑADIDO SEGÚN TU REQUISITO
            ];
            final bool apiDiceFinalizado = estadosFinalesApi.contains(
              pago.estado?.toLowerCase() ?? '',
            );

            // --- CONDICIÓN FINAL ---
            // 4. El pago está finalizado si la matemática lo confirma O si la API lo fuerza.
            final bool isFinished = matematicamentePagado || apiDiceFinalizado;

            // Opcional: AppLogger.log de debugging final para confirmar
            AppLogger.log('--- DEBUG v7 SEMANA ${pago.semana} ---');
            AppLogger.log(
              'Deuda Total: $deudaTotalOriginal | Total Abonado: $totalAbonado',
            );
            AppLogger.log('¿Matemáticamente Pagado?: $matematicamentePagado');
            AppLogger.log(
              'Estado API: "${pago.estado}", ¿API lo fuerza como finalizado?: $apiDiceFinalizado',
            );
            AppLogger.log('Resultado Final isFinished: $isFinished');
            AppLogger.log('----------------------------------');

            // +++ FIN DEL BLOQUE +++

            Widget content;
            // Ahora esta condición funcionará correctamente.
            if (mostrarFormularioInicial && !isFinished) {
              content = Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: _buildFormularioNuevoAbono(
                        pago,
                        totalAbonado,
                        isDarkMode,
                        setStateInDialog: setStateInDialog,
                        onAbonoGuardado: () => Navigator.pop(modalContext),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              content = Column(
                children: [
                  Expanded(
                    child:
                        pago.abonos.isEmpty
                            ? _buildEmptyAbonosState(isDarkMode)
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                10,
                                20,
                                20,
                              ),
                              itemCount: pago.abonos.length,
                              itemBuilder: (context, index) {
                                final abono = pago.abonos[index];
                                return _buildAbonoTile(
                                  abono,
                                  isDarkMode,
                                  index + 1,
                                  pago,
                                );
                              },
                            ),
                  ),
                  if (pago.abonos.isNotEmpty)
                    _buildTotalAbonosRow(totalAbonado, isDarkMode),
                ],
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.backgroundPrimary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white30 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 12),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          // El título también se beneficia de la lógica corregida.
                          mostrarFormularioInicial && !isFinished
                              ? 'Agregar Nuevo Abono'
                              : 'Abonos de la Semana ${pago.semana}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(child: content),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _mostrandoFormularioAbono.remove(pago.semana);
      _nuevoAbonoControllers[pago.semana]?.clear();
      _saldoRestanteCalculado.remove(pago.semana);
      _fechaNuevoAbono.remove(pago.semana);
    });
  }

  /// Muestra un diálogo de confirmación para eliminar un ABONO INDIVIDUAL.
  void _mostrarDialogoConfirmarEliminarAbono(
    BuildContext context,
    Pago pago,
    Map<String, dynamic> abono,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final double monto =
        double.tryParse(abono['deposito']?.toString() ?? '0') ?? 0.0;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
                SizedBox(width: 10),
                Text('Confirmar Eliminación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar el abono de \$${formatearNumero(monto)}?',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _ejecutarEliminacionAbono(pago, abono);
                },
                child: Text('Sí, Eliminar'),
              ),
            ],
          ),
    );
  }

  /// Llama al servicio para eliminar un ABONO INDIVIDUAL y maneja la respuesta.
  Future<void> _ejecutarEliminacionAbono(
    Pago pago,
    Map<String, dynamic> abono,
  ) async {
    final String? idAbono = abono['idpagos'];
    if (idAbono == null) return; // Seguridad extra

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminando abono...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      final response = await _pagoService.eliminarAbono(
        idAbono: idAbono,
        idFechasPago: pago.idfechaspagos!,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Abono eliminado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        _recargarPagos();
        widget.onDataChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error del servidor: ${response.error ?? "No se pudo eliminar."}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el abono: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyAbonosState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: isDarkMode ? Colors.white38 : Colors.grey[400],
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'No hay abonos registrados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbonoTile(
    Map<String, dynamic> abono,
    bool isDarkMode,
    int numeroAbono,
    Pago pago,
  ) {
    final double monto =
        double.tryParse(abono['deposito']?.toString() ?? '0') ?? 0.0;
    final String fecha = formatearFecha(abono['fechaDeposito']);

    // Lógica robusta para detectar el tipo de abono
    final bool esGarantia =
        (abono['garantia']?.toString() ?? 'No').trim().toLowerCase() == 'si';

    // <<< AÑADIR ESTA LÍNEA >>>
    final bool esMoratorio =
        (abono['moratorio']?.toString() ?? 'No').trim().toLowerCase() == 'si';

    final bool sePuedeEliminar =
        abono['idpagos'] != null && abono['idpagos'].toString().isNotEmpty;

    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final bool esAdmin = userData.tipoUsuario == 'Admin';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              '$numeroAbono',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monto del Abono',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '\$ ${formatearNumero(monto)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                // --- Lógica para mostrar los chips ---
                if (esGarantia) _buildGarantiaChip(),

                // <<< AÑADIR ESTA LÍNEA >>>
                if (esMoratorio) _buildMoratorioChip(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Pagado:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                fecha,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
          if (sePuedeEliminar && esAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: Icon(Icons.delete_outline, size: 20),
                color: Colors.red[300],
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                tooltip: 'Eliminar este abono (Solo Admin)',
                onPressed: () {
                  Navigator.pop(context);
                  _mostrarDialogoConfirmarEliminarAbono(context, pago, abono);
                },
              ),
            ),
        ],
      ),
    );
  }

  // En tu clase _ControlPagosTabState, reemplaza esta función completa.

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  Widget _buildGarantiaArea(Pago pago, bool isDarkMode, bool isFinished) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (isFinished) {
      final double montoUtilizado = pago.capitalMasInteres;
      final double garantiaTotal = widget.montoGarantia;

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.colors.disabledCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.pink, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.colors.textSecondary,
                    fontFamily:
                        Theme.of(context).textTheme.bodyLarge?.fontFamily,
                  ),
                  children: [
                    TextSpan(text: 'Se cubrió con '),
                    TextSpan(
                      text: '\$${formatearNumero(montoUtilizado)}',
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' de la garantía de '),
                    TextSpan(
                      text: '\$${formatearNumero(garantiaTotal)}',
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ▼▼▼ CAMBIO PRINCIPAL AQUÍ ▼▼▼
    // Envolvemos el widget en una Columna para poder añadir
    // el selector de fecha debajo de la información de la garantía.
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield, color: Colors.amber[700], size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usar Garantía',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Aplicar monto de garantía',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatearNumero(widget.montoGarantia),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16), // Espacio entre la info y el selector
        _buildDateSelector(
          pago,
          isDarkMode,
          isFinished,
        ), // Selector de fecha añadido
      ],
    );
    // ▲▲▲ FIN DEL CAMBIO ▲▲▲
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  // ▼▼▼ REEMPLAZA ESTA FUNCIÓN COMPLETA ▼▼▼
  Widget _buildDateSelector(Pago pago, bool isDarkMode, bool isFinished) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // Determina qué fecha mostrar en el botón
    Object fechaADisplegar;
    if (isFinished) {
      // Si está pagado, la fecha es la del último abono, o la de vencimiento si no hay abonos
      fechaADisplegar =
          (pago.abonos.isNotEmpty
              ? pago.abonos.last['fechaDeposito']
              : pago.fechaPago) ??
          DateTime.now();
    } else {
      // Si está pendiente, muestra la fecha que el usuario seleccionó, o la de hoy por defecto
      fechaADisplegar = _fechasPagoSeleccionadas[pago.semana] ?? DateTime.now();
    }

    final String etiquetaFecha =
        isFinished ? 'Fecha de liquidación' : 'Fecha de pago';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isFinished ? colors.disabledCard : colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isFinished ? Icons.event_available : Icons.calendar_today,
                size: 18,
                color:
                    isFinished
                        ? Colors.green
                        : (isDarkMode ? Colors.white60 : Colors.grey[600]),
              ),
              SizedBox(width: 8),
              Text(
                etiquetaFecha,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed:
                isFinished ? null : () => _seleccionarFecha(context, pago),
            child: Text(
              formatearFecha(
                fechaADisplegar,
              ), // <-- Ahora siempre mostrará la fecha correcta
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isFinished
                        ? Colors.green
                        : (isDarkMode ? Colors.white : Color(0xFF4F46E5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar un pago.
  void _mostrarDialogoConfirmacionEliminar(BuildContext context, Pago pago) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
                SizedBox(width: 10),
                Text('Confirmar Eliminación'),
              ],
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar TODOS los pagos registrados para la semana ${pago.semana}?\n\nEsta acción no se puede deshacer.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Cierra el diálogo y procede con la eliminación.
                  Navigator.pop(dialogContext);
                  _ejecutarEliminacion(pago);
                },
                child: Text('Sí, Eliminar'),
              ),
            ],
          ),
    );
  }

  /// Llama al servicio para eliminar el pago y maneja la respuesta.
  /// Itera sobre los abonos de un pago y los elimina uno por uno, luego recarga.
  Future<void> _ejecutarEliminacion(Pago pago) async {
    // 1. Obtenemos la lista de abonos que ya están guardados en el servidor.
    //    Estos son los que tienen un ID en el campo 'idpagos'.
    final List<Map<String, dynamic>> abonosAEliminar =
        pago.abonos
            .where(
              (abono) =>
                  abono['idpagos'] != null &&
                  abono['idpagos'].toString().isNotEmpty,
            )
            .toList();

    if (abonosAEliminar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontraron depósitos registrados para eliminar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminando ${abonosAEliminar.length} depósito(s)...'),
        backgroundColor: Colors.blue,
      ),
    );

    bool huboError = false;

    // 2. Iteramos sobre cada abono y llamamos al servicio de eliminación.
    for (final abono in abonosAEliminar) {
      try {
        final String idAbono = abono['idpagos'];
        final String idFechasPago = pago.idfechaspagos!;

        AppLogger.log(
          'Eliminando abono: idAbono=$idAbono, idFechasPago=$idFechasPago',
        );

        // Usamos el método que ya existía en el servicio.
        final response = await _pagoService.eliminarAbono(
          idAbono: idAbono,
          idFechasPago: idFechasPago,
        );

        if (!response.success) {
          // Si un abono falla, marcamos el error y continuamos con los demás.
          huboError = true;
          AppLogger.log(
            'Error al eliminar el abono $idAbono: ${response.error}',
          );
          // Opcional: podrías detener el proceso aquí si lo prefieres.
          // break;
        }
      } catch (e) {
        huboError = true;
        AppLogger.log('Excepción al eliminar el abono ${abono['idpagos']}: $e');
        // break; // Detener en caso de excepción de red, etc.
      }
    }

    // 3. Al finalizar el bucle, mostramos un resultado final y recargamos.
    if (huboError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocurrió un error al eliminar algunos depósitos. Por favor, revisa.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pagos eliminados exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // 4. Recargamos la lista de pagos desde el servidor para reflejar los cambios.
    _recargarPagos();
    widget.onDataChanged();
  }

  // --- DESPUÉS (La versión corregida que debes usar) ---
  void _showAdvancedOptions(BuildContext context, String idFechasPago) {
    // 1. CAMBIASTE LA FIRMA: Ahora recibe un String llamado 'idFechasPago'.

    // 2. BUSCA EL OBJETO 'PAGO' FRESCO EN TU LISTA DE ESTADO
    // Esto asegura que tienes los datos más recientes (como los abonos).
    // --- DESPUÉS (código correcto y moderno) ---
    final Pago? pagoActualizado = _pagosActuales.firstWhereOrNull(
      (p) => p.idfechaspagos == idFechasPago,
    );

    // 3. MEDIDA DE SEGURIDAD: Si no se encontró el pago, no continuamos.
    if (pagoActualizado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo encontrar la información del pago.'),
        ),
      );
      return;
    }

    // <<< INICIO DEL CAMBIO (1/2) >>>
    // Obtenemos el provider para saber si el usuario es Admin
    final userData = Provider.of<UserDataProvider>(context, listen: false);
    final bool esAdmin = userData.tipoUsuario == 'Admin';
    // <<< FIN DEL CAMBIO (1/2) >>>

    // ==========================================================
    // <<< AÑADE ESTE AppLogger.log PARA DEPURAR >>>
    // ==========================================================
    AppLogger.log("--- ABRIENDO MODAL PARA PAGO ${pagoActualizado.semana} ---");
    AppLogger.log(
      "Suma de depósitos (tieneActividad): ${pagoActualizado.sumaDepositoMoratorisos}",
    );
    AppLogger.log("Saldo en contra: ${pagoActualizado.saldoEnContra}");
    AppLogger.log("------------------------------------------");
    // ==========================================================

    // 4. A PARTIR DE AQUÍ, USA 'pagoActualizado' EN LUGAR DE 'pago'.
    // Tu lógica para calcular el saldo a favor ya usa la lista completa, así que está bien.
    double saldoFavorTotalAcumulado = _pagosActuales.fold(
      0.0,
      (sum, p) => sum + p.saldoRestante, // <-- Usa el nuevo getter
    );

    // ▼▼▼ AÑADE ESTE AppLogger.log AQUÍ ▼▼▼
    AppLogger.log("======================================================");
    AppLogger.log(
      "🌍 DATOS DEL SERVIDOR 🌍 Se reconstruyó la UI con datos de la API.",
    );
    AppLogger.log(
      "Saldos restantes individuales: ${_pagosActuales.map((p) => p.saldoRestante?.toStringAsFixed(2) ?? '0.00').toList()}",
    );
    AppLogger.log(
      "SALDO A FAVOR TOTAL (DEL SERVIDOR): \$${formatearNumero(saldoFavorTotalAcumulado)}",
    );
    AppLogger.log("======================================================");
    // ▲▲▲ FIN DEL CÓDIGO AÑADIDO ▲▲▲

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return AdvancedOptionsSheet(
          // 5. PASA EL OBJETO FRESCO Y ACTUALIZADO AL MODAL
          pago: pagoActualizado,
          idCredito: widget.idCredito,
          clientesParaRenovar: widget.clientesParaRenovar,
          saldoFavorTotalAcumulado: saldoFavorTotalAcumulado,
          onDataChanged: () {
            _recargarPagos();
            if (widget.onDataChanged != null) {
              widget.onDataChanged!();
            }
          },
          pagoService: _pagoService,
          esAdmin: esAdmin,
        );
      },
    );
  }

  /// Calcula el número de indicadores activos para un pago específico.
  /// Calcula el número de indicadores activos para un pago específico.
  // REEMPLAZA ESTA FUNCIÓN DENTRO DE _ControlPagosTabState
  /// Calcula el número de indicadores activos para un pago específico.
  int _calcularIndicadoresActivos(Pago pago, double saldoFavorTotalAcumulado) {
    int contador = 0;

    // Condición 1: Tiene moratorios activos (esto ya está bien).
    if (pago.tieneMoratoriosActivos) {
      contador++;
    }

    // Condición 2: Tiene renovaciones pendientes (esto ya está bien).
    if (pago.tieneRenovacionesPendientes) {
      contador++;
    }

    // --- INICIO DE LA LÓGICA CORREGIDA PARA SALDO A FAVOR ---
    // Condición 3: Se mostrará el indicador si YA SE UTILIZÓ saldo a favor
    // en este pago en particular.
    if ((pago.favorUtilizado ?? 0.0) > 0.01) {
      contador++;
    }
    // --- FIN DE LA LÓGICA CORREGIDA ---

    return contador;
  }

  /// Muestra la información detallada sobre el saldo a favor de un pago específico.
  /// Este widget se adapta dinámicamente para mostrar si el saldo está disponible,
  /// fue usado parcialmente o se consumió por completo.
  // Y asegúrate de tener la función _buildSaldoFavorInfo que ya creamos
  // (La pego de nuevo aquí por si acaso, pero ya la deberías tener)
  // DENTRO DE: _ControlPagosTabState

  /// Muestra la información de saldo a favor de forma compacta.
  // Pega esta nueva función dentro de tu clase _ControlPagosTabState

  /// Muestra la información de saldo a favor de forma compacta y detallada.
  /// Se adapta para mostrar si está disponible, se usó parcialmente o del todo.
  // REEMPLAZA ESTA FUNCIÓN COMPLETA
  /// Muestra la información de saldo a favor de forma compacta y detallada.
  /// Se adapta para mostrar si está disponible, se usó parcialmente o del todo.
  Widget _buildSaldoFavorInfo(Pago pago, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    if ((pago.saldoFavorOriginalGenerado ?? 0.0) <= 0.01) {
      return SizedBox.shrink();
    }

    final double original = pago.saldoFavorOriginalGenerado;
    final double restante = pago.saldoRestante ?? 0.0;
    final bool fueUsado = restante < original;

    IconData iconData;
    Color iconColor;
    Widget infoWidget;

    // --- Lógica de visualización con Tooltips ---

    // CASO 1: El saldo se usó por completo.
    if (fueUsado && restante <= 0.01) {
      iconData = Icons.check_circle_outline;
      iconColor = Colors.grey;
      infoWidget = Tooltip(
        // --- TOOLTIP AÑADIDO ---
        message:
            'Se utilizaron \$${formatearNumero(original)} de este saldo a favor.',
        child: Text(
          '\$${formatearNumero(original)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white54 : Colors.black45,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      );
    }
    // CASO 2: El saldo se usó parcialmente.
    else if (fueUsado && restante > 0.01) {
      final double usado = original - restante; // Calculamos cuánto se usó.
      iconData = Icons.scatter_plot_outlined;
      iconColor = Colors.orange.shade700;
      infoWidget = Tooltip(
        // --- TOOLTIP AÑADIDO ---
        message:
            'Se utilizaron \$${formatearNumero(usado)} de este saldo a favor.',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$${formatearNumero(restante)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(de \$${formatearNumero(original)})',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    // CASO 3: El saldo está intacto (no se ha usado).
    else {
      iconData = Icons.savings_outlined;
      iconColor = Colors.green.shade600;
      // No necesita tooltip porque no se ha usado.
      infoWidget = Text(
        '\$${formatearNumero(original)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade600,
        ),
      );
    }

    // El contenedor que se mostrará
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Saldo a Favor Generado:',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          infoWidget,
        ],
      ),
    );
  }
}
// --- Pega esta función dentro de la clase _ControlPagosTabState ---

// Función para centralizar la lógica de colores e iconos según el estado del pago
Map<String, dynamic> _getStatusDetails(String estado) {
  Color statusColor;
  IconData statusIcon;

  // Lógica extraída de tu archivo seguimiento_screen.dart
  switch (estado.toLowerCase()) {
    case 'pagado':
    case 'pagado para renovacion':
    case 'pagado con retraso':
      statusColor = Colors.green; // Unificamos pagados a verde
      statusIcon = Icons.check_circle;
      break;
    case 'pendiente':
    case 'en abonos':
      statusColor = Colors.blue; // Pendientes y abonos en azul
      statusIcon = Icons.schedule;
      break;
    case 'atraso': // "Atraso" del cronograma y "Atrasado" que calculabas antes
      statusColor = Colors.orange; // Usaremos naranja para Atraso
      statusIcon = Icons.error_outline;
      break;
    case 'proximo':
      statusColor = Colors.grey; // "Próximo" es menos urgente que "Pendiente"
      statusIcon = Icons.hourglass_empty;
      break;
    case 'garantia':
      statusColor = Colors.pink;
      statusIcon = Icons.check_circle;
      break;
    case 'garantia pagada':
      statusColor = Colors.pink;
      statusIcon = Icons.check_circle;
      break;
    case 'retraso':
      statusColor = Colors.green;
      statusIcon = Icons.timelapse;
      break;
    default:
      statusColor = Colors.grey;
      statusIcon = Icons.radio_button_unchecked;
  }

  // Un caso especial: si el estado es 'Pagado con retraso', el chip puede ser púrpura
  if (estado.toLowerCase() == 'pagado con retraso') {
    statusColor = Colors.purple;
  }

  return {'color': statusColor, 'icon': statusIcon};
}
