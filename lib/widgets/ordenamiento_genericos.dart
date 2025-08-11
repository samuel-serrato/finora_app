// widgets/ordenamiento_genericos.dart (o donde tengas OrdenamientoGenericoMobile)
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:finora_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TipoOrdenamiento {
  dropdown,
  rangoFechas,
  // Agregar más tipos según necesidad
}

class ConfiguracionOrdenamiento {
  final String clave;
  final String titulo;
  final TipoOrdenamiento tipo;
  List<String>? opciones; // Para dropdowns
  final DateTime? fechaInicial; // Para rangos de fechas
  final DateTime? fechaFinal; // Para rangos de fechas
  final String? hintText;

  ConfiguracionOrdenamiento({
    required this.clave,
    required this.titulo,
    required this.tipo,
    this.opciones,
    this.fechaInicial,
    this.fechaFinal,
    this.hintText,
  });

  // Método para crear una copia con opciones actualizadas
  ConfiguracionOrdenamiento copyWith({
    List<String>? opciones,
    String? hintText, // Añadido por si necesitas cambiar el hint también
  }) {
    return ConfiguracionOrdenamiento(
      clave: clave,
      titulo: titulo,
      tipo: tipo,
      opciones: opciones ?? this.opciones,
      fechaInicial: fechaInicial,
      fechaFinal: fechaFinal,
      hintText: hintText ?? this.hintText,
    );
  }
}

class OrdenamientoGenericoMobile extends StatefulWidget {
  final List<ConfiguracionOrdenamiento> configuraciones;
  final Map<String, dynamic> valoresIniciales;
  final Function(Map<String, dynamic>) onAplicar;
  final VoidCallback onRestablecer;
  final String titulo;
  final String textoBotonAplicar;
  final Function(String clave, dynamic valor)?
  onValorCambiado; // <--- NUEVO PARÁMETRO

  const OrdenamientoGenericoMobile({
    Key? key,
    required this.configuraciones,
    required this.valoresIniciales,
    required this.onAplicar,
    required this.onRestablecer,
    this.titulo = 'Ordenamiento',
    this.textoBotonAplicar = 'Aplicar',
    this.onValorCambiado, // <--- NUEVO PARÁMETRO
  }) : super(key: key);

  @override
  _OrdenamientoGenericoMobileState createState() =>
      _OrdenamientoGenericoMobileState();
}

