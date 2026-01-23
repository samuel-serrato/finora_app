// lib/screens/reporteContable.dart (VERSIÓN FINAL COMPLETA CON FILTRO)

import 'dart:math';

import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// =========================================================================
// === ESTRUCTURA PRINCIPAL: STATEFULWIDGET PARA MANEJAR EL FILTRO =========
// =========================================================================
class ReporteContableWidget extends StatefulWidget {
  final ReporteContableData reporteData;
  final NumberFormat currencyFormat;
  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;

  const ReporteContableWidget({
    super.key,
    required this.reporteData,
    required this.currencyFormat,
    this.verticalScrollController,
    this.horizontalScrollController,
  });

  @override
  State<ReporteContableWidget> createState() => _ReporteContableWidgetState();
}

class _ReporteContableWidgetState extends State<ReporteContableWidget> {
  // --- Constantes y Estado del Widget ---
  static const Color primaryColor = Color(0xFF5162F6);
  static const Color abonoGlobalColor = Colors.teal;
  static const Color garantiaColor = Color(0xFFE53888);
  static final Color saldoFavorColor = Colors.green.shade700;
  static final Color analysisColor = Colors.blue.shade800;

  bool _showOnlyPaid = false;
  List<ReporteContableGrupo> _filteredGrupos = [];

  @override
  void initState() {
    super.initState();
    // Inicializar la lista al construir el widget
    _filterGrupos();
  }

