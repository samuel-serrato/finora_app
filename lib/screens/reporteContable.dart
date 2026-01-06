// lib/screens/reporteContable.dart (ACTUALIZADO CON TOOLTIP EN ESCRITORIO Y MÓVIL)

import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReporteContableWidget extends StatelessWidget {
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

  static const Color primaryColor = Color(0xFF5162F6);
  static const Color abonoGlobalColor = Colors.teal;
  static const Color garantiaColor = Color(0xFFE53888); // <--- AÑADE ESTA LÍNEA

  // === AÑADIDO: Color para Saldo a Favor ===
  static final Color saldoFavorColor = Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  // =========================================================================
  // === CAMBIO PRINCIPAL: Añadir Tooltip para Abono Global en Escritorio ====
  // =========================================================================
  Widget _buildDesktopStandardDepositCard(
    BuildContext context,
    Deposito deposito,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isSaldoGlobal = deposito.esSaldoGlobal == "Si";

    // 1. Creamos el widget de la etiqueta visual
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

    // 2. Si es un abono global, envolvemos la etiqueta en un Tooltip con el nuevo diseño
    if (isSaldoGlobal) {
      labelWidget = Tooltip(
        message:
            'Es parte de un abono global de: ${currencyFormat.format(deposito.saldoGlobal)}',
        // === MODIFICADO: Estilo del Tooltip ===
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
                      // 3. Usamos el widget (con o sin tooltip)
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

  // =========================================================================
  // === EL RESTO DEL CÓDIGO PERMANECE IGUAL (SALVO OTROS TOOLTIPS) ==========
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
          if (reporteData.listaGrupos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: Center(child: Text('No hay grupos para mostrar')),
            )
          else
            Column(
              children:
                  reporteData.listaGrupos
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
          _buildMobileInfoRow('Período', reporteData.fechaSemana, context),
          _buildMobileInfoRow('Generado', reporteData.fechaActual, context),
        ],
      ),
    );
  }

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
                    currencyFormat.format(grupo.montoSolicitado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Interés Total',
                    currencyFormat.format(grupo.interesCredito),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto Ficha',
                    currencyFormat.format(grupo.montoficha),
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
                    currencyFormat.format(grupo.montoDesembolsado),
                  ),
                  _buildMobileFinancialItem(
                    context,
                    'Monto a Recuperar',
                    currencyFormat.format(grupo.montoARecuperar),
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
                currencyFormat.format(grupo.capitalsemanal),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Interés $periodoText',
                currencyFormat.format(grupo.interessemanal),
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
                currencyFormat.format(grupo.moratorios.moratoriosAPagar),
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMobileStatCard(
                context,
                'Moratorios Pagados',
                currencyFormat.format(grupo.pagoficha.sumaMoratorio),
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
                      currencyFormat.format(cliente.capitalMasInteres),
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
                  'Cap: ${currencyFormat.format(cliente.periodoCapital)} • Int: ${currencyFormat.format(cliente.periodoInteres)}',
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
              currencyFormat.format(totalGeneral),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileDepositosList(
    BuildContext context,
    ReporteContableGrupo grupo,
  ) {
    final pagoficha = grupo.pagoficha;
    final colors = Provider.of<ThemeProvider>(context).colors;

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
          currencyFormat.format(pagoficha.sumaDeposito),
          valueColor: primaryColor,
        ),
        _buildMobileDetailRow(
          context,
          'Restante Ficha',
          currencyFormat.format(grupo.restanteFicha),
          valueColor: Colors.orange.shade700,
        ),
        const Divider(height: 16),
        _buildMobileDetailRow(
          context,
          'Saldo Global Crédito',
          currencyFormat.format(grupo.saldoGlobal),
        ),
        _buildMobileDetailRow(
          context,
          'Restante Global Crédito',
          currencyFormat.format(grupo.restanteGlobal),
        ),
      ],
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
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Usado en otro pago)';
      tooltipMessage =
          'Un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'Saldo a Favor Disponible';
      primaryText = currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText =
          '(de ${currencyFormat.format(pagoficha.saldofavor)} total)';
      tooltipMessage =
          'De un saldo total de ${currencyFormat.format(pagoficha.saldofavor)}, se usaron ${currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'Saldo a Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = '(Disponible)';
      tooltipMessage =
          'Se generó un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    return Tooltip(
      message: tooltipMessage,
      // === MODIFICADO: Estilo del Tooltip ===
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

  // REEMPLAZA ESTA FUNCIÓN COMPLETA
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
        color: isGarantia
            ? garantiaColor
            : isSaldoGlobal
                ? abonoGlobalColor
                : Colors.grey.withOpacity(0.2),
        width: (isGarantia || isSaldoGlobal) ? 1.5 : 1.0,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // Alinea al inicio
      children: [
        // Columna de la izquierda (Depósito e Info)
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
                currencyFormat.format(deposito.deposito),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              // --- CAMBIO PRINCIPAL: Mostrar etiquetas de texto ---
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
                              'Es parte de un abono global de: ${currencyFormat.format(deposito.saldoGlobal)}',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Columna de la derecha (Moratorio)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Moratorio',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(deposito.pagoMoratorio),
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

// AÑADE ESTA NUEVA FUNCIÓN AUXILIAR
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
              currencyFormat.format(favorUtilizado),
              valueColor: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
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
        ],
      ),
    );
  }

  Widget _buildMobileTotalsSummary(BuildContext context) {

    // --- NUEVOS CÁLCULOS MANUALES PARA PRECISIÓN ---
    final double totalMoratoriosGenerados = reporteData.listaGrupos.fold(
      0.0, (sum, g) => sum + g.moratorios.moratoriosAPagar);
    
    final double totalMoratoriosPagados = reporteData.listaGrupos.fold(
      0.0, (sum, g) => sum + g.pagoficha.sumaMoratorio);

    final double nuevoTotalBruto = reporteData.totalPagoficha + 
                                   reporteData.totalSaldoDisponible + 
                                   totalMoratoriosPagados;

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
          _buildMobileDetailRow(
            context,
            'Capital Total',
            currencyFormat.format(reporteData.totalCapital),
          ),
          _buildMobileDetailRow(
            context,
            'Interés Total',
            currencyFormat.format(reporteData.totalInteres),
          ),
          const Divider(height: 16),
          _buildMobileDetailRow(
            context,
            'Monto Total Fichas',
            currencyFormat.format(reporteData.totalFicha),
          ),
          _buildMobileDetailRow(
            context,
            'Pago Total Fichas',
            currencyFormat.format(reporteData.totalPagoficha),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'S. Favor Disponible',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
              Tooltip(
                message:
                    'Total generado históricamente: ${currencyFormat.format(reporteData.totalSaldoFavor)}',
                // === MODIFICADO: Estilo del Tooltip ===
                decoration: BoxDecoration(
                  color: saldoFavorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                waitDuration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Text(
                      currencyFormat.format(reporteData.totalSaldoDisponible),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
             const Divider(height: 16),
          // --- DESGLOSE DE MORATORIOS ---
          _buildMobileDetailRow(
            context,
            'Moratorios Gen.',
            currencyFormat.format(totalMoratoriosGenerados),
            valueColor: totalMoratoriosGenerados > 0 ? Colors.red.shade400 : null,
          ),
          _buildMobileDetailRow(
            context,
            'Moratorios Pag.',
            currencyFormat.format(totalMoratoriosPagados),
            valueColor: totalMoratoriosPagados > 0 ? Colors.green.shade600 : null,
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
                    _buildMobileTotalItem(
                      'Total Ideal',
                      reporteData.totalTotal,
                    ),
                    _buildMobileTotalItem('Diferencia', reporteData.restante),
                  ],
                ),
                const Divider(color: Colors.white30, height: 20),
                _buildMobileTotalItem(
                  'Total Bruto',
                  nuevoTotalBruto
                ),
              ],
            ),
          ),
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
          currencyFormat.format(value),
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
          reporteData.fechaSemana,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Generado: ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          reporteData.fechaActual,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: isDarkMode ? Colors.grey[300] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTotalesCard(BuildContext context) {
  
    // --- NUEVOS CÁLCULOS MANUALES ---
    final double totalMoratoriosGenerados = reporteData.listaGrupos.fold(
      0.0, (sum, g) => sum + g.moratorios.moratoriosAPagar);
    
    final double totalMoratoriosPagados = reporteData.listaGrupos.fold(
      0.0, (sum, g) => sum + g.pagoficha.sumaMoratorio);

    final double nuevoTotalBruto = reporteData.totalPagoficha + 
                                   reporteData.totalSaldoDisponible + 
                                   totalMoratoriosPagados;


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
                  controller: horizontalScrollController,
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
                        'Capital Total',
                        reporteData.totalCapital,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Interés Total',
                        reporteData.totalInteres,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Monto Fichas',
                        reporteData.totalFicha,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Pago Fichas',
                        reporteData.totalPagoficha,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSaldoFavorTotalItem(context),
                          const SizedBox(width: 24),
                      // --- NUEVOS ITEMS DE MORATORIOS ---
                      _buildDesktopSummaryItem(
                        context,
                        'Mor. Gen.',
                        totalMoratoriosGenerados,
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
                        reporteData.totalTotal,
                        isPrimary: true,
                      ),
                      const SizedBox(width: 24),
                      _buildDesktopSummaryItem(
                        context,
                        'Diferencia',
                        reporteData.restante,
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

  Widget _buildDesktopSaldoFavorTotalItem(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      children: [
        _buildDesktopSummaryItem(
          context,
          'S. Favor Disp.',
          reporteData.totalSaldoDisponible,
        ),
        const SizedBox(width: 6),
        Tooltip(
          message:
              'Total generado históricamente: ${currencyFormat.format(reporteData.totalSaldoFavor)}',
          // === MODIFICADO: Estilo del Tooltip ===
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

  Widget _buildDesktopSummaryItem(
    BuildContext context,
    String label,
    double value, {
    bool isPrimary = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              currencyFormat.format(value),
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
      ],
    );
  }

  Widget _buildDesktopGruposList(BuildContext context) {
    if (reporteData.listaGrupos.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }
    return ListView.builder(
      controller: verticalScrollController,
      itemCount: reporteData.listaGrupos.length,
      itemBuilder: (context, index) {
        final grupo = reporteData.listaGrupos[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDesktopGrupoCard(context, grupo),
        );
      },
    );
  }

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
                Expanded(child: _buildDesktopClientesSection(grupo, context)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _buildDesktopFinancialColumn(context, grupo),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _buildDesktopDepositosSection(
                    context,
                    grupo.pagoficha,
                    grupo.restanteFicha,
                    grupo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          '${currencyFormat.format(value)}${isPercentage ? '%' : ''}',
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
            currencyFormat.format(value),
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
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        currencyFormat.format(cliente.periodoCapital),
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
                        currencyFormat.format(cliente.periodoInteres),
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
                        currencyFormat.format(cliente.capitalMasInteres),
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
                      currencyFormat.format(totalCapital),
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
                      currencyFormat.format(totalInteres),
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
                      currencyFormat.format(totalGeneral),
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
          constraints: const BoxConstraints(maxHeight: 220),
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
                currencyFormat.format(pagoficha.sumaDeposito),
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
                currencyFormat.format(restanteFicha),
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
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'Usado en otro pago.';
      tooltipMessage =
          'Un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} generado en este pago fue utilizado completamente en otro.';
    } else if (pagoficha.saldoUtilizado > 0) {
      title = 'S. Favor Disponible';
      primaryText = currencyFormat.format(pagoficha.saldoDisponible);
      secondaryText = 'de ${currencyFormat.format(pagoficha.saldofavor)} total';
      tooltipMessage =
          'De un saldo total de ${currencyFormat.format(pagoficha.saldofavor)}, se usaron ${currencyFormat.format(pagoficha.saldoUtilizado)} en otro pago.';
    } else {
      title = 'S. Favor Generado';
      primaryText = currencyFormat.format(pagoficha.saldofavor);
      secondaryText = 'disponible';
      tooltipMessage =
          'Se generó un saldo a favor de ${currencyFormat.format(pagoficha.saldofavor)} en este pago, que está disponible para usarse.';
    }

    return Tooltip(
      message: tooltipMessage,
      // === MODIFICADO: Estilo del Tooltip ===
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
              isDarkMode ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50],
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
      // === MODIFICADO: Estilo del Tooltip ===
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
                    currencyFormat.format(favorUtilizado),
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

  Widget _buildDesktopSaldoFavorDetail(
    BuildContext context,
    Pagoficha pagoficha,
  ) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    Widget valueDisplay;
    String? tooltipMessage;

    if (pagoficha.saldofavor == 0) {
      valueDisplay = Text(
        currencyFormat.format(0.0),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: isDarkMode ? Colors.grey[200] : Colors.black87,
        ),
      );
    } else if (pagoficha.utilizadoPago == 'Si') {
      tooltipMessage =
          'Saldo de ${currencyFormat.format(pagoficha.saldofavor)} utilizado completamente en otro pago.';
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white54 : Colors.grey[600],
          decoration: TextDecoration.lineThrough,
        ),
      );
    } else if (pagoficha.saldoUtilizado > 0) {
      tooltipMessage =
          'Original: ${currencyFormat.format(pagoficha.saldofavor)}\n'
          'Utilizado: ${currencyFormat.format(pagoficha.saldoUtilizado)}\n'
          'Disponible: ${currencyFormat.format(pagoficha.saldoDisponible)}';
      valueDisplay = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currencyFormat.format(pagoficha.saldoDisponible),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: isDarkMode ? Colors.grey[200] : Colors.black87,
            ),
          ),
          Text(
            '(de ${currencyFormat.format(pagoficha.saldofavor)})',
            style: TextStyle(
              fontSize: 9,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      );
    } else {
      valueDisplay = Text(
        currencyFormat.format(pagoficha.saldofavor),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
          color: isDarkMode ? Colors.grey[200] : Colors.black87,
        ),
      );
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 10,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 3),
            Text(
              'Saldo a Favor',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        valueDisplay,
      ],
    );

    if (tooltipMessage != null) {
      return Tooltip(
        message: tooltipMessage,
        // === MODIFICADO: Estilo del Tooltip ===
        decoration: BoxDecoration(
          color: saldoFavorColor, // Verde para saldo a favor
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 300),
        child: MouseRegion(cursor: SystemMouseCursors.help, child: content),
      );
    }
    return content;
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
              currencyFormat.format(value),
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
            'Depósito completo: ${currencyFormat.format(depositoCompleto!)}',
        // === MODIFICADO: Estilo del Tooltip (ahora es consistente) ===
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
