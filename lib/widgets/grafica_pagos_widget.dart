import 'dart:math';

import 'package:finora_app/constants/colors.dart';
import 'package:finora_app/models/grafica_data.dart';
import 'package:finora_app/services/grafica_service.dart';
import 'package:finora_app/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GraficaPagosWidget extends StatefulWidget {
  final AppColors colors;
  const GraficaPagosWidget({Key? key, required this.colors}) : super(key: key);

  @override
  State<GraficaPagosWidget> createState() => _GraficaPagosWidgetState();
}

class _GraficaPagosWidgetState extends State<GraficaPagosWidget> {
  final GraficaService _graficaService = GraficaService();
  GraficaView _currentView = GraficaView.mensual;
  DateTime _currentDate = DateTime.now();

  GraficaResponse? _graficaData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFetching = false; // <-- AÑADE ESTA LÍNEA

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return; // Tu bloqueo, que está perfecto.
    if (!mounted) return;

    // 1. Inicia el estado de carga en un solo setState
    setState(() {
      _isLoading = true;
      _isFetching = true; // Marcamos el bloqueo
      _errorMessage = null;
    });

    try {
      final data = await _graficaService.getGraficaData(
        _currentView,
        _currentDate,
      );
      if (!mounted) return;

      // 2. Estado de éxito: Actualiza todo en un solo setState
      setState(() {
        _graficaData = data;
        _isLoading = false;
        _isFetching = false; // Liberamos el bloqueo aquí
      });
    } catch (e) {
  if (!mounted) return;

  final errorMessageString = e.toString().replaceFirst("Exception: ", "");

  // >>> INICIO DEL CAMBIO IMPORTANTE <<<
  // Verificamos si el error es en realidad un mensaje de "estado vacío".
  // Puedes ajustar el texto si el mensaje del servidor es ligeramente diferente.
  if (errorMessageString.contains("No hay reportes de pagos") || 
      errorMessageString.contains("No hay datos para este período")) {
        
    // Si es así, lo tratamos como un éxito con datos vacíos.
    setState(() {
      // Creamos una respuesta vacía para que la UI construya el esqueleto.
      _graficaData = GraficaResponse(sumaTotal: 0, sumaTotalIdeal: 0, puntos: []); 
      _isLoading = false;
      _isFetching = false;
      _errorMessage = null; // MUY IMPORTANTE: nos aseguramos de que no haya mensaje de error.
    });

  } else {
    // Si es cualquier otro error (sin conexión, error del servidor, etc.),
    // entonces sí lo mostramos como un error real.
    setState(() {
      _errorMessage = errorMessageString;
      _isLoading = false;
      _isFetching = false;
    });
  }
  // >>> FIN DEL CAMBIO <<<
}
  }

  void _navigate(int direction) {
    if (_isFetching) return; // <-- AÑADE ESTA LÍNEA
    setState(() {
      switch (_currentView) {
        case GraficaView.semanal:
          _currentDate = _currentDate.add(Duration(days: 7 * direction));
          break;
        case GraficaView.mensual:
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month + direction,
            _currentDate.day,
          );
          break;
        case GraficaView.anual:
          _currentDate = DateTime(
            _currentDate.year + direction,
            _currentDate.month,
            _currentDate.day,
          );
          break;
      }
    });
    _fetchData();
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case GraficaView.semanal:
        // Verificamos si ya tenemos datos del servidor.
        // Si no hay datos, mostramos un título genérico mientras carga.
        if (_graficaData == null || _graficaData!.puntos.isEmpty) {
          return 'Cargando semana...';
        }

        try {
          // Tomamos la fecha del primer y último día de la semana desde los datos.
          final String fechaInicioStr = _graficaData!.puntos.first.periodo;
          final String fechaFinStr = _graficaData!.puntos.last.periodo;

          // Convertimos los strings a objetos DateTime.
          // Usamos .split(' - ').first por si el formato llegara a cambiar,
          // asegurando que solo tomamos la fecha de inicio.
          final DateTime fechaInicio = DateTime.parse(
            fechaInicioStr.split(' - ').first,
          );
          final DateTime fechaFin = DateTime.parse(
            fechaFinStr.split(' - ').first,
          );

          // Formateamos las fechas para mostrarlas.
          final String formatoInicio = DateFormat(
            'd MMM',
            'es_ES',
          ).format(fechaInicio);
          final String formatoFin = DateFormat(
            'd MMM yyyy',
            'es_ES',
          ).format(fechaFin);

          // Devolvemos el título final construido con los datos reales.
          return 'Semana del $formatoInicio al $formatoFin';
        } catch (e) {
          // Si ocurre un error al procesar las fechas (muy improbable),
          // mostramos un mensaje de error para no bloquear la app.
          print('Error al formatear las fechas de la semana: $e');
          return 'Semana con datos inválidos';
        }

      case GraficaView.mensual:
        return DateFormat('MMMM yyyy', 'es_ES').format(_currentDate);
      case GraficaView.anual:
        return 'Año ${DateFormat('yyyy', 'es_ES').format(_currentDate)}';
    }
  }

  /// Formatea un número para el eje Y de forma abreviada (ej: 1.5k, 2M).
  String _formatYAxisLabel(double value) {
    if (value >= 1000000) {
      final double result = value / 1000000;
      // Remueve el .0 si no hay decimales (ej: 2.0M -> 2M)
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}M';
    } else if (value >= 1000) {
      final double result = value / 1000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
    } else {
      return value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El resto del build se mantiene igual)
    return Card(
      // <<< ¡AÑADE ESTA LÍNEA AQUÍ! >>>
      // Esto permite que el tooltip se "salga" de los bordes del Card.
      clipBehavior: Clip.none,
      surfaceTintColor: widget.colors.backgroundCard,
      color: widget.colors.backgroundCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildViewSelector(),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildChartContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;
    final bool isSmallScreen2 = size.width < 800;

    return Column(
      children: [
        // --- Fila de navegación (sin cambios) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _navigate(-1),
            ),
            Flexible(
              child: Text(
                _getHeaderTitle(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _navigate(1),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // <<< CAMBIO PRINCIPAL AQUÍ: MOSTRAMOS AMBOS TOTALES >>>
        // Usamos una Fila para ponerlos uno al lado del otro
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // --- Columna para el Total Recaudado ---
            Column(
              children: [
                Text(
                  "Total Recaudado",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 12,
                    color: widget.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(_graficaData?.sumaTotal ?? 0),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green, // Usamos el color verde consistente
                  ),
                ),
              ],
            ),

            // --- Columna para el Total Ideal ---
           /*  Column(
              children: [
                Text(
                  "Total Ideal",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 12,
                    color: widget.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(
                    _graficaData?.sumaTotalIdeal ?? 0,
                  ), // Usamos el nuevo dato
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.withOpacity(
                      0.9,
                    ), // Color azul para el ideal
                  ),
                ),
              ],
            ), */
          ],
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    // ... (Sin cambios)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          GraficaView.values.map((view) {
            final isSelected = _currentView == view;
            return GestureDetector(
              onTap: () {
                if (_isFetching) return; // <-- AÑADE ESTA LÍNEA
                setState(() => _currentView = view);
                _fetchData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary
                          : widget.colors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  view.name[0].toUpperCase() + view.name.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isSelected ? Colors.white : widget.colors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

 Widget _buildChartContent() {
  if (_isLoading) {
    return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
  }
  if (_errorMessage != null) {
    return Center(key: const ValueKey('error'), child: Text(_errorMessage!));
  }

  final bool isEmpty = _graficaData == null || _graficaData!.puntos.isEmpty;

  // <<< INICIO DE LA LÓGICA RESPONSIVA >>>
  // 1. Obtenemos el ancho de la pantalla del dispositivo.
  final screenWidth = MediaQuery.of(context).size.width;

  // 2. Decidimos un "punto de corte". Si la pantalla es más estrecha que esto,
  //    consideramos que es "pequeña" (móvil). Puedes ajustar el valor 450 si es necesario.
  final bool isSmallScreen = screenWidth < 450;

  // 3. Definimos los tamaños de los elementos de forma condicional.
  final double iconSize = isSmallScreen ? 48 : 60;
  final double titleFontSize = isSmallScreen ? 15 : 18;
  final double subtitleFontSize = isSmallScreen ? 12 : 14;
  final double verticalSpacing = isSmallScreen ? 12 : 16;
  // <<< FIN DE LA LÓGICA RESPONSIVA >>>

  return Stack(
    alignment: Alignment.center,
    children: [
      // 1. La gráfica (se mantiene igual, siempre se dibuja)
      Padding(
        key: ValueKey('${_currentView.name}-${_currentDate.toIso8601String()}'),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: LineChart(_buildLineChartData()),
      ),

      // 2. El mensaje de estado vacío (ahora con estilos adaptativos)
      if (isEmpty)
        // Añadimos un Padding para que el texto nunca toque los bordes laterales
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: iconSize, // <-- Usamos el tamaño adaptativo
                color: widget.colors.textSecondary.withOpacity(0.5),
              ),
              SizedBox(height: verticalSpacing), // <-- Usamos el espaciado adaptativo
              Text(
                "Aún no hay reportes",
                textAlign: TextAlign.center, // Es buena práctica centrar el texto
                style: TextStyle(
                  fontSize: titleFontSize, // <-- Usamos el tamaño de fuente adaptativo
                  fontWeight: FontWeight.bold,
                  color: widget.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Los datos de tus pagos aparecerán aquí.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleFontSize, // <-- Usamos el tamaño de fuente adaptativo
                  color: widget.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

  /// Calcula un límite superior y un intervalo "redondos" para el eje Y.
  /// Esto evita etiquetas con números extraños como "96.3k".
  /// Calcula un límite superior y un intervalo "redondos" para el eje Y.
  /// Esto evita etiquetas con números extraños como "96.3k".
  Map<String, double> _calculateAxisBounds(
    double dataMax, {
    int tickCount = 5,
  }) {
    // <-- ¡EL ÚNICO CAMBIO ESTÁ AQUÍ!
    if (dataMax <= 0) {
      // Valor por defecto si no hay datos o son negativos.
      return {'max': 1000, 'interval': 250};
    }

    // 1. Calcula un intervalo crudo.
    final double roughInterval = dataMax / tickCount;

    // 2. Calcula el orden de magnitud (10, 100, 1000...).
    final double magnitude =
        pow(10, (log(roughInterval) / ln10).floor()).toDouble();

    // 3. Normaliza el intervalo y lo redondea al "buen" número más cercano (1, 2, 5).
    final double residual = roughInterval / magnitude;
    double niceInterval;
    if (residual > 5) {
      niceInterval = 10 * magnitude;
    } else if (residual > 2) {
      niceInterval = 5 * magnitude;
    } else if (residual > 1) {
      niceInterval = 2 * magnitude;
    } else {
      niceInterval = 1 * magnitude;
    }

    // 4. Calcula el nuevo valor máximo como el múltiplo del intervalo "bonito"
    // que sea mayor o igual al máximo de los datos.
    final double niceMax = (dataMax / niceInterval).ceil() * niceInterval;

    return {'max': niceMax, 'interval': niceInterval};
  }

  LineChartData _buildLineChartData() {
  final puntos = _graficaData?.puntos ?? [];
  final bool isEmpty = puntos.isEmpty;

  // 1. Definimos las variables que cambiarán dependiendo de si hay datos o no
  double finalMaxY;
  double finalIntervalY;
  double finalMaxX;
  List<FlSpot> spots;
  Map<int, String> bottomTitles;

  if (isEmpty) {
    // --- CONFIGURACIÓN PARA LA GRÁFICA VACÍA ---
    finalMaxY = 1000;
    finalIntervalY = 250;
    finalMaxX = 6; // Dibuja 7 puntos en el eje X (de 0 a 6) para dar espacio
    spots = [];   // La lista de puntos de la línea está vacía
    
    // Títulos vacíos para el eje X para que no muestre números
    bottomTitles = { 0: '', 1: '', 2: '', 3: '', 4: '', 5: '', 6: '' };

  } else {
    // --- CONFIGURACIÓN CUANDO SÍ HAY DATOS (tu lógica original) ---
    double maxVal = 0;
    for (var p in puntos) {
      if (p.totalPago > maxVal) maxVal = p.totalPago;
    }

    final bounds = _calculateAxisBounds(maxVal);
    finalMaxY = bounds['max']!;
    finalIntervalY = bounds['interval']!;
    finalMaxX = (puntos.length - 1).toDouble();
    spots = List.generate(puntos.length, (i) {
      return FlSpot(i.toDouble(), puntos[i].totalPago);
    });
    bottomTitles = {}; // Los títulos se generarán dinámicamente más abajo
  }

  // 2. Construimos el LineChartData UNA SOLA VEZ, usando las variables definidas arriba
  //    Esto garantiza que el estilo es idéntico en ambos casos.
  return LineChartData(
    clipData: const FlClipData.none(),
    borderData: FlBorderData(show: false),
    
    // --- ESTILO DE LA CUADRÍCULA (AHORA UNIFICADO) ---
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      verticalInterval: 1,
      getDrawingVerticalLine: (value) => FlLine(
        color: widget.colors.textSecondary.withOpacity(0.1),
        strokeWidth: 1,
        dashArray: [3, 4], // Estilo de línea punteada
      ),
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (value) => FlLine(
        color: widget.colors.textSecondary.withOpacity(0.1),
        strokeWidth: 1,
      ),
    ),

    // --- LÍMITES DE LOS EJES (DINÁMICOS) ---
    minX: 0,
    minY: 0,
    maxX: finalMaxX,
    maxY: finalMaxY,

    // --- TÍTULOS DE LOS EJES (CON LÓGICA PARA AMBOS CASOS) ---
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: finalIntervalY,
          getTitlesWidget: (value, meta) {
            if (value == finalMaxY || value == 0) {
              return const SizedBox.shrink();
            }
            // Usa tu formateador de "k" y "M" en ambos casos
            return Text(
              _formatYAxisLabel(value),
              style: TextStyle(color: widget.colors.textSecondary, fontSize: 10),
              textAlign: TextAlign.left,
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTitlesWidget: (value, meta) {
            String text;
            if (isEmpty) {
              // Si la gráfica está vacía, usamos los títulos en blanco
              text = bottomTitles[value.toInt()] ?? '';
            } else {
              // Si hay datos, usamos tu lógica original para obtener el nombre del período
              final index = value.toInt();
              if (index < 0 || index >= puntos.length) {
                return const SizedBox.shrink();
              }
              final puntoActual = puntos[index];
              text = _getTranslatedPeriodName(puntoActual, _currentView);
              text = text[0].toUpperCase() + text.substring(1);

              if (_currentView == GraficaView.anual || _currentView == GraficaView.semanal) {
                text = text.substring(0, 3);
              }
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 4,
              child: Text(
                text,
                style: TextStyle(color: widget.colors.textSecondary, fontSize: 10),
              ),
            );
          },
        ),
      ),
    ),
    
    // --- DATOS DE LA LÍNEA Y SU ESTILO ---
    lineBarsData: [
      LineChartBarData(
        spots: spots, // << Usa la lista de spots que puede estar vacía
        isCurved: true,
        gradient: LinearGradient(
          colors: [
            widget.colors.colorRecaudado,
            widget.colors.colorRecaudado.withOpacity(0.8),
          ],
        ),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: !isEmpty), // Oculta los puntos si la gráfica está vacía
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              widget.colors.colorRecaudado.withOpacity(0.2),
              widget.colors.colorRecaudado.withOpacity(0.5),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
    ],

    // --- TOOLTIPS (Se mantiene igual, solo se activa si hay datos) ---
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (spot) => widget.colors.tooltipBackground,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tooltipBorder: const BorderSide(color: Colors.transparent),
        tooltipRoundedRadius: 8,
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          if (touchedSpots.isEmpty) return [];

          final spotIndex = touchedSpots.first.spotIndex;
          final punto = puntos[spotIndex];
          final nombrePeriodo = _getTranslatedPeriodName(punto, _currentView);
          final headerText = '${nombrePeriodo[0].toUpperCase()}${nombrePeriodo.substring(1)}';
          final periodoFormateado = _formatPeriodoForTooltip(punto, _currentView);

          final children = <TextSpan>[];
          children.add(
            TextSpan(
              text: headerText,
              style: TextStyle(
                color: widget.colors.tooltipTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );

          if (periodoFormateado.isNotEmpty) {
            children.add(
              TextSpan(
                text: '\n$periodoFormateado',
                style: TextStyle(
                  color: widget.colors.tooltipTextSecondary,
                  fontWeight: FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            );
          }
          children.add(const TextSpan(text: '\n', style: TextStyle(fontSize: 10)));
          children.add(
            TextSpan(
              text: 'Recaudado:\n',
              style: TextStyle(color: widget.colors.colorRecaudadoText, fontSize: 12),
            ),
          );
          children.add(
            TextSpan(
              text: formatCurrency(punto.totalPago),
              style: TextStyle(
                color: widget.colors.colorRecaudadoText,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );

          return touchedSpots.map((touchedSpot) {
            if (touchedSpot == touchedSpots.first) {
              return LineTooltipItem(
                '',
                const TextStyle(fontSize: 0),
                children: children,
                textAlign: TextAlign.left,
              );
            }
            return LineTooltipItem('', const TextStyle(fontSize: 0));
          }).toList();
        },
      ),
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            const FlLine(color: Colors.transparent),
            FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 8,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: widget.colors.backgroundCard,
                );
              },
            ),
          );
        }).toList();
      },
    ),
  );
}

  // <<< ESTA ES LA NUEVA FUNCIÓN AUXILIAR >>>
  /// Formatea el string del período para mostrarlo de forma amigable en el tooltip.
  String _formatPeriodoForTooltip(GraficaPunto punto, GraficaView view) {
    // Para la vista anual, el nombre del mes ya es suficiente, no añadimos nada.
    if (view == GraficaView.anual) {
      return '';
    }

    try {
      // El período puede ser una fecha única o un rango separado por " - ".
      final parts = punto.periodo.split(' - ');
      final startDateString = parts[0];
      final startDate = DateTime.parse(startDateString);

      if (view == GraficaView.semanal) {
        // Para la vista semanal, solo mostramos la fecha del día.
        // Ej: "28 ago 2025"
        return DateFormat('d MMM yyyy', 'es_ES').format(startDate);
      }

      if (view == GraficaView.mensual && parts.length > 1) {
        // Para la vista mensual, formateamos el rango.
        // Ej: "26 ago - 1 sep"
        final endDateString = parts[1];
        final endDate = DateTime.parse(endDateString);
        final startFormat = DateFormat('d MMM', 'es_ES').format(startDate);
        final endFormat = DateFormat('d MMM', 'es_ES').format(endDate);
        return '$startFormat - $endFormat';
      }

      // Si no es un caso conocido, no mostramos nada.
      return '';
    } catch (e) {
      // Si hay un error al parsear la fecha, no mostramos nada para evitar crasheos.
      print('Error al formatear período para tooltip: $e');
      return '';
    }
  }

  String _getTranslatedPeriodName(GraficaPunto punto, GraficaView view) {
    if (view == GraficaView.mensual) {
      return "Sem ${punto.nombrePeriodo}"; // Añadimos "Semana" para más claridad
    }

    try {
      final dateString = punto.periodo.split(' - ')[0];
      final dateTime = DateTime.parse(dateString);

      switch (view) {
        case GraficaView.anual:
          return DateFormat('MMMM', 'es_ES').format(dateTime);
        case GraficaView.semanal:
          return DateFormat('EEEE', 'es_ES').format(dateTime);
        case GraficaView.mensual:
          return punto.nombrePeriodo;
      }
    } catch (e) {
      print('Error al parsear la fecha: $e');
      return punto.nombrePeriodo;
    }
  }
}