class _OrdenamientoGenericoMobileState
    extends State<OrdenamientoGenericoMobile> {
  late Map<String, dynamic> _valores;
  late List<ConfiguracionOrdenamiento> _currentConfigs;

  static const String _expectedKeyForSortColumn = 'sort_by_column_config_key';
  static const String _expectedKeyForSortDirection =
      'sort_direction_config_key';

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _valores = Map<String, dynamic>.from(widget.valoresIniciales);
    // Crear copias de las configuraciones para poder modificarlas internamente si es necesario
    _currentConfigs = widget.configuraciones.map((c) => c.copyWith()).toList();

    // Asegurar valores iniciales válidos o nulos para hints
    for (var config in _currentConfigs) {
      final currentValue = _valores[config.clave];
      if (currentValue != null &&
          !(config.opciones?.contains(currentValue) ?? true)) {
        // Si el valor no es nulo y no está en las opciones, resetear
        _valores[config.clave] =
            (config.opciones?.isNotEmpty ?? false)
                ? config.opciones!.first
                : null;
      }
      // Si es null, se mantiene null para el hint.
    }
  }

  @override
  void didUpdateWidget(covariant OrdenamientoGenericoMobile oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool configsNeedUpdate = false;
    if (widget.configuraciones.length != _currentConfigs.length) {
      configsNeedUpdate = true;
    } else {
      for (int i = 0; i < widget.configuraciones.length; i++) {
        // Compara las opciones. Si las opciones del dropdown de dirección cambian, esto lo detectará.
        if (widget.configuraciones[i].opciones?.join(',') !=
            _currentConfigs[i].opciones?.join(',')) {
          configsNeedUpdate = true;
          break;
        }
      }
    }

    if (configsNeedUpdate) {
      _currentConfigs =
          widget.configuraciones.map((c) => c.copyWith()).toList();
    }

    // Si los valoresIniciales cambian desde el padre (StatefulBuilder), actualizamos _valores.
    // Esto es crucial para que el dropdown de dirección se resetee a null.
    if (widget.valoresIniciales[_expectedKeyForSortDirection] !=
            _valores[_expectedKeyForSortDirection] ||
        widget.valoresIniciales[_expectedKeyForSortColumn] !=
            _valores[_expectedKeyForSortColumn]) {
      setState(() {
        _valores = Map<String, dynamic>.from(widget.valoresIniciales);
        // Re-validar contra las opciones actuales después de tomar valores del padre
        for (var config in _currentConfigs) {
          final currentValue = _valores[config.clave];
          if (currentValue != null &&
              !(config.opciones?.contains(currentValue) ?? true)) {
            _valores[config.clave] =
                null; // Resetear a null para el hint si el valor no es válido
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      // ... (Decoración del Container principal - sin cambios)
      decoration: BoxDecoration(
        color: colors.backgroundDialog,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ... (Handle, Título, Divider - sin cambios)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [..._construirOpcionesOrdenamientoMobile(isDarkMode)],
              ),
            ),
          ),
          // ... (Botones de Restablecer y Aplicar - modificados para no cerrar el modal)
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
                        // Llama al callback onRestablecer del padre.
                        // El padre (StatefulBuilder) se encargará de actualizar
                        // el estado visual del modal si es necesario (pasando nuevos valoresIniciales y configuraciones)
                        // y también de la lógica de restablecimiento global.
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
                        // Navigator.of(context).pop(); // El padre se encarga de cerrar
                      },
                      child: Text(
                        widget.textoBotonAplicar,
                        style: const TextStyle(
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

  List<Widget> _construirOpcionesOrdenamientoMobile(bool isDarkMode) {
    List<Widget> widgets = [];
    for (int i = 0; i < _currentConfigs.length; i++) {
      // Usar _currentConfigs
      final config = _currentConfigs[i];
      if (config.tipo == TipoOrdenamiento.dropdown) {
        widgets.add(_construirDropdownOpcionMobile(config, isDarkMode));
      }
      if (i < _currentConfigs.length - 1) {
        widgets.add(const SizedBox(height: 20));
      }
    }
    return widgets;
  }

  Widget _construirDropdownOpcionMobile(
    ConfiguracionOrdenamiento config,
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
        ),
        const SizedBox(height: 12),
        _construirDropdownMobile(
          value: currentValue,
          hint: config.hintText ?? 'Seleccionar ${config.titulo.toLowerCase()}',
          items: config.opciones ?? [],
          isDarkMode: isDarkMode,
          onChanged: (value) {
            setState(() {
              _valores[config.clave] = value;

              // Si el campo de ordenamiento cambia a "Ninguno"
              if (config.clave == _expectedKeyForSortColumn &&
                  value == 'Ninguno') {
                if (_valores.containsKey(_expectedKeyForSortDirection)) {
                  _valores[_expectedKeyForSortDirection] =
                      null; // Resetear para mostrar hint
                }
              }
            });
            // Notificar al padre del cambio
            widget.onValorCambiado?.call(
              config.clave,
              value,
            ); // <--- LLAMADA AL CALLBACK
          },
        ),
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
    final String? validValue =
        (value != null && items.contains(value)) ? value : null;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      // ... (Estilos del Container y DropdownButton2 - sin cambios)
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
          value: validValue,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              fontSize: 14,
            ),
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
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          iconStyleData: IconStyleData(
            icon: Padding(
              padding: const EdgeInsets.only(right: 12),
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
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}
