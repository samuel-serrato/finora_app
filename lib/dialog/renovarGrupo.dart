// Archivo: lib/dialogs/renovarGrupo.dart

import 'dart:convert';
import 'package:finora_app/ip.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

class RenovarGrupoDialog extends StatefulWidget {
  final String idGrupo;
  final VoidCallback onGrupoRenovado;

  const RenovarGrupoDialog({
    super.key,
    required this.idGrupo,
    required this.onGrupoRenovado,
  });

  @override
  _RenovarGrupoDialogState createState() => _RenovarGrupoDialogState();
}

class _RenovarGrupoDialogState extends State<RenovarGrupoDialog> {
  bool _isRenewing = false;
  String? _errorMessage;

  Future<void> _renewGroup() async {
    if (_isRenewing) return;

    setState(() {
      _isRenewing = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';

      // NOTA: Asegúrate de que este es el endpoint correcto para renovar.
      // Podría ser un POST o un PUT dependiendo de tu API.
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/grupodetalles/renovar/${widget.idGrupo}'),
        headers: {
          'tokenauth': token,
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Si la renovación es exitosa
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo renovado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onGrupoRenovado(); // Ejecuta el callback
      } else {
        // Si hay un error en la respuesta
        final errorData = json.decode(response.body);
        final message = errorData['Error']?['Message'] ?? 'Error desconocido al renovar.';
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      // Si hay un error de conexión o de otro tipo
      setState(() {
        _errorMessage = 'Error de conexión. Inténtalo de nuevo.';
      });
      AppLogger.log('Error en renovación de grupo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRenewing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    return AlertDialog(
      backgroundColor: colors.backgroundPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.autorenew_rounded, color: colors.brandPrimary),
          const SizedBox(width: 10),
          Text(
            'Confirmar Renovación',
            style: TextStyle(color: colors.textPrimary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás seguro de que deseas iniciar el proceso de renovación para este grupo?',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_isRenewing)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isRenewing ? null : _renewGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.brandPrimary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}