  // Se activa si los datos de entrada cambian (ej. al seleccionar otra semana)
  @override
  void didUpdateWidget(covariant ReporteContableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reporteData != widget.reporteData) {
      _filterGrupos();
    }
  }

  // --- Lógica Central del Filtro ---
  void _filterGrupos() {
    if (_showOnlyPaid) {
      // Filtrar para mostrar solo grupos con pagos en el período
      _filteredGrupos =
          widget.reporteData.listaGrupos.where((g) {
            final pagoActual =
                g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado;
            return pagoActual > 0;
          }).toList();
    } else {
      // Mostrar todos los grupos
      _filteredGrupos = List.from(widget.reporteData.listaGrupos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  // =========================================================================
  // === LAYOUTS PRINCIPALES (MÓVIL Y ESCRITORIO) ===========================
  // =========================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(child: _buildDesktopGruposList(context)),
                        const SizedBox(height: 8),
                        _buildDesktopTotalesCard(context),
                      ],
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

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Provider.of<ThemeProvider>(context).colors.backgroundPrimary,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMobileHeader(context),
          const SizedBox(height: 16),
          if (_filteredGrupos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Center(
                child: Text(
                  _showOnlyPaid
                      ? 'No hay grupos con pagos para mostrar'
                      : 'No hay grupos para mostrar',
                ),
              ),
            )
          else
            Column(
              children:
                  _filteredGrupos
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildMobileGrupoCard(
                          context,
                          entry.value,
                          entry.key,
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 16),
          _buildMobileTotalsSummary(context),
        ],
      ),
    );
  }

  // =========================================================================
  // === CABECERAS CON FILTRO ================================================
  // =========================================================================

  // lib/screens/reporteContable.dart

  Widget _buildDesktopHeader(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart_rounded, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          'Período: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          widget.reporteData.fechaSemana,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Generado: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          widget.reporteData.fechaActual,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
        const Spacer(),
        // === INICIO DEL CAMBIO ===
        Text(
          //'Mostrando ${_filteredGrupos.length} de ${widget.reporteData.listaGrupos.length}',
          'Mostrando ${widget.reporteData.listaGrupos.length} resultados',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        // === FIN DEL CAMBIO ===
        /* const Spacer(),
        Text(
          'Mostrar solo con pagos',
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: _showOnlyPaid,
          onChanged: (value) {
            setState(() {
              _showOnlyPaid = value;
              _filterGrupos();
            });
          },
          activeColor: primaryColor,
        ), */
      ],
    );
  }

  // lib/screens/reporteContable.dart

  Widget _buildMobileHeader(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_rounded,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Reporte Contable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileInfoRow(
            'Período',
            widget.reporteData.fechaSemana,
            context,
          ),
          _buildMobileInfoRow(
            'Generado',
            widget.reporteData.fechaActual,
            context,
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // === INICIO DEL CAMBIO ===
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* Text(
                      'Mostrar solo con pagos',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ), */
                    const SizedBox(height: 2),
                    Text(
                      //'Mostrando ${_filteredGrupos.length} de ${widget.reporteData.listaGrupos.length}',
                      'Mostrando ${widget.reporteData.listaGrupos.length} resultados',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // === FIN DEL CAMBIO ===
              /* SizedBox(
                height: 30,
                child: Switch.adaptive(
                  value: _showOnlyPaid,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyPaid = value;
                      _filterGrupos();
                    });
                  },
                  activeColor: primaryColor,
                ),
              ), */
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // === LISTA DE GRUPOS (USA LISTA FILTRADA) ===============================
  // =========================================================================

  Widget _buildDesktopGruposList(BuildContext context) {
    if (_filteredGrupos.isEmpty) {
      return Center(
        child: Text(
          _showOnlyPaid
              ? 'No hay grupos con pagos para mostrar'
              : 'No hay datos para mostrar',
        ),
      );
    }
    return ListView.builder(
      controller: widget.verticalScrollController,
      itemCount: _filteredGrupos.length,
      itemBuilder: (context, index) {
        final grupo = _filteredGrupos[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDesktopGrupoCard(context, grupo),
        );
      },
    );
  }

  // =========================================================================
  // === SECCIONES DE TOTALES (CALCULAN BASADO EN LISTA FILTRADA) ===========
  // =========================================================================

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  Widget _buildDesktopTotalesCard(BuildContext context) {
    final double totalCapital = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.capitalsemanal,
    );
    final double totalInteres = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.interessemanal,
    );
    final double totalFicha = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.montoficha,
    );

    // === CÁLCULO SIN GARANTÍA (EXISTENTE) ===
    final double totalPagoficha = _filteredGrupos.fold(0.0, (sum, g) {
      final depositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      return sum + depositosSinGarantia + g.pagoficha.favorUtilizado;
    });

    double totalCapitalRecaudadoPeriodo = 0;
    double totalInteresRecaudadoPeriodo = 0;

    for (var g in _filteredGrupos) {
      final pagoDepositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      final pagoActual = pagoDepositosSinGarantia + g.pagoficha.favorUtilizado;

      if (pagoActual > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActual;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudadoEsteGrupo =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoPeriodo += capitalRecaudadoEsteGrupo;
        totalInteresRecaudadoPeriodo +=
            (pagoActual - capitalRecaudadoEsteGrupo);
      }
    }

    // === INICIO: NUEVOS CÁLCULOS CON GARANTÍA PARA TOOLTIPS ===
    final double totalPagofichaConGarantia = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado,
    );

    double totalCapitalRecaudadoConGarantia = 0;
    double totalInteresRecaudadoConGarantia = 0;

    for (var g in _filteredGrupos) {
      final pagoActualConGarantia =
          g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado;
      if (pagoActualConGarantia > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActualConGarantia;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudado =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoConGarantia += capitalRecaudado;
        totalInteresRecaudadoConGarantia +=
            (pagoActualConGarantia - capitalRecaudado);
      }
    }
    // === FIN: NUEVOS CÁLCULOS CON GARANTÍA ===

    final double totalSaldoDisponible = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.saldoDisponible,
    );
    final double totalMoratoriosPagados = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.sumaMoratorio,
    );
    final double totalTotal = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.montoficha,
    );
    final double restante = totalTotal - totalPagoficha;
    final double nuevoTotalBruto =
        totalPagoficha + totalSaldoDisponible + totalMoratoriosPagados;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 1,
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Totales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: widget.horizontalScrollController,
                  child: Row(
                    children: [
                      Container(
                        height: 24,
                        width: 1,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        margin: const EdgeInsets.only(right: 16),
                      ),
                      _buildDesktopSummaryItem(
                        context,
                        'Capital (Período)',
                        totalCapital,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Interés (Período)',
                        totalInteres,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Monto Fichas',
                        totalFicha,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Pago Fichas',
                        totalPagoficha, // Valor sin garantía
                        tooltipMessage:
                            'Con Garantía: ${widget.currencyFormat.format(totalPagofichaConGarantia)}',
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Cap. Rec. (Período)',
                        totalCapitalRecaudadoPeriodo, // Valor sin garantía
                        tooltipMessage:
                            'Con Garantía: ${widget.currencyFormat.format(totalCapitalRecaudadoConGarantia)}',
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Interés Rec. (Período)',
                        totalInteresRecaudadoPeriodo, // Valor sin garantía
                        tooltipMessage:
                            'Con Garantía: ${widget.currencyFormat.format(totalInteresRecaudadoConGarantia)}',
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSaldoFavorTotalItem(
                        context,
                        totalSaldoDisponible,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Mor. Pag.',
                        totalMoratoriosPagados,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Total Ideal',
                        totalTotal,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Diferencia',
                        restante,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Total Bruto',
                        nuevoTotalBruto,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  Widget _buildMobileTotalsSummary(BuildContext context) {
    final double totalCapitalPeriodo = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.capitalsemanal,
    );
    final double totalInteresPeriodo = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.interessemanal,
    );

    // === CÁLCULO SIN GARANTÍA (EXISTENTE) ===
    final double totalPagoficha = _filteredGrupos.fold(0.0, (sum, g) {
      final depositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      return sum + depositosSinGarantia + g.pagoficha.favorUtilizado;
    });

    double totalCapitalRecaudadoPeriodo = 0;
    double totalInteresRecaudadoPeriodo = 0;
    for (var g in _filteredGrupos) {
      final pagoDepositosSinGarantia = g.pagoficha.depositos
          .where((d) => d.garantia != 'Si')
          .fold(0.0, (depSum, d) => depSum + d.deposito);
      final pagoActual = pagoDepositosSinGarantia + g.pagoficha.favorUtilizado;
      if (pagoActual > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActual;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudadoEsteGrupo =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoPeriodo += capitalRecaudadoEsteGrupo;
        totalInteresRecaudadoPeriodo +=
            (pagoActual - capitalRecaudadoEsteGrupo);
      }
    }

    // === INICIO: NUEVOS CÁLCULOS CON GARANTÍA PARA TOOLTIPS ===
    final double totalPagofichaConGarantia = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado,
    );

    double totalCapitalRecaudadoConGarantia = 0;
    double totalInteresRecaudadoConGarantia = 0;

    for (var g in _filteredGrupos) {
      final pagoActualConGarantia =
          g.pagoficha.sumaDeposito + g.pagoficha.favorUtilizado;
      if (pagoActualConGarantia > 0) {
        final saldoGlobalAnterior = g.saldoGlobal - pagoActualConGarantia;
        final capitalPendienteAnterior = max(
          0,
          g.montoDesembolsado - saldoGlobalAnterior,
        );
        final capitalPendienteActual = max(
          0,
          g.montoDesembolsado - g.saldoGlobal,
        );
        final capitalRecaudado =
            (capitalPendienteAnterior - capitalPendienteActual);
        totalCapitalRecaudadoConGarantia += capitalRecaudado;
        totalInteresRecaudadoConGarantia +=
            (pagoActualConGarantia - capitalRecaudado);
      }
    }
    // === FIN: NUEVOS CÁLCULOS CON GARANTÍA ===

    final double totalSaldoDisponible = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.saldoDisponible,
    );
    final double totalMoratoriosPagados = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.pagoficha.sumaMoratorio,
    );
    final double totalFicha = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.montoficha,
    );
    final double totalTotal = _filteredGrupos.fold(
      0.0,
      (sum, g) => sum + g.montoficha,
    );
    final double restante = totalTotal - totalPagoficha;
    final double nuevoTotalBruto =
        totalPagoficha + totalSaldoDisponible + totalMoratoriosPagados;

    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Resumen Financiero Total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Desglose Ideal del Período',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: analysisColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildMobileDetailRow(
            context,
            'Capital Total (Período)',
            widget.currencyFormat.format(totalCapitalPeriodo),
          ),
          _buildMobileDetailRow(
            context,
            'Interés Total (Período)',
            widget.currencyFormat.format(totalInteresPeriodo),
          ),
          const Divider(height: 16),
          _buildMobileDetailRow(
            context,
            'Monto Total Fichas',
            widget.currencyFormat.format(totalFicha),
          ),
          _buildMobileDetailRow(
            context,
            'Pago Total Fichas',
            widget.currencyFormat.format(totalPagoficha), // Valor sin garantía
            tooltipMessage:
                'Con Garantía: ${widget.currencyFormat.format(totalPagofichaConGarantia)}',
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Desglose de Pagos del Período',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: analysisColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildMobileDetailRow(
            context,
            'Capital Recaudado (Período)',
            widget.currencyFormat.format(
              totalCapitalRecaudadoPeriodo,
            ), // Valor sin garantía
            tooltipMessage:
                'Con Garantía: ${widget.currencyFormat.format(totalCapitalRecaudadoConGarantia)}',
          ),
          _buildMobileDetailRow(
            context,
            'Interés Recaudado (Período)',
            widget.currencyFormat.format(
              totalInteresRecaudadoPeriodo,
            ), // Valor sin garantía
            valueColor:
                totalInteresRecaudadoPeriodo > 0 ? Colors.green.shade700 : null,
            tooltipMessage:
                'Con Garantía: ${widget.currencyFormat.format(totalInteresRecaudadoConGarantia)}',
          ),
          const Divider(height: 16),
          _buildMobileDetailRow(
            context,
            'Moratorios Pag.',
            widget.currencyFormat.format(totalMoratoriosPagados),
            valueColor:
                totalMoratoriosPagados > 0 ? Colors.green.shade600 : null,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileTotalItem('Total Ideal', totalTotal),
                    _buildMobileTotalItem('Diferencia', restante),
                  ],
                ),
                const Divider(color: Colors.white30, height: 20),
                _buildMobileTotalItem('Total Bruto', nuevoTotalBruto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // === RESTO DE WIDGETS AUXILIARES (SIN CAMBIOS FUNCIONALES) ===============
  // =========================================================================

  Widget _buildMobileInfoRow(String label, String value, BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildMobileGrupoCard(
    BuildContext context,
    ReporteContableGrupo grupo,
    int index,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            (index + 1).toString(),
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          grupo.grupos,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Folio: ${grupo.folio} • ${grupo.tipopago}',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildMobileDetailSection(
                  context,
                  'Información del Crédito',
                  Icons.attach_money,
                  _buildMobileFinancialDetails(context, grupo),
                ),
                const SizedBox(height: 12),
                _buildMobileDetailSection(
                  context,
                  'Clientes (${grupo.clientes.length})',
                  Icons.people,
                  _buildMobileClientesList(context, grupo),
                ),
                const SizedBox(height: 12),
                _buildMobileDetailSection(
                  context,
                  'Depósitos',
                  Icons.account_balance_wallet,
                  _buildMobileDepositosList(context, grupo),
                ),
                // === AQUÍ SE AÑADE LA NUEVA SECCIÓN DE ANÁLISIS ===
                const SizedBox(height: 12),
                _buildMobileDetailSection(
                  context,
                  'Análisis de Recuperación',
                  Icons.insights,
                  _buildMobileAnalysisSection(context, grupo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildMobileFinancialDetails(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final periodoText = grupo.tipopago == "SEMANAL" ? "Semanal" : "Quincenal";
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileFinancialItem(
                    context,
                    'Garantía',
                    grupo.garantia,
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Solicitado',
                    widget.currencyFormat.format(grupo.montoSolicitado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Interés Total',
                    widget.currencyFormat.format(grupo.interesCredito),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Ficha',
                    widget.currencyFormat.format(grupo.montoficha),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileFinancialItem(
                    context,
                    'Tasa',
                    '${grupo.tazaInteres}%',
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Desembolsado',
                    widget.currencyFormat.format(grupo.montoDesembolsado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto a Recuperar',
                    widget.currencyFormat.format(grupo.montoARecuperar),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Capital $periodoText',
                widget.currencyFormat.format(grupo.capitalsemanal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Interés $periodoText',
                widget.currencyFormat.format(grupo.interessemanal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Moratorios Generados',
                widget.currencyFormat.format(grupo.moratorios.moratoriosAPagar),
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Moratorios Pagados',
                widget.currencyFormat.format(grupo.pagoficha.sumaMoratorio),
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFinancialItem(
    BuildContext context,
    String label,
    String value,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
    BuildContext context,
    String label,
    String value, {
    Color color = primaryColor,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileClientesList(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    double totalCapital = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoCapital,
    );
    double totalInteres = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoInteres,
    );
    double totalGeneral = totalCapital + totalInteres;

    return Column(
      children: [
        ...grupo.clientes.map(
          (cliente) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      widget.currencyFormat.format(cliente.capitalMasInteres),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cap: ${widget.currencyFormat.format(cliente.periodoCapital)} • Int: ${widget.currencyFormat.format(cliente.periodoInteres)}',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Totales del Grupo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              widget.currencyFormat.format(totalGeneral),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildMobileDepositosList(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final pagoficha = grupo.pagoficha;
    final colors = Provider.of<ThemeProvider>(context).colors;

    // LA LÓGICA DE ANÁLISIS QUE ESTABA AQUÍ FUE ELIMINADA

    if (pagoficha.depositos.isEmpty && pagoficha.favorUtilizado == 0) {
      return Center(
        child: Text(
          "Sin depósitos registrados.",
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileInfoRow(
          'Fecha Programada',
          _formatDateSafe(pagoficha.fechasPago),
          context,
        ),
        const SizedBox(height: 12),
        ...pagoficha.depositos
            .map((deposito) => _buildMobileCompactDepositRow(context, deposito))
            .toList(),
        if (pagoficha.saldofavor > 0)
          _buildSaldoFavorSummaryCard(context, pagoficha),
        if (pagoficha.favorUtilizado > 0)
          _buildMobileFavorUtilizadoCard(context, pagoficha.favorUtilizado),
        const Divider(height: 20),
        _buildMobileDetailRow(
          context,
          'Total Depósitos',
          widget.currencyFormat.format(pagoficha.sumaDeposito),
          valueColor: primaryColor,
        ),
        _buildMobileDetailRow(
          context,
          'Restante Ficha',
          widget.currencyFormat.format(grupo.restanteFicha),
          valueColor: Colors.orange.shade700,
        ),
        const Divider(height: 16),
        _buildMobileDetailRow(
          context,
          'Saldo Global Crédito',
          widget.currencyFormat.format(grupo.saldoGlobal),
        ),
        _buildMobileDetailRow(
          context,
          'Restante Global Crédito',
          widget.currencyFormat.format(grupo.restanteGlobal),
        ),
        // LA SECCIÓN DE ANÁLISIS QUE ESTABA AQUÍ AL FINAL FUE COMPLETAMENTE REMOVIDA
      ],
    );
  }

  // AÑADE ESTAS DOS NUEVAS FUNCIONES A TU ARCHIVO

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL CORREGIDA)

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL CORREGIDA)

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL CORREGIDA)

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL FINAL)

  // lib/screens/reporteContable.dart

// REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
Widget _buildMobileAnalysisSection(
  BuildContext context,
  ReporteContableGrupo grupo,
) {
  final colors = Provider.of<ThemeProvider>(context).colors;

  final double pagoTotalAplicado =
      grupo.pagoficha.sumaDeposito + grupo.pagoficha.favorUtilizado;

  final double depositosSinGarantia = grupo.pagoficha.depositos
      .where((d) => d.garantia != 'Si')
      .fold(0.0, (sum, d) => sum + d.deposito);
  final double pagoEfectivoPeriodo =
      depositosSinGarantia + grupo.pagoficha.favorUtilizado;

  final bool huboPagoConGarantia =
      (pagoTotalAplicado - pagoEfectivoPeriodo).abs() > 0.01;
  final bool esPagoSoloConGarantia =
      pagoEfectivoPeriodo < 0.01 && pagoTotalAplicado > 0;

  double capitalAplicadoTotal = 0;
  double interesAplicadoTotal = 0;

  if (pagoTotalAplicado > 0) {
    final saldoGlobalAnterior = grupo.saldoGlobal - pagoTotalAplicado;
    final num capitalPendienteAnterior = max(
      0,
      grupo.montoDesembolsado - saldoGlobalAnterior,
    );
    final num capitalPendienteActual = max(
      0,
      grupo.montoDesembolsado - grupo.saldoGlobal,
    );

    capitalAplicadoTotal =
        (capitalPendienteAnterior - capitalPendienteActual).toDouble();
    interesAplicadoTotal = pagoTotalAplicado - capitalAplicadoTotal;
  }

  final double capitalPagadoEfectivo = min(
    capitalAplicadoTotal,
    pagoEfectivoPeriodo,
  );
  final double interesPagadoEfectivo =
      pagoEfectivoPeriodo - capitalPagadoEfectivo;

  final double capitalPendienteReal =
      max(0, grupo.montoDesembolsado - grupo.saldoGlobal).toDouble();
  final double InteresSobreDesembolso =
      max(0, grupo.saldoGlobal - grupo.montoDesembolsado).toDouble();

  // === INICIO DEL CAMBIO: Se añade el cálculo que faltaba ===
  final double InteresSobreSolicitado =
      max(0, grupo.saldoGlobal - grupo.montoSolicitado).toDouble();
  // === FIN DEL CAMBIO ===


  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (pagoTotalAplicado > 0) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            'Aplicación del Pago del Período',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Abono a Capital',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              _buildMobileAnalysisValue(
                context,
                cashValue: capitalPagadoEfectivo,
                appliedValue: capitalAplicadoTotal,
                showAppliedValue:
                    huboPagoConGarantia,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Abono a Interés',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              _buildMobileAnalysisValue(
                context,
                cashValue: interesPagadoEfectivo,
                appliedValue: interesAplicadoTotal,
                showAppliedValue:
                    huboPagoConGarantia,
                valueColor:
                    interesPagadoEfectivo > 0 ? Colors.green.shade700 : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildMobileAnalysisNote(
          context,
          capitalAplicadoTotal,
          interesAplicadoTotal,
          pagoTotalAplicado,
          esPagoSoloConGarantia,
          huboPagoConGarantia,
        ),
        const Divider(height: 20),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          'Estado Global del Crédito',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 8),
      _buildMobileDetailRow(
        context,
        'Capital Desembolsado Pendiente',
        widget.currencyFormat.format(capitalPendienteReal),
      ),
      // === INICIO DEL CAMBIO: Se modifica este widget para mostrar ambos valores ===
      _buildMobileDetailRow(
        context,
        'Interés Acumulado (s/ Solicitado)', // Etiqueta principal
        widget.currencyFormat.format(InteresSobreSolicitado), // Valor principal
        valueColor: InteresSobreSolicitado > 0 ? Colors.green.shade700 : null,
        tooltipMessage: // Se añade el tooltip con la información secundaria
            'Sobre Desembolso: ${widget.currencyFormat.format(InteresSobreDesembolso)}',
      ),
      // === FIN DEL CAMBIO ===
    ],
  );
}

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL FINAL)

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN MÓVIL FINALÍSIMA)

  Widget _buildMobileAnalysisNote(
    BuildContext context,
    double capital,
    double interes,
    double pagoTotal,
    bool esSoloGarantia,
    bool huboPagoConGarantia,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    String message;
    IconData icon;
    Color iconColor;

    const double epsilon = 0.01;

    if (esSoloGarantia) {
      message =
          'El crédito se cubrió con garantía. No representa un ingreso en este período.';
      icon = Icons.security;
      iconColor = garantiaColor;
    } else if (huboPagoConGarantia) {
      // === NUEVA LÓGICA ANIDADA (MÓVIL) ===
      if (capital < epsilon) {
        message =
            'El depósito se aplicó a interés; el resto se cubrió con garantía.';
        icon = Icons.add_task;
        iconColor = Colors.green;
      } else {
        message =
            'El pago en efectivo fue aplicado y se complementó con la garantía para cubrir el monto total.';
        icon = Icons.add_task;
        iconColor = primaryColor;
      }
      // === FIN DE LA LÓGICA ANIDADA (MÓVIL) ===
    } else if (capital < epsilon && pagoTotal > 0) {
      message =
          'El capital del crédito ya fue cubierto. Este pago se aplica 100% a interés.';
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else if (interes < epsilon && pagoTotal > 0) {
      message = 'Este pago se aplica 100% a capital pendiente.';
      icon = Icons.arrow_downward;
      iconColor = primaryColor;
    } else {
      message =
          'Este pago se dividió para cubrir parte del capital y del interés.';
      icon = Icons.call_split;
      iconColor = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoFavorSummaryCard(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    String title;
    String primaryText;
    String? secondaryText;
    String tooltipMessage;

    if (pagoficha.utilizadoPago == 'Si') {
      title = 'Saldo a Favor Utilizado';
      primaryText = widget.currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Usado en otro pago)';
      tooltipMessage =
          'Un saldo a favor de ${widget.currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'Saldo a Favor Disponible';
      primaryText = widget.currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText =
          '(de ${widget.currencyFormat.format(pagoficha.saldofavor)} total)';
      tooltipMessage =
          'De un saldo total de ${widget.currencyFormat.format(pagoficha.saldofavor)}, se usaron ${widget.currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'Saldo a Favor Generado';
      primaryText = widget.currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Disponible)';
      tooltipMessage =
          'Se generó un saldo a favor de ${widget.currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: saldoFavorColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.blue.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (secondaryText != null)
                    Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              primaryText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                decoration:
                    (pagoficha.utilizadoPago == 'Si')
                        ? TextDecoration.lineThrough
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompactDepositRow(
    BuildContext context,
    Deposito deposito,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final isGarantia = deposito.garantia == "Si";
    final isSaldoGlobal = deposito.esSaldoGlobal == "Si";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isGarantia
                  ? garantiaColor
                  : isSaldoGlobal
                  ? abonoGlobalColor
                  : Colors.grey.withOpacity(0.2),
          width: (isGarantia || isSaldoGlobal) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currencyFormat.format(deposito.deposito),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (isGarantia || isSaldoGlobal)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        if (isGarantia)
                          _buildMobileDepositTag(
                            text: 'Garantía',
                            color: garantiaColor,
                            tooltipMessage: 'Pago con garantía',
                          ),
                        if (isSaldoGlobal)
                          _buildMobileDepositTag(
                            text: 'Abono Global',
                            color: abonoGlobalColor,
                            tooltipMessage:
                                'Es parte de un abono global de: ${widget.currencyFormat.format(deposito.saldoGlobal)}',
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Moratorio',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.currencyFormat.format(deposito.pagoMoratorio),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDepositTag({
    required String text,
    required Color color,
    String? tooltipMessage,
  }) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    if (tooltipMessage != null) {
      return Tooltip(
        message: tooltipMessage,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 300),
        child: tag,
      );
    }
    return tag;
  }

  Widget _buildMobileFavorUtilizadoCard(
    BuildContext context,
    double favorUtilizado,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: const Text(
              'Abono con Saldo a Favor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: _buildMobileDetailRow(
              context,
              "Monto utilizado:",
              widget.currencyFormat.format(favorUtilizado),
              valueColor: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  Widget _buildMobileDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    String? tooltipMessage,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
          // === INICIO DEL CAMBIO: Ícono condicional con Tooltip ===
          if (tooltipMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Tooltip(
                message: tooltipMessage,
                triggerMode: TooltipTriggerMode.longPress,
                waitDuration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          // === FIN DEL CAMBIO ===
        ],
      ),
    );
  }

  Widget _buildMobileTotalItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.currencyFormat.format(value),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDateSafe(String dateString) {
    try {
      if (dateString.isEmpty) return 'N/A';
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  Widget _buildDesktopSummaryItem(
    BuildContext context,
    String label,
    double value, {
    bool isPrimary = false,
    String? tooltipMessage,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Alinea verticalmente
      children: [
        // Contenido principal (barra, etiqueta, valor)
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color:
                isPrimary
                    ? primaryColor
                    : (isDarkMode ? Colors.grey[600] : Colors.grey[300]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              widget.currencyFormat.format(value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color:
                    isPrimary
                        ? primaryColor
                        : (isDarkMode ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),

        // === INICIO DEL CAMBIO: Ícono condicional con Tooltip ===
        if (tooltipMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Tooltip(
              message: tooltipMessage,
              waitDuration: const Duration(milliseconds: 0),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.grey[700]
                        : Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 12),
              child: MouseRegion(
                cursor: SystemMouseCursors.help,
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        // === FIN DEL CAMBIO ===
      ],
    );
  }

  Widget _buildDesktopSaldoFavorTotalItem(
    BuildContext context,
    double totalSaldoDisponible,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final double totalSaldoFavorHistorico = widget.reporteData.totalSaldoFavor;
    return Row(
      children: [
        _buildDesktopSummaryItem(
          context,
          'S. Favor Disp.',
          totalSaldoDisponible,
        ),
        const SizedBox(width: 6),
        Tooltip(
          message:
              'Total generado históricamente: ${widget.currencyFormat.format(totalSaldoFavorHistorico)}',
          decoration: BoxDecoration(
            color: saldoFavorColor,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          waitDuration: const Duration(milliseconds: 300),
          child: MouseRegion(
            cursor: SystemMouseCursors.help,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildDesktopGrupoCard(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        grupo.grupos,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Folio: ${grupo.folio})',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildDesktopInfoText(context, 'Pago: ${grupo.tipopago}'),
                    _buildDesktopInfoText(context, 'Plazo: ${grupo.plazo}'),
                    _buildDesktopInfoText(
                      context,
                      'Periodo Pago: ${grupo.pagoPeriodo}',
                    ),
                  ],
                ),
              ],
            ),
            Divider(
              height: 16,
              thickness: 0.5,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLUMNA 1: CLIENTES
                Expanded(child: _buildDesktopClientesSection(grupo, context)),
                const SizedBox(width: 20),
                // COLUMNA 2: INFORMACIÓN FINANCIERA
                SizedBox(
                  width: 270,
                  child: _buildDesktopFinancialColumn(context, grupo),
                ),
                const SizedBox(width: 20),
                // COLUMNA 3: DEPÓSITOS
                SizedBox(
                  width: 270,
                  child: _buildDesktopDepositosSection(
                    context,
                    grupo.pagoficha,
                    grupo.restanteFicha,
                    grupo,
                  ),
                ),
                const SizedBox(width: 20),
                // === NUEVA COLUMNA 4: ANÁLISIS DE RECUPERACIÓN ===
                SizedBox(
                  width: 270,
                  child: _buildCapitalRecoverySection(context, grupo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildDesktopClientesSection(
    ReporteContableGrupo grupo,
    BuildContext context,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    double totalCapital = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoCapital,
    );
    double totalInteres = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.periodoInteres,
    );
    double totalGeneral = grupo.clientes.fold(
      0,
      (sum, item) => sum + item.capitalMasInteres,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, size: 14, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              'Clientes (${grupo.clientes.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            // === CAMBIO 1: SE REDUJO EL FlexColumnWidth DE 4 A 3 ===
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[300]!),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Nombre Cliente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Capital',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Interés',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Capital + Interés',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              ...grupo.clientes.map(
                (cliente) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        cliente.nombreCompleto,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        // === CAMBIO 2: SE AÑADIERON ESTAS DOS LÍNEAS ===
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        widget.currencyFormat.format(cliente.periodoCapital),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        widget.currencyFormat.format(cliente.periodoInteres),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        widget.currencyFormat.format(cliente.capitalMasInteres),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TableRow(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(81, 98, 246, 0.1),
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Totales',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      widget.currencyFormat.format(totalCapital),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      widget.currencyFormat.format(totalInteres),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      widget.currencyFormat.format(totalGeneral),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFinancialColumn(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.attach_money, size: 14, color: primaryColor),
            SizedBox(width: 6),
            Text(
              'Información del Crédito',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoText(
                      context,
                      'Garantía',
                      grupo.garantia,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Tasa',
                      grupo.tazaInteres,
                      isPercentage: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto Solicitado',
                      grupo.montoSolicitado,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto Desembolsado',
                      grupo.montoDesembolsado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Interés Total',
                      grupo.interesCredito,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Monto a Recuperar',
                      grupo.montoARecuperar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                '${grupo.tipopago == "SEMANAL" ? "Capital Semanal" : "Capital Quincenal"}',
                grupo.capitalsemanal,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                '${grupo.tipopago == "SEMANAL" ? "Interés Semanal" : "Interés Quincenal"}',
                grupo.interessemanal,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Monto Ficha',
                grupo.montoficha,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Moratorios Generados',
                grupo.moratorios.moratoriosAPagar,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildDesktopFinancialInfo(
                context,
                'Moratorios Pagados',
                grupo.pagoficha.sumaMoratorio,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFinancialInfoCompact(
    BuildContext context,
    String label,
    double value, {
    bool isPercentage = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          '${widget.currencyFormat.format(value)}${isPercentage ? '%' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopFinancialInfoText(
    BuildContext context,
    String label,
    String value,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopInfoText(BuildContext context, String text) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: isDarkMode ? Colors.grey[300] : Colors.grey[900],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDesktopFinancialInfo(
    BuildContext context,
    String label,
    double value,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            widget.currencyFormat.format(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN COMPLETA

  Widget _buildDesktopDepositosSection(
    BuildContext context,
    Pagoficha pagoficha,
    double restanteFicha,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, size: 14, color: primaryColor),
                SizedBox(width: 6),
                Text(
                  'Depósitos',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            Text(
              'Fecha programada: ${_formatDateSafe(pagoficha.fechasPago)}',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 140),
          child:
              pagoficha.depositos.isEmpty && pagoficha.favorUtilizado == 0
                  ? Center(
                    child: Text(
                      'Sin depósitos registrados',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView(
                    shrinkWrap: true,
                    children: [
                      ...pagoficha.depositos
                          .map(
                            (deposito) => _buildDesktopStandardDepositCard(
                              context,
                              deposito,
                              pagoficha,
                            ),
                          )
                          .toList(),
                      if (pagoficha.favorUtilizado > 0)
                        _buildDesktopFavorUtilizadoCard(
                          context,
                          pagoficha.favorUtilizado,
                          pagoficha.fechasPago,
                        ),
                    ],
                  ),
        ),
        if (pagoficha.saldofavor > 0)
          _buildDesktopSaldoFavorSummaryRow(context, pagoficha),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(top: 6, bottom: 8),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? const Color(0xFF000000).withOpacity(0.3)
                    : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total depósitos:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
              Text(
                widget.currencyFormat.format(pagoficha.sumaDeposito),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.orange[900]!.withOpacity(0.2)
                    : Colors.orange[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.orange[800]! : Colors.orange[200]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restante ficha:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.orange[300] : Colors.orange[900],
                ),
              ),
              Text(
                widget.currencyFormat.format(restanteFicha),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.orange[300] : Colors.orange[900],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen Global',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Saldo Global',
                      grupo.saldoGlobal,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildDesktopFinancialInfoCompact(
                      context,
                      'Restante Global',
                      grupo.restanteGlobal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === NUEVO WIDGET AUXILIAR: para mostrar el detalle del abono ===
  // === NUEVO WIDGET AUXILIAR: para mostrar el detalle del abono ===
  Widget _buildDesktopAnalysisItem(
    BuildContext context, {
    required String label,
    required double cashValue,
    required double appliedValue,
    required bool
    showAppliedValue, // <--- CAMBIO: Renombrado para mayor claridad
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            widget.currencyFormat.format(cashValue),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          // Se activa si la nueva condición es verdadera
          if (showAppliedValue && appliedValue > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                // <--- CAMBIO: Se usa "Cubierto"
                '(Cubierto: ${widget.currencyFormat.format(appliedValue)})',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // REEMPLAZA ESTA FUNCIÓN TAMBIÉN (VERSIÓN DESKTOP CORREGIDA)

  // REEMPLAZA ESTA FUNCIÓN TAMBIÉN (VERSIÓN DESKTOP FINAL)

  // lib/screens/reporteContable.dart

  // REEMPLAZA ESTA FUNCIÓN COMPLETA EN TU ARCHIVO
  Widget _buildCapitalRecoverySection(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final double capitalPendienteReal =
        max(0, grupo.montoDesembolsado - grupo.saldoGlobal).toDouble();
    final double InteresSobreDesembolso =
        max(0, grupo.saldoGlobal - grupo.montoDesembolsado).toDouble();

    final double InteresSobreSolicitado =
        max(0, grupo.saldoGlobal - grupo.montoSolicitado).toDouble();

    final double pagoTotalAplicado =
        grupo.pagoficha.sumaDeposito + grupo.pagoficha.favorUtilizado;

    final double depositosSinGarantia = grupo.pagoficha.depositos
        .where((d) => d.garantia != 'Si')
        .fold(0.0, (sum, d) => sum + d.deposito);
    final double pagoEfectivoPeriodo =
        depositosSinGarantia + grupo.pagoficha.favorUtilizado;

    final bool huboPagoConGarantia =
        (pagoTotalAplicado - pagoEfectivoPeriodo).abs() > 0.01;
    final bool esPagoSoloConGarantia =
        pagoEfectivoPeriodo < 0.01 && pagoTotalAplicado > 0;

    double capitalAplicadoTotal = 0;
    double interesAplicadoTotal = 0;

    if (pagoTotalAplicado > 0) {
      final saldoGlobalAnterior = grupo.saldoGlobal - pagoTotalAplicado;
      final num capitalPendienteAnterior = max(
        0,
        grupo.montoDesembolsado - saldoGlobalAnterior,
      );

      capitalAplicadoTotal =
          (capitalPendienteAnterior - capitalPendienteReal).toDouble();
      interesAplicadoTotal = pagoTotalAplicado - capitalAplicadoTotal;
    }

    final double capitalPagadoEfectivo = min(
      capitalAplicadoTotal,
      pagoEfectivoPeriodo,
    );
    final double interesPagadoEfectivo =
        pagoEfectivoPeriodo - capitalPagadoEfectivo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color:
              isDarkMode
                  ? analysisColor.withOpacity(0.6)
                  : analysisColor.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 14, color: analysisColor),
              const SizedBox(width: 6),
              Text(
                'Análisis de Recuperación',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: analysisColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Cálculo: Monto Desembolsado - Saldo Global Pagado',
                  child: _buildDesktopFinancialInfoCompact(
                    context,
                    'Capital Desembolsado Pendiente',
                    capitalPendienteReal,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // === INICIO DEL CAMBIO ===
              Expanded(
                child: Tooltip(
                  message:
                      'Interés acumulado sobre el monto solicitado y el monto desembolsado.',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interés Acumulado (s/ Solicitado)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.currencyFormat.format(InteresSobreSolicitado),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                           '(s. desembolso:\n${widget.currencyFormat.format(InteresSobreDesembolso)})',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // === FIN DEL CAMBIO ===
            ],
          ),
          if (pagoTotalAplicado > 0) ...[
            const SizedBox(height: 8),
            Divider(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              height: 1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Aplicación del Pago de este Período',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDesktopAnalysisItem(
                    context,
                    label: 'Abono a Capital',
                    cashValue: capitalPagadoEfectivo,
                    appliedValue: capitalAplicadoTotal,
                    showAppliedValue:
                        huboPagoConGarantia,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildDesktopAnalysisItem(
                    context,
                    label: 'Abono a Interés',
                    cashValue: interesPagadoEfectivo,
                    appliedValue: interesAplicadoTotal,
                    showAppliedValue:
                        huboPagoConGarantia,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAnalysisNote(
              context,
              capitalAplicadoTotal,
              interesAplicadoTotal,
              pagoTotalAplicado,
              esPagoSoloConGarantia,
              huboPagoConGarantia,
            ),
          ],
        ],
      ),
    );
  }

  // === NUEVO WIDGET AUXILIAR MÓVIL: para el detalle del abono ===
  // === NUEVO WIDGET AUXILIAR MÓVIL: para el detalle del abono ===
  Widget _buildMobileAnalysisValue(
    BuildContext context, {
    required double cashValue,
    required double appliedValue,
    required bool showAppliedValue, // <--- CAMBIO: Renombrado
    Color? valueColor,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    // Si no hay valor aplicado para mostrar, solo renderiza una línea
    if (!showAppliedValue || appliedValue <= 0) {
      return Text(
        widget.currencyFormat.format(cashValue),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: valueColor ?? colors.textPrimary,
        ),
      );
    }

    // Si hay que mostrar ambos, renderiza las dos líneas
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.currencyFormat.format(cashValue),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
        Text(
          // <--- CAMBIO: Se usa "Cubierto"
          '(Cubierto: ${widget.currencyFormat.format(appliedValue)})',
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }

  // === NUEVO WIDGET AUXILIAR: para la nota explicativa ===
  // Coloca esta función justo debajo de la anterior
  // Coloca esta función justo debajo de la anterior
  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN DESKTOP FINAL)

  // REEMPLAZA ESTA FUNCIÓN COMPLETA (VERSIÓN DESKTOP FINALÍSIMA)

  Widget _buildAnalysisNote(
    BuildContext context,
    double capital,
    double interes,
    double pagoTotal,
    bool esSoloGarantia,
    bool huboPagoConGarantia,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    String message;
    IconData icon;
    Color iconColor;

    const double epsilon = 0.01;

    if (esSoloGarantia) {
      message =
          'El crédito se cubrió con garantía. No representa un ingreso en este período.';
      icon = Icons.security;
      iconColor = garantiaColor;
    } else if (huboPagoConGarantia) {
      // === NUEVA LÓGICA ANIDADA: Distinguir el caso de pago mixto ===
      if (capital < epsilon) {
        // Este es el caso de tu imagen: pago mixto que va solo a interés.
        message =
            'El depósito se aplicó a interés; el resto se cubrió con garantía.';
        icon = Icons.add_task;
        iconColor =
            Colors.green; // Verde porque el objetivo (interés) se está pagando.
      } else {
        // Caso genérico de pago mixto que cubre capital e interés.
        message =
            'El pago en efectivo fue aplicado y se complementó con la garantía para cubrir el monto total.';
        icon = Icons.add_task;
        iconColor = primaryColor;
      }
      // === FIN DE LA LÓGICA ANIDADA ===
    } else if (capital < epsilon && pagoTotal > 0) {
      message =
          'El capital del crédito ya fue cubierto. Este pago se aplica 100% a interés.';
      icon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (interes < epsilon && pagoTotal > 0) {
      message = 'Este pago se aplica 100% a capital pendiente.';
      icon = Icons.arrow_downward;
      iconColor = primaryColor;
    } else {
      message =
          'Este pago se dividió para cubrir parte del capital y del interés.';
      icon = Icons.call_split;
      iconColor = Colors.orange.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSaldoFavorSummaryRow(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    String title;
    String primaryText;
    String? secondaryText;
    String tooltipMessage;

    if (pagoficha.utilizadoPago == 'Si') {
      title = 'S. Favor (Utilizado)';
      primaryText = widget.currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'Usado en otro pago.';
      tooltipMessage =
          'Un saldo a favor de ${widget.currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'S. Favor Disponible';
      primaryText = widget.currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText =
          'de ${widget.currencyFormat.format(pagoficha.saldofavor)} total';
      tooltipMessage =
          'De un saldo total de ${widget.currencyFormat.format(pagoficha.saldofavor)}, se usaron ${widget.currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'S. Favor Generado';
      primaryText = widget.currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'disponible';
      tooltipMessage =
          'Se generó un saldo a favor de ${widget.currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: saldoFavorColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.green[900]!.withOpacity(0.3)
                  : Colors.green[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDarkMode ? Colors.green[800]! : Colors.green[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 14,
              color: isDarkMode ? Colors.green[300] : Colors.green[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.green[200] : Colors.green[800],
                    ),
                  ),
                  if (secondaryText != null)
                    Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              primaryText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.green[200] : Colors.green[900],
                decoration:
                    (pagoficha.utilizadoPago == 'Si')
                        ? TextDecoration.lineThrough
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopFavorUtilizadoCard(
    BuildContext context,
    double favorUtilizado,
    String fechaOriginal,
  ) {
    return Tooltip(
      message:
          'Este abono se realizó utilizando un saldo a favor de un pago anterior.',
      decoration: BoxDecoration(
        color: saldoFavorColor,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.shade600),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: const Align(
                alignment: Alignment.center,
                child: Text(
                  'Abono con Saldo a Favor',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monto utilizado:',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? const Color(0xFFC0E3C1)
                              : Colors.green.shade800,
                    ),
                  ),
                  Text(
                    widget.currencyFormat.format(favorUtilizado),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? const Color(0xFFC0E3C1)
                              : Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStandardDepositCard(
    BuildContext context,
    Deposito deposito,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isSaldoGlobal = deposito.esSaldoGlobal == "Si";

    Widget labelWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isSaldoGlobal ? abonoGlobalColor : const Color(0xFFE53888),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isSaldoGlobal ? 'Abono Global' : 'Garantía',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );

    if (isSaldoGlobal) {
      labelWidget = Tooltip(
        message:
            'Es parte de un abono global de: ${widget.currencyFormat.format(deposito.saldoGlobal)}',
        decoration: BoxDecoration(
          color: abonoGlobalColor,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 300),
        child: labelWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5162F6).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Fecha depósito: ${_formatDateSafe(deposito.fechaDeposito)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.grey[200] : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDesktopDepositoDetail(
                      context,
                      'Depósito',
                      deposito.deposito,
                      Icons.arrow_downward,
                      depositoCompleto: pagoficha.depositoCompleto,
                    ),
                    _buildDesktopDepositoDetail(
                      context,
                      'Moratorio',
                      deposito.pagoMoratorio,
                      Icons.warning,
                    ),
                  ],
                ),
                if (deposito.garantia == "Si" || isSaldoGlobal)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: labelWidget,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDepositoDetail(
    BuildContext context,
    String label,
    double value,
    IconData icon, {
    double? depositoCompleto,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    bool shouldShowIcon = false;
    if (label == 'Depósito' &&
        depositoCompleto != null &&
        depositoCompleto > 0) {
      const double epsilon = 0.01;
      shouldShowIcon = (value - depositoCompleto).abs() > epsilon;
    }

    Widget detailWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.currencyFormat.format(value),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
                color: isDarkMode ? Colors.grey[200] : Colors.black87,
              ),
            ),
            if (shouldShowIcon)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: isDarkMode ? Colors.white54 : Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );

    if (shouldShowIcon) {
      return Tooltip(
        message:
            'Depósito completo: ${widget.currencyFormat.format(depositoCompleto!)}',
        decoration: BoxDecoration(
          color: const Color(0xFFE53888),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 300),
        child: MouseRegion(
          cursor: SystemMouseCursors.help,
          child: detailWidget,
        ),
      );
    }
    return detailWidget;
  }
}
