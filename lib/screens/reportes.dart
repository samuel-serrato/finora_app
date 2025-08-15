// NUEVO ARCHIVO: Pantalla para la generación de Reportes.
// ADAPTADO desde ClientesScreenMobile para mantener la línea de diseño.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finora_app/helpers/pdf_exporter_contable.dart';
import 'package:finora_app/helpers/pdf_exporter_general.dart';
import 'package:finora_app/helpers/responsive_helpers.dart';
import 'package:finora_app/ip.dart';
import 'package:finora_app/models/reporte_contable.dart';
import 'package:finora_app/models/reporte_general.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/screens/reporteContable.dart';
import 'package:finora_app/screens/reporteGeneral.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Se crea una nueva clase para la pantalla de reportes.
class ReportesScreenMobile extends StatefulWidget {
  final String username;
  final String tipoUsuario;

  const ReportesScreenMobile({
    super.key,
    required this.username,
    required this.tipoUsuario,
  });

  @override
  _ReportesScreenMobileState createState() => _ReportesScreenMobileState();
}

// Se crea la clase de estado correspondiente.
class _ReportesScreenMobileState extends State<ReportesScreenMobile> {
    // --- VARIABLES DE ESTADO (COMBINACIÓN DE DESKTOP Y MOBILE) ---
  String? selectedReportType;
  DateTimeRange? selectedDateRange;
  bool isLoading = false;
  bool hasGenerated = false;
  bool hasError = false;
  String? errorMessage;

  // <<< ADAPTACIÓN: Variables de datos del escritorio
  List<ReporteGeneral> listaReportes = [];
  List<ReporteContableData> listaReportesContable = [];
  ReporteGeneralData? reporteData;

  final NumberFormat currencyFormat = NumberFormat('\$#,##0.00', 'en_US');
  final DateFormat _formateadorFecha = DateFormat('dd/MM/yyyy');

