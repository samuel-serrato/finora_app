import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';

enum TipoFiltro {
  dropdown,
  rangoFechas,
  // Agregar más tipos según necesidad
}

class ConfiguracionFiltro {
  final String clave;
  final String titulo;
  final TipoFiltro tipo;
  List<String>? opciones; // Para dropdowns
  final DateTime? fechaInicial; // Para rangos de fechas
  final DateTime? fechaFinal; // Para rangos de fechas

  ConfiguracionFiltro({
    required this.clave,
    required this.titulo,
    required this.tipo,
    this.opciones,
    this.fechaInicial,
    this.fechaFinal,
  });
}

// WIDGET GENÉRICO ADAPTADO PARA MOBILE (Bottom Sheet)
class FiltrosGenericosMobile extends StatefulWidget {
  final List<ConfiguracionFiltro> configuraciones;
  final Map<String, dynamic> valoresIniciales;
  final Function(Map<String, dynamic>) onAplicar;
  final VoidCallback onRestablecer;
  final String titulo;

  const FiltrosGenericosMobile({
    Key? key,
    required this.configuraciones,
    required this.valoresIniciales,
    required this.onAplicar,
    required this.onRestablecer,
    this.titulo = 'Filtros',
  }) : super(key: key);

  @override
  _FiltrosGenericosMobileState createState() => _FiltrosGenericosMobileState();
}

class _FiltrosGenericosMobileState extends State<FiltrosGenericosMobile> {
  late Map<String, dynamic> _valores;

  @override
  void initState() {
    super.initState();
    _valores = Map<String, dynamic>.from(widget.valoresIniciales);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundDialog,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        //mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header con título y botón cerrar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.titulo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lista de filtros en grid 2x2
                  ..._construirFiltrosMobile(isDarkMode),
                ],
              ),
            ),
          ),

          // Botones de acción (fijos en la parte inferior)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.backgroundDialog,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[400]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _valores.clear();
                        });
                        widget.onRestablecer();
                      },
                      child: Text(
                        'Restablecer',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5162F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onAplicar(_valores);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Aplicar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // Construir filtros en grid de 2 columnas
  List<Widget> _construirFiltrosMobile(bool isDarkMode) {
    List<Widget> widgets = [];

    // Agrupar elementos de dos en dos
    for (int i = 0; i < widget.configuraciones.length; i += 2) {
      List<Widget> rowChildren = [];

      // Primer elemento de la fila
      rowChildren.add(
        Expanded(
          child: _construirDropdownFiltroMobile(
            widget.configuraciones[i],
            isDarkMode,
          ),
        ),
      );

      // Segundo elemento de la fila (si existe)
      if (i + 1 < widget.configuraciones.length) {
        rowChildren.add(const SizedBox(width: 16)); // Espacio entre columnas
        rowChildren.add(
          Expanded(
            child: _construirDropdownFiltroMobile(
              widget.configuraciones[i + 1],
              isDarkMode,
            ),
          ),
        );
      } else {
        // Si es impar, añadir espacio vacío para mantener el layout
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      // Crear la fila
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );

      // Añadir espacio vertical entre filas (excepto en la última)
      if (i + 2 < widget.configuraciones.length) {
        widgets.add(const SizedBox(height: 20));
      }
    }

    return widgets;
  }

  Widget _construirDropdownFiltroMobile(
    ConfiguracionFiltro config,
    bool isDarkMode,
  ) {
    final currentValue = _valores[config.clave] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _construirDropdownMobile(
          value: currentValue,
          hint: 'Seleccionar',
          items: config.opciones ?? [],
          isDarkMode: isDarkMode,
          onChanged: (value) {
            setState(() {
              _valores[config.clave] = value;
            });
          },
        ),
        if (currentValue != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _valores[config.clave] = null;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Limpiar',
                style: TextStyle(
                  color: Color(0xFF5162F6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _construirDropdownMobile({
    required String? value,
    required String hint,
    required List<String> items,
    required bool isDarkMode,
    required Function(String?) onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          isExpanded: true,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          iconStyleData: IconStyleData(
            icon: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.white60 : Colors.grey[600],
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
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }
}
