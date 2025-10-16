// En: lib/widgets/global_options_sheet.dart

import 'package:finora_app/models/saldo_global.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/providers/user_data_provider.dart';
import 'package:finora_app/services/pago_service.dart';
import 'package:finora_app/widgets/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum GlobalOptionView { menuPrincipal, abonoGlobal }

class GlobalOptionsSheet extends StatefulWidget {
  final String idCredito;
  final PagoService pagoService;
  final VoidCallback onDataChanged;
  final Future<void> Function(double monto, DateTime fecha) onSaveAbonoGlobal;
  final List<SaldoGlobal> saldosGlobales;

  const GlobalOptionsSheet({
    Key? key,
    required this.idCredito,
    required this.pagoService,
    required this.onDataChanged,
    required this.onSaveAbonoGlobal,
    this.saldosGlobales = const [],
  }) : super(key: key);

  @override
  State<GlobalOptionsSheet> createState() => _GlobalOptionsSheetState();
}

class _GlobalOptionsSheetState extends State<GlobalOptionsSheet> {
  GlobalOptionView _vistaActual = GlobalOptionView.menuPrincipal;
  bool _isSaving = false;
  late final TextEditingController _abonoGlobalController;
  DateTime _fechaSeleccionada = DateTime.now();

  // <--- CAMBIO 1: Añadimos una lista local para manejar el estado visualmente
  late List<SaldoGlobal> _localSaldosGlobales;

  @override
  void initState() {
    super.initState();
    _abonoGlobalController = TextEditingController();
    // <--- CAMBIO 2: Inicializamos la lista local con los datos del widget
    _localSaldosGlobales = List<SaldoGlobal>.from(widget.saldosGlobales);
  }

  @override
  void dispose() {
    _abonoGlobalController.dispose();
    super.dispose();
  }

  String formatearFecha(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona la fecha del abono',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF4F46E5),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaElegida != null && fechaElegida != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
    }
  }

  void _cambiarVista(GlobalOptionView nuevaVista) {
    setState(() {
      _vistaActual = nuevaVista;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final monto =
        double.tryParse(_abonoGlobalController.text.replaceAll(',', '')) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El monto debe ser mayor a cero."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSaveAbonoGlobal(monto, _fechaSeleccionada);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white30 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(context),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentView(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String titulo;
    switch (_vistaActual) {
      case GlobalOptionView.abonoGlobal:
        titulo = 'Abono Global';
        break;
      case GlobalOptionView.menuPrincipal:
      default:
        titulo = 'Opciones del Crédito';
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        if (_vistaActual != GlobalOptionView.menuPrincipal)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => _cambiarVista(GlobalOptionView.menuPrincipal),
              tooltip: 'Volver al menú',
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentView(BuildContext context) {
    switch (_vistaActual) {
      case GlobalOptionView.abonoGlobal:
        return Container(
          key: const ValueKey('vista_abono_global'),
          child: _buildAbonoGlobalView(context),
        );
      case GlobalOptionView.menuPrincipal:
      default:
        return Container(
          key: const ValueKey('menu_principal'),
          child: _buildMenuPrincipal(context),
        );
    }
  }

  Widget _buildMenuPrincipal(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOptionTile(
          context: context,
          icon: Icons.all_inclusive,
          title: 'Abono Global',
          subtitle: 'Aplica un pago y consulta el historial',
          color: Colors.teal,
          onTap: () => _cambiarVista(GlobalOptionView.abonoGlobal),
          isDarkMode: themeProvider.isDarkMode,
        ),
      ],
    );
  }

  Widget _buildAbonoGlobalView(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final colors = themeProvider.colors;

    final userDataProvider = Provider.of<UserDataProvider>(
      context,
      listen: false,
    );
    final esAdmin = userDataProvider.tipoUsuario == 'Admin';

    // <--- CAMBIO 3: Usamos la lista local para construir la lista ordenada
    final List<SaldoGlobal> saldosOrdenados =
        _localSaldosGlobales.toList()
          ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECCIÓN 1: HISTORIAL ---
          if (saldosOrdenados.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Historial de Abonos Realizados:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 16),
                LimitedBox(
                  maxHeight: 180,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: saldosOrdenados.length,
                    itemBuilder: (context, index) {
                      final saldo = saldosOrdenados[index];
                      final fechaFormateada = DateFormat(
                        'dd MMM yyyy',
                      ).format(saldo.fechaCreacion.toLocal());
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        color: colors.backgroundCard,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colors.divider.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.receipt_long,
                            color: Colors.indigo,
                          ),
                          title: Text(
                            "\$${formatearNumero(saldo.totalSaldoGlobal)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            "Fecha: $fechaFormateada",
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing:
                              esAdmin
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Eliminar abono global',
                                    onPressed: () {
                                      _handleDeleteAbonoGlobal(
                                        saldo.idsaldoglobal,
                                      );
                                    },
                                  )
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),
              ],
            ),

          // --- SECCIÓN 2: FORMULARIO PARA AÑADIR NUEVO ABONO ---
          Text(
            "Ingresa un monto y la fecha del depósito. Se distribuirá automáticamente entre las deudas pendientes.",
            style: TextStyle(
              fontSize: 14,
              color:
                  themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _abonoGlobalController,
                        enabled: !_isSaving,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Monto del Abono',
                          hintText: '0.00',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: themeProvider.colors.backgroundCard,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          formatearFecha(_fechaSeleccionada),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: _isSaving ? null : _seleccionarFecha,
                        style: TextButton.styleFrom(
                          foregroundColor: themeProvider.colors.textButton2,
                          backgroundColor: themeProvider.colors.backgroundCard,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          minimumSize: const Size(0, 45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon:
                  _isSaving
                      ? const SizedBox.shrink()
                      : const Icon(Icons.save_alt),
              label:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text("Aplicar Abono"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAbonoGlobal(String idSaldoglobal) async {
    final bool? confirmado = await showCustomDialog(
      context: context,
      title: 'Confirmar Eliminación',
      content:
          '¿Estás seguro de que deseas eliminar este abono global? Esta acción no se puede deshacer.',
      confirmText: 'Sí, Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmado != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text("Eliminando..."),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final response = await widget.pagoService.eliminarSaldoGlobal(
        idSaldoglobal: idSaldoglobal,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (!mounted) return;

      if (response.success) {
        // <--- CAMBIO 4: ¡LA PARTE MÁS IMPORTANTE!
        // Actualizamos la lista local y llamamos a setState para redibujar la UI.
        setState(() {
          _localSaldosGlobales.removeWhere(
            (saldo) => saldo.idsaldoglobal == idSaldoglobal,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Abono global eliminado correctamente."),
            backgroundColor: Colors.green,
          ),
        );

        // Esta línea sigue siendo importante para que la pantalla de atrás se actualice también.
        widget.onDataChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar: ${response.error}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ocurrió un error inesperado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode ? Colors.white30 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String formatearNumero(double numero) {
    final formatter = NumberFormat("#,##0.00", "es_MX");
    return formatter.format(numero);
  }
}