  // <<< ADAPTACIÓN: Controladores de Scroll si tus widgets de reporte los necesitan
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // <<< ADAPTACIÓN: Lógica de obtención de reportes de la versión de escritorio ---
  Future<void> obtenerReportes() async {
    if (selectedReportType == null || selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tipo de reporte y rango de fechas')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasGenerated = false; // Se pondrá en true solo si hay éxito
      hasError = false;
      errorMessage = null;
      listaReportes = [];
      listaReportesContable = [];
      reporteData = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenauth') ?? '';
      final fechaInicio = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
      final fechaFin = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);
      String tipoReporte = selectedReportType == 'Contable' ? 'contable' : 'general';
      final url = Uri.parse('$baseUrl/api/v1/formato/reporte/$tipoReporte/datos?inicio=$fechaInicio&final=$fechaFin');

      final response = await http.get(
        url,
        headers: {'tokenauth': token, 'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (selectedReportType == 'Contable') {
          setState(() {
            listaReportesContable = [ReporteContableData.fromJson(data)];
          });
        } else {
          setState(() {
            reporteData = ReporteGeneralData.fromJson(data);
            listaReportes = reporteData?.listaGrupos ?? [];
          });
        }
        setState(() => hasGenerated = true); // Reporte generado con éxito
      } else {
        final errorData = json.decode(response.body);
        final String serverMessage = errorData["Error"]?["Message"] ?? "";

        if (serverMessage == "La sesión ha cambiado. Cerrando sesión...") {
          // Manejar cierre de sesión...
        } else if (response.statusCode == 401 || (response.statusCode == 404 && serverMessage == "jwt expired")) {
          // Manejar sesión expirada...

        // --- INICIO DE LA CORRECCIÓN ---
        // Se añade un caso para manejar la respuesta "No hay reportes de pagos".
        // Esto se considera una generación exitosa pero sin resultados, no un error.
        } else if (response.statusCode == 400 && serverMessage == "No hay reportes de pagos") {
          setState(() {
            hasGenerated = true; // El reporte se "generó", pero vino vacío.
          });
        // --- FIN DE LA CORRECCIÓN ---

        } else {
          // Solo los errores realmente inesperados lanzarán una excepción.
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }
    } on SocketException {
      setState(() {
        hasError = true;
        errorMessage = 'Error de conexión. Verifica tu internet.';
      });
    } on TimeoutException {
      setState(() {
        hasError = true;
        errorMessage = 'El servidor tardó mucho en responder.';
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Ocurrió un error inesperado: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // <<< ADAPTACIÓN: Lógica de exportación ADAPTADA para MÓVIL ---
  // <<< ADAPTACIÓN: Lógica de exportación CORREGIDA y MÁS ROBUSTA ---
// Método exportarReporte() corregido para dispositivos móviles
Future<void> exportarReporte() async {
  final isDarkMode =
      Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: isDarkMode ? Color(0xFF2A2D3E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF5162F6),
              ),
              const SizedBox(height: 20),
              Text(
                'Exportando reporte...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    await Future.delayed(Duration(milliseconds: 500));

    // ...
if (selectedReportType == 'Contable') {
  // Exportar reporte contable
  if (listaReportesContable.isEmpty) {
    Navigator.pop(context); // Cierra diálogo de carga
    mostrarDialogoError('No hay datos contables para exportar');
    return;
  }

  // --- INICIO DE LA CORRECCIÓN ---
  
  // 1. Crea una instancia del helper.
  final pdfHelper = PDFExportHelperContable(
      listaReportesContable.first, currencyFormat, selectedReportType, context);

  // 2. Llama al nuevo método público que hace todo.
  await pdfHelper.exportToPdf();

  // 3. Cierra el diálogo de carga.
  Navigator.pop(context);

  // Ya no necesitas más código aquí, el helper se encarga de mostrar los SnackBars.

  // --- FIN DE LA CORRECCIÓN ---
} else {
      // Exportar reporte general
      if (reporteData == null || listaReportes.isEmpty) {
        Navigator.pop(context);
        mostrarDialogoError('No hay datos del reporte general para exportar.');
        return;
      }

      Navigator.pop(context); // Cerrar diálogo de carga

      // Llamar al método corregido del ExportHelperGeneral
      await ExportHelperGeneral.exportToPdf(
        context: context,
        reporteData: reporteData,
        listaReportes: listaReportes,
        selectedDateRange: selectedDateRange,
        selectedReportType: selectedReportType,
        currencyFormat: currencyFormat,
      );
    }
  } catch (e) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    mostrarDialogoError('Error al exportar: ${e.toString()}');
  }
}

  // Función para mostrar el selector de rango de fechas.
  // Función para mostrar el selector de rango de fechas.
  // Combina la UI del móvil con la lógica de estado del escritorio.
  Future<void> _seleccionarRangoFechas(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.colors;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      // Se mantiene tu excelente implementación del builder para adaptar el tema
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.brandPrimary,
              brightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              primary: colors.brandPrimary,
              onPrimary: Colors.white,
              surface: colors.backgroundCard,
              onSurface: colors.textPrimary,
            ),
            dialogBackgroundColor: colors.backgroundCard,
          ),
          child: child!,
        );
      },
    );

    // Si el usuario selecciona un nuevo rango, actualizamos el estado.
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
        hasGenerated = false; // ¡IMPORTANTE! Resetea el estado para forzar nueva generación.
      });
    }
  }

  void mostrarDialogoError(String mensaje, {VoidCallback? onClose}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClose?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final colors = themeProvider.colors;
  final bool sePuedeGenerar = selectedReportType != null && selectedDateRange != null;

  // <<< CAMBIO 2: Usa tu helper para determinar el layout
  final bool isMobileLayout = context.isMobile; 

  return Scaffold(
    backgroundColor: colors.backgroundPrimary,
    appBar: AppBar(
      surfaceTintColor: colors.backgroundPrimary,
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      backgroundColor: colors.backgroundPrimary,
      
      bottom: PreferredSize(
        // Ajustamos la altura de la AppBar dinámicamente
        // Le damos más altura en móvil para que quepa todo en la columna.
        preferredSize: Size.fromHeight(isMobileLayout ? 110.0 : 50.0), 
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          // <<< CAMBIO 3: La lógica ahora es un simple if/else
          child: isMobileLayout
              ? _buildMobileAppBarContent(colors, sePuedeGenerar)
              : _buildDesktopAppBarContent(colors, sePuedeGenerar),
        ),
      ),
    ),
    body: _buildContenidoReporte(colors),
  );
}

// Contenido de la AppBar para el diseño móvil (en columna)
Widget _buildMobileAppBarContent(dynamic colors, bool sePuedeGenerar) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(flex: 1, child: _buildDropdownTipoReporte(colors)),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: _buildDateRangePickerButton(colors)),
        ],
      ),
      const SizedBox(height: 16),
      _buildActionButtons(colors, sePuedeGenerar),
    ],
  );
}

