// Archivo: lib/dialog/grupo_detalle_dialog.dart

import 'dart:async';
import 'package:finora_app/dialog/renovarGrupo.dart';
import 'package:finora_app/forms/renovar_grupo_form.dart';
import 'package:finora_app/models/grupos.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/api_service.dart';
import 'package:finora_app/services/grupo_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';


class GrupoDetalleDialog extends StatefulWidget {
  final String idGrupo;
  final String nombreGrupo;
  final VoidCallback onGrupoRenovado;

  const GrupoDetalleDialog({
    super.key,
    required this.idGrupo,
    required this.nombreGrupo,
    required this.onGrupoRenovado,
  });

  @override
  _GrupoDetalleDialogState createState() => _GrupoDetalleDialogState();
}

class _GrupoDetalleDialogState extends State<GrupoDetalleDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Grupo? grupoData;
  List<dynamic> historialData = [];
  bool isLoading = true;
  bool errorDeConexion = false;
  String errorMessage = 'Ocurrió un error inesperado.';

  final GrupoService _grupoService = GrupoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorDeConexion = false;
    });

    try {
      final responses = await Future.wait([
        _grupoService.getGrupoDetalles(widget.idGrupo),
        // AQUÍ ESTÁ EL CAMBIO
        _grupoService.getGrupoHistorial(
          widget.nombreGrupo,
          showErrorDialog: false, // <--- ¡AÑADE ESTA LÍNEA!
        ),
      ]);

      if (!mounted) return;

      final grupoResponse = responses[0] as ApiResponse<Grupo>;
      final historialResponse = responses[1] as ApiResponse<List<dynamic>>;

      if (grupoResponse.success && grupoResponse.data != null) {
        grupoData = grupoResponse.data;
      } else {
        errorDeConexion = true;
        errorMessage =
            grupoResponse.error ??
            "No se pudieron obtener los datos del grupo.";
        setState(() => isLoading = false);
        return;
      }

      if (historialResponse.success && historialResponse.data != null) {
        historialData = historialResponse.data!;
      } else {
        AppLogger.log(
          "Aviso: No se pudo cargar el historial. ${historialResponse.error}",
        );
        historialData = [];
      }
    } catch (e) {
      if (mounted) {
        errorDeConexion = true;
        errorMessage =
            "Error de conexión o del servidor. Por favor, inténtalo de nuevo.";
        AppLogger.log("Error en _fetchAllData: $e");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

    // --- FUNCIÓN MODIFICADA ---
   // --- REEMPLAZA TU ANTIGUA FUNCIÓN _mostrarDialogoRenovar CON ESTA ---
  void _mostrarDialogoRenovar(String idGrupo) {
    // Obtenemos el ancho total de la pantalla ANTES de llamar al BottomSheet.
    final fullScreenWidth = MediaQuery.of(context).size.width;

    // Definimos las constantes y calculamos el ancho del diálogo aquí mismo.
    const double mobileBreakpoint = 600.0;
    double dialogMaxWidth;

    if (fullScreenWidth < mobileBreakpoint) {
      // En móvil, el diálogo ocupa todo el ancho.
      dialogMaxWidth = fullScreenWidth;
    } else {
      // En escritorio, el diálogo ocupa un porcentaje de la pantalla.
      // Puedes ajustar este valor si lo necesitas.
      dialogMaxWidth = fullScreenWidth * 0.7; 
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
          // Esto asegura que el teclado no tape el formulario
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // La altura máxima se sigue controlando aquí.
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            // --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
            // Llamamos a RenovarGrupoForm en lugar de GrupoDetalleDialog
            child: RenovarGrupoForm(
              idGrupo: idGrupo,
              onGrupoRenovado: () {
                // Cerramos este diálogo de detalles para volver a la lista principal.
                // Lo hacemos desde aquí porque el RenovarGrupoForm ya se cierra solo.
                Navigator.of(context).pop(); 
                widget.onGrupoRenovado(); // Refresca la lista de grupos.
              },
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // CAMBIO 1: Reemplazar DraggableScrollableSheet con un Container de altura fija.
    return Container(
      //height: MediaQuery.of(context).size.height * 0.92, // Altura fija del 90%
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar (igual que en ClienteDetalleDialog)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: colors.brandPrimary,
                      ),
                    )
                    : errorDeConexion || grupoData == null
                    ? _buildErrorState()
                    : _buildDetailContent(themeProvider),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_MX').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  // CAMBIO 2: Eliminar el parámetro 'scrollController' de las funciones.
  Widget _buildDetailContent(ThemeProvider themeProvider) {
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      grupoData!.nombreGrupo,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildModernStatusChip(grupoData!.estado),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: _buildQuickStats(colors, isDarkMode),
              ),
            ],
          ),
        ),
        _buildModernTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInformacionTab(
                colors,
                isDarkMode,
              ), // Ya no necesita scrollController
              _buildIntegrantesList(
                colors,
                isDarkMode,
              ), // Ya no necesita scrollController
              _buildHistorialList(
                colors,
                isDarkMode,
              ), // Ya no necesita scrollController
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(colors, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Integrantes',
            '${grupoData!.clientes.length}',
            Icons.person_outline_rounded,
            colors,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Historial',
            '${historialData.length}',
            Icons.history_rounded,
            colors,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tipo',
            grupoData!.tipoGrupo,
            Icons.category_outlined,
            colors,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    colors,
    bool isDarkMode,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.navigatorBorder),
      ),
      child: Column(
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
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // (El resto de tus widgets de construcción de UI como _buildInformacionGrid, _buildInfoTile, etc., no necesitan cambios en su lógica interna)
  // ... (código sin cambios)

  Widget _buildRenovacionButton(colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Container(
      width: double.infinity,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton.icon(
        onPressed: () => _mostrarDialogoRenovar(widget.idGrupo),
        icon: Icon(Icons.autorenew_rounded, size: 20, color: colors.iconButton),
        label: const Text(
          'Renovar Grupo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brandPrimary,
          foregroundColor: colors.whiteWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInformacionTab(
    colors,
    bool isDarkMode,
    // CAMBIO 3: Eliminar el parámetro 'scrollController'
  ) {
    // CAMBIO 4: Quitar el 'controller' del SingleChildScrollView.
    // El widget se encargará de su propio scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            null,
            null,
            [
              _buildInfoItem(
                'Asesor',
                grupoData!.asesor,
                Icons.person_pin_rounded,
              ),
              _buildInfoItem(
                'Tipo de Grupo',
                grupoData!.tipoGrupo,
                Icons.category_outlined,
              ),
              _buildInfoItem(
                'Descripción',
                grupoData!.detalles,
                Icons.notes,
                isExpanded: true,
              ),
              _buildInfoItem(
                'Folio del Crédito',
                grupoData!.folio,
                Icons.receipt_long_rounded,
              ),
              _buildInfoItem(
                'Creado el',
                _formatDate(grupoData!.fCreacion),
                Icons.event_rounded,
              ),
            ],
            colors,
            isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildRenovacionButton(colors),
        ],
      ),
    );
  }

  // (El resto de tus widgets de construcción de UI como _buildInformacionGrid, _buildInfoTile, etc., no necesitan cambios en su lógica interna)
  // ... (código sin cambios hasta llegar a los que usan el scrollController)
  Widget _buildInfoSection(
    String? title, // Ahora es opcional
    IconData? titleIcon, // Ahora es opcional
    List<Widget> items,
    colors,
    bool isDarkMode,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solo mostrar header si title no es null o vacío
            if (title != null && title.isNotEmpty) ...[
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        titleIcon,
                        color: colors.brandPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            ...items,
          ],
        ),
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
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 0),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildModernTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      height: 48,
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider)
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
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //const Icon(Icons.info_outline_rounded, size: 12),
                  const SizedBox(width: 2),
                  const Text('Información'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //const Icon(Icons.people_outline_rounded, size: 12),
                  const SizedBox(width: 2),
                  const Text('Integrantes'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //const Icon(Icons.history_rounded, size: 12),
                  const SizedBox(width: 2),
                  const Text('Historial'),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildIntegrantesList(
    colors,
    bool isDarkMode,
    // CAMBIO 3
  ) {
    if (grupoData!.clientes.isEmpty) {
      return _buildEmptyState(
        'No hay integrantes',
        'Este grupo no tiene integrantes registrados.',
        Icons.people_outline_rounded,
        colors,
        isDarkMode,
      );
    }

    // CAMBIO 4
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: grupoData!.clientes.length,
      itemBuilder: (context, index) {
        final cliente = grupoData!.clientes[index];
        return _buildClienteCard(cliente, colors, isDarkMode);
      },
    );
  }

  // ... (código de _buildClienteCard, _buildAccountDetails, etc., sin cambios)...
  Widget _buildClienteCard(cliente, colors, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.brandPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            color: colors.brandPrimary,
            size: 20,
          ),
        ),
        title: Text(
          cliente.nombres,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          cliente.cargo,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        children: [
          if (cliente.cuenta != null)
            _buildAccountDetails(cliente.cuenta, colors, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(CuentaResumen? cuenta, colors, bool isDarkMode) {
    if (cuenta == null ||
        (cuenta.nombreBanco.isEmpty &&
            cuenta.numCuenta.isEmpty &&
            cuenta.numTarjeta.isEmpty &&
            cuenta.clbIntBanc.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No hay información de cuenta disponible.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final accountInfo = [
      {
        'label': 'Banco',
        'value': cuenta.nombreBanco,
        'icon': Icons.account_balance,
      },
      {
        'label': 'No. Cuenta',
        'value': cuenta.numCuenta,
        'icon': Icons.credit_card,
      },
      {
        'label': 'No. Tarjeta',
        'value': cuenta.numTarjeta,
        'icon': Icons.payment,
      },
      {
        'label': 'CLABE',
        'value': cuenta.clbIntBanc,
        'icon': Icons.receipt_long,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Bancaria',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...accountInfo
                .where((item) => (item['value'] as String).isNotEmpty)
                .map(
                  (item) => _buildAccountRow(
                    item['label'] as String,
                    item['value'] as String,
                    item['icon'] as IconData,
                    colors,
                    isDarkMode,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountRow(
    String label,
    String value,
    IconData icon,
    colors,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.brandPrimary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialList(
    colors,
    bool isDarkMode,
    // CAMBIO 3
  ) {
    if (historialData.isEmpty) {
      return _buildEmptyState(
        'Sin historial',
        'No hay registros históricos para este grupo.',
        Icons.history_rounded,
        colors,
        isDarkMode,
      );
    }

    // CAMBIO 4
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: historialData.length,
      itemBuilder: (context, index) {
        var item = historialData[index];
        return _buildHistorialCard(item, colors, isDarkMode);
      },
    );
  }

  // ... (código de _buildHistorialCard, _buildGrupoYClientes, etc., sin cambios)...
  Widget _buildHistorialCard(Map item, colors, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.history_edu_outlined,
            color: Colors.purple.shade700,
            size: 20,
          ),
        ),
        title: Text(
          item['nombreGrupo'] ?? 'Versión anterior',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Folio: ${item['folio'] ?? 'N/A'} • Estado: ${item['estado']}',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        children: [_buildGrupoYClientes(item, colors, isDarkMode)],
      ),
    );
  }

  Widget _buildGrupoYClientes(Map historialItem, colors, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    List clientes = historialItem['clientes'] ?? [];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.backgroundCardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((historialItem['detalles'] ?? '').isNotEmpty) ...[
              Text(
                'Detalles:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                historialItem['detalles'] ?? 'N/A',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Integrantes (${clientes.length}):',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...clientes.map<Widget>(
              (cliente) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: colors.brandPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente['nombres'],
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      cliente['cargo'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    colors,
    bool isDarkMode,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 48, color: colors.brandPrimary),
            ),
            const SizedBox(height: 16),
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
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    // CAMBIO 2
    // CAMBIO 4
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar la información',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
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
      ),
    );
  }
}
