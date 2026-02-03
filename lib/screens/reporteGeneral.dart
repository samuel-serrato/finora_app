// reporte_general_widget.dart

import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reporte_general.dart';

class ReporteGeneralWidget extends StatelessWidget {
  final List<ReporteGeneral> listaReportes;
  final ReporteGeneralData? reporteData;
  final NumberFormat currencyFormat;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final double headerTextSize;
  final double cellTextSize;

  const ReporteGeneralWidget({
    super.key,
    required this.listaReportes,
    required this.reporteData,
    required this.currencyFormat,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    this.headerTextSize = 12.0,
    this.cellTextSize = 11.0,
  });

  static const Color primaryColor = Color(0xFF5162F6);

  @override
  Widget build(BuildContext context) {
    // El método build ahora es muy simple: decide qué layout mostrar.
    return context.isMobile
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  //============================================================================
  // === LAYOUT Y WIDGETS PARA ESCRITORIO (SIN CAMBIOS) =========================
  //============================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
 final double totalMoratoriosPagados = listaReportes.fold(0.0, (sum, r) => sum + r.sumaMoratorio);
    
    // NUEVO CÁLCULO SOLICITADO
    final double nuevoTotalBruto = (reporteData?.totalPagoficha ?? 0.0) + 
                                   (reporteData?.totalSaldoDisponible ?? 0.0) + 
                                   totalMoratoriosPagados;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (reporteData != null) _buildDesktopHeader(context),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child:
                    listaReportes.isEmpty
                        ? Center(child: Text('No hay datos para mostrar'))
                        : Column(
                          children: [
                            _buildDataTableHeader(context),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: verticalScrollController,
                                child: _buildDataTableBody(context),
                              ),
                            ),
                            if (reporteData != null)
                              Column(
                                children: [
                                  _buildTotalsWidget(),
                                  _buildTotalsIdealWidget(nuevoTotalBruto),
                                ],
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

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.bar_chart_rounded, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Período: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    reporteData!.fechaSemana,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generado: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    reporteData!.fechaActual,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
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

  // ... (Aquí van todos los demás helpers de la tabla de escritorio que ya estaban correctos)
  // ... _buildDataTableHeader, _buildHeaderCell, _buildDataTableBody, etc.
  // ... LOS PEGO AL FINAL PARA QUE EL CÓDIGO SEA COMPLETO Y COMPILABLE.

  //============================================================================
  // === LAYOUT Y WIDGETS PARA MÓVIL (CORREGIDO Y MEJORADO) =====================
  //============================================================================

  Widget _buildMobileLayout(BuildContext context) {
    // El ListView será el elemento principal de scroll en la vista móvil.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (reporteData != null) _buildMobileHeader(context),
        const SizedBox(height: 16),
        _buildQuickSummary(context),
        const SizedBox(height: 16),
        if (listaReportes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48.0),
            child: Center(child: Text('No hay datos para mostrar')),
          )
        else
          // Usamos un Column para las tarjetas, ya que el ListView padre ya se encarga del scroll.
          Column(
            children:
                listaReportes
                    .asMap()
                    .entries
                    .map(
                      (entry) => _buildMobileReportCard(
                        context,
                        entry.key,
                        entry.value,
                      ),
                    )
                    .toList(),
          ),
        // === CAMBIO: Ahora el resumen de totales es mucho más completo ===
        if (reporteData != null) _buildMobileTotalsSummary(context),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Reporte General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMobileInfoRow('Período', reporteData!.fechaSemana, context),
          const SizedBox(height: 4),
          _buildMobileInfoRow('Generado', reporteData!.fechaActual, context),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value, BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Provider.of<ThemeProvider>(context).colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSummary(BuildContext context) {
    final totalReportes = listaReportes.length;
    final reportesCompletos =
        listaReportes
            .where(
              (r) =>
                  r.pagoficha >= r.montoficha &&
                  (r.moratoriosAPagar - r.sumaMoratorio) <= 0,
            )
            .length;
    final reportesPendientes =
        listaReportes.where((r) => r.pagoficha == 0.0).length;
    final reportesIncompletos =
        totalReportes - reportesCompletos - reportesPendientes;
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Estados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                totalReportes.toString(),
                primaryColor,
              ),
              _buildSummaryItem(
                'Completos',
                reportesCompletos.toString(),
                Colors.green,
              ),
              _buildSummaryItem(
                'Incompletos',
                reportesIncompletos.toString(),
                Colors.orange,
              ),
              _buildSummaryItem(
                'Pendientes',
                reportesPendientes.toString(),
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMobileReportCard(
    BuildContext context,
    int index,
    ReporteGeneral reporte,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final bool pagoNoRealizado = reporte.pagoficha == 0.0;
    // DESPUÉS (CORREGIDO):
    // La ficha se considera cubierta si el restante es 0 o menos.
    final bool esCompleto =
        reporte.restanteFicha <= 0 &&
        (reporte.moratoriosAPagar - reporte.sumaMoratorio) <= 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (pagoNoRealizado) {
      statusColor = Colors.red;
      statusText = 'Pendiente';
      statusIcon = Icons.cancel;
    } else if (!esCompleto) {
      statusColor = Colors.orange;
      statusText = 'Incompleto';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Completo';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (index + 1).toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${reporte.tipoPago} - ${reporte.grupos}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(reporte.pagoficha),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        children: [_buildMobileDetailedInfo(context, reporte)],
      ),
    );
  }

  Widget _buildMobileDetailedInfo(
    BuildContext context,
    ReporteGeneral reporte,
  ) {
    final String fechaPrincipal =
        reporte.depositos.isNotEmpty ? reporte.depositos.first.fecha : 'N/A';
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Column(
      children: [
        _buildMobileDetailSection('Información Principal', [
          _buildMobileDetailRow('Fecha Pago', fechaPrincipal, context),
          _buildMobileDetailRow(
            'Monto Ficha',
            currencyFormat.format(reporte.montoficha),
            context,
          ),
          _buildMobileDetailRow(
            'Total Pagos',
            currencyFormat.format(reporte.pagoficha),
            context,
          ),
          _buildMobileDetailRow(
            'Saldo Contra',
            _buildSaldoContraText(reporte),
            context,
            valueColor: _getSaldoContraColor(reporte, context),
          ),
        ], context),
        const SizedBox(height: 16),
        _buildMobileDetailSection('Composición del Préstamo', [
          _buildMobileDetailRow(
            'Capital',
            currencyFormat.format(reporte.capitalsemanal),
            context,
          ),
          _buildMobileDetailRow(
            'Interés',
            currencyFormat.format(reporte.interessemanal),
            context,
          ),
          // === CAMBIO 2: Lógica de Saldo a Favor mejorada ===
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Saldo Favor",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                _buildMobileSaldoFavorDisplay(context, reporte),
              ],
            ),
          ),
        ], context),
        const SizedBox(height: 16),
        _buildMobileDetailSection('Moratorios', [
          _buildMobileDetailRow(
            'Generados',
            currencyFormat.format(reporte.moratoriosAPagar),
            context,
            valueColor: reporte.moratoriosAPagar > 0 ? Colors.red : null,
          ),
          _buildMobileDetailRow(
            'Pagados',
            currencyFormat.format(reporte.sumaMoratorio),
            context,
            valueColor: reporte.sumaMoratorio > 0 ? Colors.green : null,
          ),
        ], context),
        // === CAMBIO 1: Desglose de pagos más completo ===
        if (reporte.depositos.isNotEmpty || reporte.favorUtilizado > 0) ...[
          const SizedBox(height: 16),
          _buildMobilePaymentsSection(context, reporte),
        ],
      ],
    );
  }

  // === NUEVO WIDGET: Replicar la lógica de escritorio para el Saldo a Favor ===
  Widget _buildMobileSaldoFavorDisplay(
    BuildContext context,
    ReporteGeneral reporte,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    // Si no se generó saldo a favor.
    if (reporte.saldofavor == 0) {
      return Text(
        currencyFormat.format(0.0),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      );
    }

    // Caso 1: Se generó y se utilizó por completo en este mismo pago.
    if (reporte.utilizadoPago == 'Si') {
      return Tooltip(
        message:
            'Saldo de ${currencyFormat.format(reporte.saldofavor)} generado y utilizado completamente en este pago.',
        child: Text(
          currencyFormat.format(reporte.saldofavor),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary.withOpacity(0.7),
            decoration: TextDecoration.lineThrough, // Tachado
          ),
        ),
      );
    }

    // Caso 2: Se generó y se utilizó una parte.
    if (reporte.saldoUtilizado > 0) {
      return Tooltip(
        message:
            'De un saldo total de ${currencyFormat.format(reporte.saldofavor)}, se utilizaron ${currencyFormat.format(reporte.saldoUtilizado)}.',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(reporte.saldoDisponible),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(de ${currencyFormat.format(reporte.saldofavor)})',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Caso 3 (Default): Se generó y no se usó nada.
    return Text(
      currencyFormat.format(reporte.saldofavor),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildMobileDetailSection(
    String title,
    List<Widget> children,
    BuildContext context,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
        border:
            Provider.of<ThemeProvider>(context).isDarkMode
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMobileDetailRow(
    String label,
    String value,
    BuildContext context, {
    Color? valueColor,
  }) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // === CAMBIO 1 (Continuación): Mejorado para mostrar todos los tipos de pago ===
   // --- CAMBIO EN VISTA MÓVIL (dentro de _buildMobilePaymentsSection) ---
  Widget _buildMobilePaymentsSection(
    BuildContext context,
    ReporteGeneral reporte,
  ) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagos Realizados',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          // Pagos en efectivo / depósitos
          ...reporte.depositos.map((deposito) {
            // --- NUEVA LÓGICA PARA IDENTIFICAR TIPO DE PAGO ---
            bool isGarantia = deposito.garantia == "Si";
            bool isSaldoGlobal = deposito.esSaldoGlobal == "Si";
            Color? chipColor;
            Widget? subLabel;

            if (isGarantia) {
              chipColor = const Color(0xFFE53888);
              subLabel = const Text(
                'Con garantía',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFE53888),
                  fontWeight: FontWeight.w500,
                ),
              );
            } else if (isSaldoGlobal) {
              chipColor = Colors.teal;
              subLabel = Tooltip( // En móvil el tooltip se activa con pulsación larga
                message:
                    'Es parte de un abono global de: ${currencyFormat.format(deposito.saldoGlobal)}',
                child: Text(
                  'Abono global',
                  style: TextStyle(
                    fontSize: 10,
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            // --- FIN DE NUEVA LÓGICA ---

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    chipColor != null
                        ? Border.all(color: chipColor, width: 1)
                        : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposito.fecha,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (subLabel != null) subLabel, // Muestra el sub-label si existe
                    ],
                  ),
                  Text(
                    currencyFormat.format(deposito.monto),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: chipColor ?? colors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          // Pago con Saldo a Favor (sin cambios)
          if (reporte.favorUtilizado > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Con saldo a favor',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(reporte.favorUtilizado),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- MÉTODO MODIFICADO (MÓVIL) ---
  String _buildSaldoContraText(ReporteGeneral reporte) {
    // Ya no se calcula, se usa el valor del API
    final double saldoContra = reporte.restanteFicha;
    return saldoContra > 0
        ? currencyFormat.format(saldoContra)
        : currencyFormat.format(0.0);
  }

  // --- MÉTODO MODIFICADO (MÓVIL) ---
  Color? _getSaldoContraColor(ReporteGeneral reporte, BuildContext context) {
    // La condición ahora usa el nuevo campo
    if (reporte.restanteFicha > 0) {
      return Provider.of<ThemeProvider>(context, listen: false).isDarkMode
          ? Colors.red[300]
          : Colors.red[700];
    }
    return null;
  }
  

  // === CAMBIO 3: Resumen de totales completamente rediseñado ===
   // --- MÉTODO MODIFICADO (TOTALES MÓVIL) ---
  Widget _buildMobileTotalsSummary(BuildContext context) {
    // === CAMBIO: Usamos fold para sumar el nuevo campo restanteFicha ===
    double totalSaldoContra =
        listaReportes.fold(0.0, (sum, r) => sum + r.restanteFicha);

    final double totalMoratoriosGenerados = listaReportes.fold(
      0.0,
      (sum, r) => sum + r.moratoriosAPagar,
    );
    final double totalMoratoriosPagados = listaReportes.fold(
      0.0,
      (sum, r) => sum + r.sumaMoratorio,
    );

    final double nuevoTotalBruto = (reporteData?.totalPagoficha ?? 0.0) + 
                               (reporteData?.totalSaldoDisponible ?? 0.0) + 
                               totalMoratoriosPagados;


    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Sección de Totales Ideales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Resumen Financiero',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMobileTotalItem(
                      context,
                      'Total Ideal',
                      reporteData!.totalTotal,
                      isPrimary: true,
                    ),
                    _buildMobileTotalItem(
                      context,
                      'Diferencia',
                      reporteData!.restante,
                      isPrimary: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMobileTotalItem(
                  context,
                  'Total Bruto',
                  nuevoTotalBruto, // <--- USAMOS EL NUEVO CÁLCULO
                  isPrimary: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Totales por Concepto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          // Sección de Totales por Columna
          _buildMobileDetailRow(
            'Pagos Ficha',
            currencyFormat.format(reporteData!.totalPagoficha),
            context,
          ),
          _buildMobileDetailRow(
            'Monto Ficha',
            currencyFormat.format(reporteData!.totalFicha),
            context,
          ),
          _buildMobileDetailRow(
            'Saldo Contra',
            currencyFormat.format(totalSaldoContra),
            context,
            valueColor: totalSaldoContra > 0 ? Colors.red : null,
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildMobileDetailRow(
            'Capital',
            currencyFormat.format(reporteData!.totalCapital),
            context,
          ),
          _buildMobileDetailRow(
            'Interés',
            currencyFormat.format(reporteData!.totalInteres),
            context,
          ),
          _buildMobileDetailRow(
            'Saldo Favor Disp.',
            currencyFormat.format(reporteData!.totalSaldoDisponible),
            context,
          ),
          const Divider(height: 20, thickness: 0.5),
          _buildMobileDetailRow(
            'Moratorios Gen.',
            currencyFormat.format(totalMoratoriosGenerados),
            context,
            valueColor: totalMoratoriosGenerados > 0 ? Colors.red : null,
          ),
          _buildMobileDetailRow(
            'Moratorios Pag.',
            currencyFormat.format(totalMoratoriosPagados),
            context,
            valueColor: totalMoratoriosPagados > 0 ? Colors.green : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTotalItem(
    context,
    String label,
    double value, {
    bool isPrimary = false,
  }) {
    final Color labelColor =
        isPrimary
            ? Colors.white70
            : Provider.of<ThemeProvider>(context).colors.textSecondary;
    final Color valueColor =
        isPrimary
            ? Colors.white
            : Provider.of<ThemeProvider>(context).colors.textPrimary;
    final double fontSize = isPrimary ? 14 : 12;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  //============================================================================
  // === CÓDIGO DE DESKTOP PEGADO PARA INTEGRIDAD ===============================
  //============================================================================

  Widget _buildDataTableHeader(BuildContext context) {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _buildHeaderCell('#', context),
          _buildHeaderCell('Tipo', context),
          _buildHeaderCell('Grupos', context),
          _buildHeaderCell('Pagos', context),
          _buildHeaderCell('Fecha', context),
          _buildHeaderCell('Monto Ficha', context),
          _buildHeaderCell('Saldo Contra', context),
          _buildHeaderCell('Capital', context),
          _buildHeaderCell('Interés', context),
          _buildHeaderCell('Saldo Favor', context),
          _buildHeaderCell('Moratorios\nGenerados', context),
          _buildHeaderCell('Moratorios\nPagados', context),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: headerTextSize,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDataTableBody(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children:
          listaReportes.asMap().entries.map((entry) {
            final index = entry.key;
            final reporte = entry.value;

            final totalPagos = reporte.pagoficha;
            final montoFicha = reporte.montoficha;
            final moratoriosGenerados = reporte.moratoriosAPagar;
            final moratoriosPagados = reporte.sumaMoratorio;
            final moratoriosPendientes =
                moratoriosGenerados - moratoriosPagados;

            final bool pagoNoRealizado = reporte.pagoficha == 0.0; // Se usa pagoficha aquí, es correcto.

             // DESPUÉS (CORREGIDO):
            // La ficha está cubierta si el API nos dice que el restante es 0 o menos.
            final bool fichaCubierta = reporte.restanteFicha <= 0;
            final bool moratoriosCubiertos = moratoriosPendientes <= 0;
            final bool esCompleto = fichaCubierta && moratoriosCubiertos;
            final bool esIncompleto = !pagoNoRealizado && !esCompleto;

            return Container(
              color:
                  isDarkMode
                      ? (index.isEven
                          ? const Color(0xFF2A3040)
                          : const Color(0xFF1E1E1E))
                      : (index.isEven
                          ? const Color.fromARGB(255, 216, 228, 245)
                          : Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  _buildBodyCell(
                    _buildIndexCircle(
                      index,
                      pagoNoRealizado,
                      esIncompleto,
                      !fichaCubierta,
                      !moratoriosCubiertos,
                      context,
                    ),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    reporte.tipoPago,
                    context: context,
                    alignment: Alignment.center,
                  ),
                  _buildBodyCell(
                    reporte.grupos,
                    context: context,
                    alignment: Alignment.center,
                  ),
                  _buildBodyCell(
                    _buildPagosColumn(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    _buildFechasColumn(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    currencyFormat.format(reporte.montoficha),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    _buildSaldoContra(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    currencyFormat.format(reporte.capitalsemanal),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    currencyFormat.format(reporte.interessemanal),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    _buildSaldoFavor(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    _buildMoratoriosGenerados(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                  _buildBodyCell(
                    _buildMoratoriosPagados(reporte, context),
                    alignment: Alignment.center,
                    context: context,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFechasColumn(ReporteGeneral reporte, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (reporte.depositos.isEmpty) {
      return Text(
        'Pendiente',
        style: TextStyle(
          fontSize: cellTextSize,
          color: isDarkMode ? Colors.white70 : Colors.grey[800],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children:
          reporte.depositos.map((deposito) {
            return Text(
              deposito.fecha,
              style: TextStyle(
                fontSize: cellTextSize,
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
              ),
            );
          }).toList(),
    );
  }

   // --- MÉTODO MODIFICADO (ESCRITORIO) ---
  Widget _buildSaldoContra(ReporteGeneral reporte, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    // === CAMBIO: Usar el campo del API en lugar de calcular ===
    final double saldoContra = reporte.restanteFicha;
    final String displayValue =
        saldoContra > 0
            ? currencyFormat.format(saldoContra)
            : currencyFormat.format(0.0);

    return Text(
      displayValue,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: cellTextSize,
        color:
            saldoContra > 0
                ? (isDarkMode ? Colors.red[300] : Colors.red[700])
                : (isDarkMode ? Colors.white70 : Colors.grey[800]),
        fontWeight: saldoContra > 0 ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildBodyCell(
    dynamic content, {
    Alignment alignment = Alignment.centerLeft,
    required BuildContext context,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: alignment,
        child:
            content is String
                ? Text(
                  content,
                  style: TextStyle(
                    fontSize: cellTextSize,
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                  ),
                )
                : content,
      ),
    );
  }

  Widget _buildIndexCircle(
    int index,
    bool pagoNoRealizado,
    bool esIncompleto,
    bool faltaPagoFicha,
    bool faltaPagoMoratorios,
    BuildContext context,
  ) {
    Color circleColor = Colors.transparent;
    String tooltipMessage = 'Pago completo y al corriente';

    if (pagoNoRealizado) {
      circleColor = Colors.red;
      tooltipMessage = 'Pago no realizado';
    } else if (esIncompleto) {
      circleColor = Colors.orange;
      List<String> razones = [];
      if (faltaPagoFicha) {
        razones.add('monto de la ficha no cubierto');
      }
      if (faltaPagoMoratorios) {
        razones.add('aún debe moratorios');
      }
      tooltipMessage = 'Pago incompleto: ${razones.join(' y ')}.';
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        circleColor == Colors.transparent
            ? (isDarkMode ? Colors.white : Colors.black)
            : Colors.white;

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: circleColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            (index + 1).toString(),
            style: TextStyle(
              fontSize: cellTextSize,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

    // --- CAMBIO EN VISTA DE ESCRITORIO (dentro de _buildPagosColumn) ---
  Widget _buildPagosColumn(ReporteGeneral reporte, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white70 : Colors.grey[800];

    if (reporte.depositos.isEmpty && reporte.favorUtilizado == 0) {
      return Text(
        currencyFormat.format(0.0),
        style: TextStyle(fontSize: cellTextSize, color: textColor),
      );
    }

    List<Widget> paymentWidgets = [];

    for (var deposito in reporte.depositos) {
      if (deposito.monto > 0) {
        // --- NUEVA LÓGICA PARA IDENTIFICAR TIPO DE PAGO ---
        final bool isGarantia = deposito.garantia == "Si";
        final bool isSaldoGlobal = deposito.esSaldoGlobal == "Si";
        // --- FIN DE NUEVA LÓGICA ---
        
        const double epsilon = 0.01;
        final bool montoDifiereDeCompleto =
            reporte.depositoCompleto > 0 &&
            (deposito.monto - reporte.depositoCompleto).abs() > epsilon;

        final String depositoCompletoMsg =
            'Depósito completo: ${currencyFormat.format(reporte.depositoCompleto)}';

        String? tooltip;
        Color? bgColor;

        // --- LÓGICA DE PRIORIDAD: Garantía, Saldo Global, otros ---
        if (isGarantia) {
          bgColor = const Color(0xFFE53888);
          tooltip = 'Pago realizado con garantía';
          if (montoDifiereDeCompleto) {
            tooltip = '$tooltip\n$depositoCompletoMsg';
          }
        } else if (isSaldoGlobal) { // <-- ¡AQUÍ ESTÁ TU CAMBIO!
          bgColor = Colors.teal;
          tooltip = 'Es parte de un abono global de: ${currencyFormat.format(deposito.saldoGlobal)}';
          if (montoDifiereDeCompleto) {
            tooltip = '$tooltip\n$depositoCompletoMsg';
          }
        } else if (montoDifiereDeCompleto) {
          tooltip = depositoCompletoMsg;
        }

        paymentWidgets.add(
          _buildPaymentItem(
            context: context,
            amount: deposito.monto,
            backgroundColor: bgColor,
            tooltipMessage: tooltip,
            tooltipColor: bgColor ?? const Color(0xFFE53888),
            showInfoIcon: montoDifiereDeCompleto && !isGarantia && !isSaldoGlobal,
          ),
        );
      }
    }

    if (reporte.favorUtilizado > 0) {
      paymentWidgets.add(
        _buildPaymentItem(
          context: context,
          amount: reporte.favorUtilizado,
          backgroundColor: Colors.green,
          tooltipMessage: 'Pago con saldo a favor',
          tooltipColor: Colors.green,
        ),
      );
    }

    if (paymentWidgets.isEmpty) {
      return Text(
        currencyFormat.format(0.0),
        style: TextStyle(fontSize: cellTextSize, color: textColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: paymentWidgets,
    );
  }

  Widget _buildPaymentItem({
    required BuildContext context,
    required double amount,
    Color? backgroundColor,
    String? tooltipMessage,
    Color? tooltipColor,
    bool showInfoIcon = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor =
        (backgroundColor != null)
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.grey[800]);

    Widget paymentDisplay = Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          backgroundColor != null
              ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              )
              : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontSize: cellTextSize, color: textColor),
          ),
          if (showInfoIcon)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.info_outline, size: 10, color: textColor),
            ),
        ],
      ),
    );

    if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
      return Tooltip(
        message: tooltipMessage,
        decoration: BoxDecoration(
          color: tooltipColor ?? backgroundColor ?? Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.help,
          child: paymentDisplay,
        ),
      );
    }
    return paymentDisplay;
  }

  Widget _buildSaldoFavor(ReporteGeneral reporte, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (reporte.saldofavor == 0) {
      return Text(
        currencyFormat.format(0.0),
        style: TextStyle(
          fontSize: cellTextSize,
          color: isDarkMode ? Colors.white70 : Colors.grey[800],
        ),
      );
    }

    if (reporte.utilizadoPago == 'Si') {
      return Tooltip(
        message:
            'Saldo de ${currencyFormat.format(reporte.saldofavor)} generado y utilizado completamente en este pago.',
        child: Text(
          currencyFormat.format(reporte.saldofavor),
          style: TextStyle(
            fontSize: cellTextSize,
            color: isDarkMode ? Colors.white54 : Colors.grey[600],
            decoration: TextDecoration.lineThrough,
            decorationThickness: 1.0,
          ),
        ),
      );
    }

    if (reporte.saldoUtilizado > 0) {
      return Tooltip(
        message:
            'De un saldo total de ${currencyFormat.format(reporte.saldofavor)}, se utilizaron ${currencyFormat.format(reporte.saldoUtilizado)}.',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              currencyFormat.format(reporte.saldoDisponible),
              style: TextStyle(
                fontSize: cellTextSize,
                color: isDarkMode ? Colors.white70 : Colors.grey[800],
              ),
            ),
            Text(
              '(de ${currencyFormat.format(reporte.saldofavor)})',
              style: TextStyle(
                fontSize: cellTextSize - 2,
                color: isDarkMode ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      currencyFormat.format(reporte.saldofavor),
      style: TextStyle(
        fontSize: cellTextSize,
        color: isDarkMode ? Colors.white70 : Colors.grey[800],
      ),
    );
  }

  Widget _buildMoratoriosGenerados(
    ReporteGeneral reporte,
    BuildContext context,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final moratoriosGenerados = reporte.moratoriosAPagar;

    final color =
        moratoriosGenerados > 0
            ? (isDarkMode ? Colors.red.shade300 : Colors.red)
            : (isDarkMode ? Colors.white70 : Colors.grey[800]);

    return Text(
      currencyFormat.format(moratoriosGenerados),
      style: TextStyle(
        fontSize: cellTextSize,
        color: color,
        fontWeight:
            moratoriosGenerados > 0 ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildMoratoriosPagados(ReporteGeneral reporte, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final moratoriosPagados = reporte.sumaMoratorio;

    final color =
        moratoriosPagados > 0
            ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade700)
            : (isDarkMode ? Colors.white70 : Colors.grey[800]);

    return Text(
      currencyFormat.format(moratoriosPagados),
      style: TextStyle(
        fontSize: cellTextSize,
        color: color,
        fontWeight: moratoriosPagados > 0 ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

    // --- MÉTODO MODIFICADO (TOTALES ESCRITORIO) ---
  Widget _buildTotalsWidget() {
    if (reporteData == null) {
      return const SizedBox.shrink();
    }

    final double totalPagosFicha = reporteData!.totalPagoficha;
    final double totalFicha = reporteData!.totalFicha;
    final double totalCapital = reporteData!.totalCapital;
    final double totalInteres = reporteData!.totalInteres;
    final double totalSaldoDisponible = reporteData!.totalSaldoDisponible;
    final double totalSaldoFavorHistorico = reporteData!.totalSaldoFavor;

    // === CAMBIO: Usamos fold para sumar el nuevo campo restanteFicha ===
    double totalSaldoContra = listaReportes.fold(0.0, (sum, r) => sum + r.restanteFicha);
    
    final double totalMoratoriosGenerados = listaReportes.fold(
      0.0,
      (sum, r) => sum + r.moratoriosAPagar,
    );
    final double totalMoratoriosPagados = listaReportes.fold(
      0.0,
      (sum, r) => sum + r.sumaMoratorio,
    );

    Widget totalText(double value) {
      return Text(
        currencyFormat.format(value),
        style: TextStyle(
          fontSize: cellTextSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }
    
    // El resto del widget permanece igual, pero la variable `totalSaldoContra`
    // ya tiene el valor correcto.
    return _buildTotalsRow('Totales', [
      (content: totalText(totalPagosFicha), column: 3),
      (content: totalText(totalFicha), column: 5),
      (content: totalText(totalSaldoContra), column: 6), // <--- USA EL NUEVO CÁLCULO
      (content: totalText(totalCapital), column: 7),
      (content: totalText(totalInteres), column: 8),
      (
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            totalText(totalSaldoDisponible),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  'Total de saldo a favor generado históricamente: ${currencyFormat.format(totalSaldoFavorHistorico)}',
              child: const MouseRegion(
                cursor: SystemMouseCursors.help,
                child: Icon(Icons.info_outline, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        column: 9,
      ),
      (content: totalText(totalMoratoriosGenerados), column: 10),
      (content: totalText(totalMoratoriosPagados), column: 11),
    ]);
  }
  

  Widget _buildTotalsRow(
    String label,
    List<({Widget content, int column})> items,
  ) {
    List<Widget> cells = List.generate(12, (_) => Expanded(child: Container()));

    cells[0] = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: cellTextSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );

    for (final item in items) {
      cells[item.column] = Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          alignment: Alignment.center,
          child: item.content,
        ),
      );
    }

    return Container(
      color: const Color(0xFF5162F6),
      child: Row(children: cells),
    );
  }

  Widget _buildTotalsIdealWidget(double nuevoTotalBruto) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 109, 121, 232),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTotalItem('Total Ideal', reporteData!.totalTotal),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'El Total Ideal representa el total de:\n\n'
                    '• Monto ficha\n\n'
                    'Es el monto objetivo que se debe alcanzar.',
                decoration: BoxDecoration(
                  color: const Color(0xFFE53888),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 50),
          Row(
            children: [
              _buildTotalItem('Diferencia', reporteData!.restante),
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'La Diferencia es el monto restante para alcanzar el Total Ideal.\n\n'
                    'Se calcula restando el total de pagos recibidos del Total Ideal.',
                decoration: BoxDecoration(
                  color: const Color(0xFFE53888),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 50),
          Row(
            children: [
               _buildTotalItem('Total Bruto', nuevoTotalBruto), // <--- USAMOS EL NUEVO VALOR
              const SizedBox(width: 8),
              Tooltip(
                message:
                    'El Total Bruto representa la suma completa de todos los conceptos:\n\n'
                    '• Total Pagos\n'
                    '• Saldos a favor\n'
                    '• Moratorios\n',
                    //'Es el total acumulado antes de aplicar cualquier ajuste o validación.',
                decoration: BoxDecoration(
                  color: const Color(0xFFE53888),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: cellTextSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(fontSize: cellTextSize, color: Colors.white),
        ),
      ],
    );
  }
}
