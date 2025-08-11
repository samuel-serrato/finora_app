// lib/dialogs/info_usuario_dialog.dart

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/models/usuarios.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_logger.dart';



class InfoUsuarioDialog extends StatefulWidget {
  final String idUsuario;

  const InfoUsuarioDialog({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _InfoUsuarioDialogState createState() => _InfoUsuarioDialogState();
}

class _InfoUsuarioDialogState extends State<InfoUsuarioDialog> {
  final UsuarioService _usuarioService = UsuarioService();
  bool _isLoading = true;
  String? _errorMessage;
  Usuario? _usuario;

  @override
  void initState() {
    super.initState();
    _fetchUsuario();
  }

  Future<void> _fetchUsuario() async {
    final response = await _usuarioService.getUsuarioPorId(widget.idUsuario);
    if (!mounted) return;

    setState(() {
      if (response.success && response.data != null) {
        _usuario = response.data;
      } else {
        _errorMessage = response.error ?? "No se pudieron cargar los detalles del usuario.";
      }
      _isLoading = false;
    });
  }

  DateTime? _parseApiDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy hh:mm a', 'en_US').parse(dateString);
    } catch (e) {
      AppLogger.log('⚠️ Fallo al parsear fecha: "$dateString". Error: $e');
      return null;
    }
  }

  String _formatDate(DateTime? date, {String format = 'd \'de\' MMMM \'de\' yyyy, hh:mm a'}) {
    if (date == null) return "N/A";
    return DateFormat(format, 'es_MX').format(date);
  }
  
  String _displayValue(String? value, {String defaultValue = "No asignado"}) {
    return (value == null || value.trim().isEmpty) ? defaultValue : value;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Container(
      //height: MediaQuery.of(context).size.height * 0.75,
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
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                : _errorMessage != null || _usuario == null
                    ? _buildErrorState()
                    : _buildDetailContent(colors),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ====================== WIDGET CON LA MODIFICACIÓN =======================
  // =========================================================================
  Widget _buildDetailContent(AppColors colors) {
    final usuario = _usuario!;
    final fechaCreacion = _parseApiDate(usuario.fCreacion);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado Modificado ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alinea los elementos a los extremos
              crossAxisAlignment: CrossAxisAlignment.center, // Centra verticalmente
              children: [
                // El nombre del usuario ocupará el espacio disponible
                Expanded(
                  child: Text(
                    usuario.nombreCompleto,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    //overflow: TextOverflow.ellipsis, // Evita desbordamiento si el nombre es muy largo
                  ),
                ),
                const SizedBox(width: 16), // Un espacio entre el nombre y el chip
                // El chip de tipo de usuario
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20), // Bordes más redondeados
                    border: Border.all(color: colors.brandPrimary.withOpacity(0.3)) // Borde sutil
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: colors.brandPrimary),
                      const SizedBox(width: 6),
                      Text(
                        usuario.tipoUsuario,
                        style: TextStyle(color: colors.brandPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- Tarjetas de Información Rápida (sin cambios) ---
            Row(
              children: [
                Expanded(child: _buildStatCard('Usuario', usuario.usuario, Icons.person_pin_rounded, colors)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Email', _displayValue(usuario.email), Icons.alternate_email_rounded, colors)),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- Sección de Detalles Adicionales (sin cambios) ---
            _buildInfoSection(
              "Detalles de la Cuenta",
              [
                _buildInfoItem('ID de Usuario', usuario.idusuarios, Icons.fingerprint_rounded, colors),
                _buildInfoItem('Fecha de Creación', _formatDate(fechaCreacion), Icons.calendar_today_rounded, colors),
              ],
              colors,
            ),
          ],
        ),
      ),
    );
  }
  
  // El resto de los widgets de construcción de UI se mantienen igual.
  Widget _buildStatCard(String label, String value, IconData icon, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: colors.brandPrimary),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            maxLines: 1,
            //overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider.withOpacity(0.5)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.brandPrimary.withOpacity(0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              _errorMessage ?? 'Ocurrió un error inesperado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUsuario,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}