// Contenido de la AppBar para el diseño de escritorio (en fila)
Widget _buildDesktopAppBarContent(dynamic colors, bool sePuedeGenerar) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // Filtro de tipo de reporte
      SizedBox(
        width: 300,
        child: _buildDropdownTipoReporte(colors),
      ),
      const SizedBox(width: 12),
      // Filtro de fecha
      SizedBox(
        width: 300,
        child: _buildDateRangePickerButton(colors),
      ),
      const Spacer(), // Empuja los botones de acción hacia la derecha
      // Botones de acción
      SizedBox(
        width: 400,
        child: _buildActionButtons(colors, sePuedeGenerar),
      ),
    ],
  );
}


  // Widget para el Dropdown de selección de reporte.
  Widget _buildDropdownTipoReporte(dynamic colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Reporte',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            /*  border: Border.all(
            color: colors.textSecondary.withOpacity(0.3),
          ), */
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: selectedReportType,
              hint: Text(
                'Selecciona un tipo',
                style: TextStyle(
                  color: colors.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              isExpanded: true,
              items:
                  ['General', 'Contable'].map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (newValue) {
                   setState(() {
            selectedReportType = newValue;
            hasGenerated = false;
          });
        },
              iconStyleData: IconStyleData(
                icon: Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: colors.textSecondary.withOpacity(0.7),
                    size: 24,
                  ),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 300,
                offset: const Offset(0, -5), // Añade esta línea
                decoration: BoxDecoration(
                  color: colors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              buttonStyleData: const ButtonStyleData(
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget para el botón de selección de fecha.
   // Widget para el botón de selección de fecha.
  Widget _buildDateRangePickerButton(dynamic colors) {
    String textoBoton;
    final bool hayFechasSeleccionadas = selectedDateRange != null;

    if (!hayFechasSeleccionadas) {
      textoBoton = 'Seleccionar Fechas';
    } else {
      // Usamos el formateador de fecha definido en el estado de la clase.
      final inicio = _formateadorFecha.format(selectedDateRange!.start);
      final fin = _formateadorFecha.format(selectedDateRange!.end);
      textoBoton = '$inicio - $fin';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período del Reporte',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: colors.backgroundCard, // Fondo para el botón
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          // Usamos un solo OutlinedButton y cambiamos su contenido dinámicamente
          // para simplificar el código.
          child: OutlinedButton(
            onPressed: () => _seleccionarRangoFechas(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Colors.transparent, // El color ya está en el Container
              foregroundColor: colors.textPrimary,
              side: BorderSide.none, // Sin borde, el shadow da el efecto
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Solo muestra el ícono si no hay fechas seleccionadas
                if (!hayFechasSeleccionadas)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: colors.brandPrimary,
                    ),
                  ),
                // El texto se adapta y se asegura de no desbordarse
                Expanded(
                  child: Text(
                    textoBoton,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hayFechasSeleccionadas ? FontWeight.w500 : FontWeight.normal,
                      color: hayFechasSeleccionadas ? colors.textPrimary : colors.textSecondary,
                    ),
                    textAlign: hayFechasSeleccionadas ? TextAlign.center : TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget que contiene los botones de "Generar" y "Exportar" en fila.
   Widget _buildActionButtons(dynamic colors, bool sePuedeGenerar) {
    return Center(
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: isLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Icon(Icons.settings_suggest_rounded, color: Colors.white),
              label: Text(isLoading ? 'Generando...' : 'Generar'),
              onPressed: (sePuedeGenerar && !isLoading) ? obtenerReportes : null, // <<< ADAPTACIÓN
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                disabledForegroundColor: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          if (hasGenerated && !isLoading) ...[ // <<< ADAPTACIÓN
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white),
                label: const Text('Exportar'),
                onPressed: exportarReporte, // <<< ADAPTACIÓN
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  // Widget que muestra el contenido principal (placeholder o resultado).
   // <<< ADAPTACIÓN: Widget de contenido principal con toda la lógica de estados
  Widget _buildContenidoReporte(dynamic colors) {
  if (isLoading) {
    // Muestra un indicador de carga centrado mientras se obtienen los datos.
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0), 
        child: CircularProgressIndicator()
      )
    );
  }

  if (hasError) {
    // Muestra el mensaje de error.
    return _buildMensajeConIcono(
      icon: Icons.error_outline_rounded,
      colorIcono: Colors.red,
      titulo: 'Ocurrió un Error',
      mensaje: errorMessage ?? 'No se pudo cargar el reporte. Inténtalo de nuevo.',
      colors: colors,
    );
  }

  if (hasGenerated) {
    // Muestra el widget del reporte correspondiente.
    if (selectedReportType == 'Contable' && listaReportesContable.isNotEmpty) {
      // ASUMCIÓN: Tienes un widget `ReporteContableWidget` adaptado para móvil.
      return ReporteContableWidget(
        reporteData: listaReportesContable.first,
        currencyFormat: currencyFormat,
        horizontalScrollController: _horizontalScrollController, // ✅ Parámetro correcto
        verticalScrollController: _verticalScrollController, // ✅ Parámetro correcto
        //scrollController: _verticalScrollController,
      );
    } else if (selectedReportType == 'General' && reporteData != null) {
      // Widget ReporteGeneralMobileWidget corregido para móvil
      return ReporteGeneralWidget(
        listaReportes: listaReportes,
        reporteData: reporteData,
        currencyFormat: currencyFormat,
        verticalScrollController: _verticalScrollController, // ✅ Parámetro correcto
        horizontalScrollController: _horizontalScrollController, // ✅ Parámetro correcto
      );
    } else {
      // Caso raro: generado pero sin datos.
      return _buildMensajeConIcono(
        icon: Icons.search_off_rounded,
        colorIcono: Colors.orange,
        titulo: 'Sin Resultados',
        mensaje: 'No se encontraron datos para los filtros seleccionados.',
        colors: colors,
      );
    }
  }

  // Estado inicial: mensaje para que el usuario seleccione filtros.
  return _buildMensajeConIcono(
    icon: Icons.description_outlined,
    colorIcono: Colors.grey[400]!,
    titulo: 'Listo para generar',
    mensaje: 'Por favor, selecciona el tipo de reporte y el período de fechas para comenzar.',
    colors: colors,
  );
}

  // Widget de ayuda para mostrar mensajes
  Widget _buildMensajeConIcono({
    required IconData icon,
    required Color colorIcono,
    required String titulo,
    required String mensaje,
    required dynamic colors,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: colorIcono.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 60, color: colorIcono),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
