// Archivo: lib/widgets/responsive_scaffold_list_view.dart

import 'dart:async';

import 'package:finora_app/providers/theme_provider.dart';
import 'package:finora_app/widgets/hoverableActionButton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Un widget de Scaffold genérico y reutilizable para mostrar listas de datos
/// de forma responsiva. Maneja la UI para búsqueda, filtros, ordenamiento,
/// layouts de grid/fila, y estados de carga, vacío y error.
class ResponsiveScaffoldListView<T> extends StatefulWidget {
  // --- CONFIGURACIÓN DE DATOS Y ESTADO ---
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasError;
  final bool noItemsFound;
  final int totalItems;
  final int currentPage;
  final int totalPages;

  // --- ¡NUEVOS PARÁMETROS DE ANIMACIÓN! ---
  final AnimationController animationController;
  final Animation<double> fadeAnimation;

  // --- BUILDERS PARA LAS TARJETAS ---
  /// Construye el widget para una tarjeta en la vista de grid estándar.
  final Widget Function(BuildContext context, T item) cardBuilder;

  /// Construye el widget para una tarjeta en la vista de fila (desktop, 1 columna).
  final Widget Function(BuildContext context, T item) tableRowCardBuilder;

  // --- CALLBACKS PARA ACCIONES ---
  final Future<void> Function() onRefresh;
  final void Function() onLoadMore;
  final void Function() onAddItem;
  final void Function(String query) onSearchChanged;
  final ScrollController scrollController;

  // --- WIDGETS DE LA BARRA DE ACCIONES ---
  /// El botón de filtros, construido en la pantalla padre.
  final Widget? filterButton;

  /// El botón de ordenamiento, construido en la pantalla padre.
  final Widget sortButton;

  // --- ¡NUEVO PARÁMETRO! ---
  /// Un widget opcional para mostrar en la barra de acciones, como una fila de chips de filtro.
  final Widget? actionBarContent;

  // --- ALTURA DE LA TARJETA (opcional pero recomendado) ---
  final double cardHeight;

  // --- TEXTOS PERSONALIZABLES ---
  final String appBarTitle;
  final String searchHintText;
  final String addItemText;
  final String loadingText;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final IconData emptyStateIcon;

  // --- ¡AÑADE ESTA LÍNEA! ---
  final Object? fabHeroTag; // Usamos Object? para permitir null

  const ResponsiveScaffoldListView({
    super.key,
    // Datos y estado
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasError,
    required this.noItemsFound,
    required this.totalItems,
    required this.currentPage,
    required this.totalPages,
    // Builders
    required this.cardBuilder,
    required this.tableRowCardBuilder,
    // Callbacks
    required this.onRefresh,
    required this.onLoadMore,
    required this.onAddItem,
    required this.onSearchChanged,
    required this.scrollController,
    // Action Bar
    this.filterButton,
    required this.sortButton,
    // Textos
    this.appBarTitle = '',
    this.searchHintText = 'Buscar...',
    this.addItemText = 'Agregar',
    this.loadingText = 'Cargando...',
    this.emptyStateTitle = 'No se encontraron resultados',
    this.emptyStateSubtitle = 'Aún no hay elementos registrados.',
    this.emptyStateIcon = Icons.inbox_rounded,
    // --- ¡AÑADE LOS NUEVOS PARÁMETROS AQUÍ! ---
    this.actionBarContent,
    this.cardHeight = 220, // Altura por defecto para las tarjetas verticales
    // --- ¡AÑADE LOS NUEVOS PARÁMETROS AQUÍ! ---
    required this.animationController,
    required this.fadeAnimation,
    // --- ¡AÑADE ESTA LÍNEA AL CONSTRUCTOR! ---
    this.fabHeroTag,
  });

  @override
  _ResponsiveScaffoldListViewState<T> createState() =>
      _ResponsiveScaffoldListViewState<T>();
}

class _ResponsiveScaffoldListViewState<T>
    extends State<ResponsiveScaffoldListView<T>> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  int? _userSelectedCrossAxisCount; // null = auto, 1, 2, 3...
  static const double mobileLayoutBreakpoint = 750.0;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (el método build principal se mantiene casi igual)
    // Solo asegúrate de que el AppBar tenga suficiente altura.
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopLayout =
            constraints.maxWidth > mobileLayoutBreakpoint;

        return Scaffold(
          backgroundColor: colors.backgroundPrimary,
          appBar: AppBar(
            // El título es opcional. Si no lo quieres, puedes quitar esta línea.
            // title: Text(widget.appBarTitle),
            backgroundColor: colors.backgroundPrimary,
            surfaceTintColor: colors.backgroundPrimary,
            elevation: 1.0,
            shadowColor: Colors.black.withOpacity(0.1),
            // Ajustamos la altura para dar espacio a todos los filtros
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                80.0,
              ), // Aumentamos la altura
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilters(context, colors, isDesktopLayout),
                  _buildResultsCountInfo(colors),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: Colors.blue,
            backgroundColor: colors.backgroundCard,
            child: _buildContent(context, colors, isDesktopLayout),
          ),
          floatingActionButton:
              isDesktopLayout ? null : _buildModernFAB(colors),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic colors,
    bool isDesktopLayout,
  ) {
    // --- 1. GESTIÓN DE ESTADOS INICIALES ---

    // Muestra el spinner de carga si es la primera carga y la lista está vacía.
    if (widget.isLoading && widget.items.isEmpty) {
      return Center(child: _buildModernLoading());
    }

    // Muestra el estado de error si hubo un problema y la lista está vacía.
    if (widget.hasError && widget.items.isEmpty) {
      return _buildErrorState(context);
    }

    // Muestra el estado vacío si la búsqueda no arrojó resultados o no hay datos.
    if (widget.noItemsFound || (widget.items.isEmpty && !widget.isLoading)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildEmptyState(),
            ),
          );
        },
      );
    }

    // --- 2. FUNCIÓN DE AYUDA PARA LA ANIMACIÓN ---

    // Esta función envuelve cualquier widget `child` con las animaciones.
    Widget _buildAnimatedItem(Widget child, int index, int totalItems) {
      return FadeTransition(
        opacity: widget.fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1), // Empieza ligeramente abajo
            end: Offset.zero, // Termina en su posición normal
          ).animate(
            CurvedAnimation(
              parent: widget.animationController,
              // El `Interval` crea el efecto escalonado (staggered)
              curve: Interval(
                (index / (totalItems == 0 ? 1 : totalItems)) * 0.5,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: child,
        ),
      );
    }

    // --- 3. LÓGICA DE LAYOUT RESPONSIVO ---

    // Obtenemos el ancho de la pantalla para decidir el número de columnas.
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    // Si el usuario seleccionó un número de columnas en desktop, lo usamos.
    if (isDesktopLayout && _userSelectedCrossAxisCount != null) {
      crossAxisCount = _userSelectedCrossAxisCount!;
      // Si no, lo calculamos automáticamente para desktop.
    } else if (isDesktopLayout) {
      const double cardIdealWidth = 380.0; // Ancho ideal de una tarjeta
      crossAxisCount = (screenWidth / cardIdealWidth).floor();
      if (crossAxisCount == 0) crossAxisCount = 1;
      // En móvil, siempre es una columna.
    } else {
      crossAxisCount = 1;
    }

    // Determinamos si debemos usar el layout de fila (tabla).
    final bool useTableRowLayout = isDesktopLayout && crossAxisCount == 1;

    // --- 4. CONSTRUCCIÓN DEL LISTADO ---

    // Si es layout de fila (tabla), usamos ListView.builder.
    if (useTableRowLayout) {
      return ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Muestra el spinner al final si se están cargando más items.
          if (index == widget.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = widget.items[index];
          // Construimos la tarjeta para la fila.
          final card = Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: widget.tableRowCardBuilder(context, item),
          );
          // La envolvemos en la animación.
          return _buildAnimatedItem(card, index, widget.items.length);
        },
      );
    }

    // Si es layout de grid, usamos GridView.builder.
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        mainAxisExtent: widget.cardHeight, // Altura fija para las tarjetas
      ),
      itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Muestra el spinner al final.
        if (index == widget.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = widget.items[index];
        // Construimos la tarjeta para el grid.
        final card = widget.cardBuilder(context, item);
        // La envolvemos en la animación.
        return _buildAnimatedItem(card, index, widget.items.length);
      },
    );
  }

  // --- Widgets de la Barra de Acciones ---

  // --- MÉTODO ACTUALIZADO PARA _buildSearchAndFilters ---
  // REEMPLAZA TU MÉTODO _buildSearchAndFilters POR ESTE:
  // REEMPLAZA TU MÉTODO _buildSearchAndFilters POR ESTA VERSIÓN FINAL:
  // Archivo: lib/widgets/responsive_scaffold_list_view.dart

  // ... (dentro de la clase _ResponsiveScaffoldListViewState)

  // REEMPLAZA TU MÉTODO _buildSearchAndFilters POR ESTA VERSIÓN DEFINITIVA:
  Widget _buildSearchAndFilters(
    BuildContext context,
    dynamic colors,
    bool isDesktopLayout,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: colors.backgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de búsqueda
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.searchHintText,
                hintStyle: TextStyle(
                  color: colors.textSecondary.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textSecondary.withOpacity(0.7),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: colors.textSecondary.withOpacity(0.7),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 700), () {
                  widget.onSearchChanged(value);
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. Fila ÚNICA de acciones
          // 2. Fila ÚNICA de acciones
          Row(
            children: [
              // ▼▼▼ VERSIÓN MÁS LIMPIA DE LA CORRECCIÓN ▼▼▼
              if (widget.filterButton != null) ...[
                widget.filterButton!,
                const SizedBox(width: 8),
              ],

              widget.sortButton,
              if (isDesktopLayout) ...[
                const SizedBox(width: 8),
                // Así se usa el nuevo widget
                LayoutControlButton(
                  userSelectedCrossAxisCount: _userSelectedCrossAxisCount,
                  onLayoutSelected: (int value) {
                    setState(() {
                      _userSelectedCrossAxisCount = (value == 0) ? null : value;
                    });
                  },
                  // Pasamos la función que construye los items
                  itemBuilder:
                      (context, colors) => [
                        _buildPopupMenuItem(
                          1,
                          '1 Columna',
                          Icons.view_list_rounded,
                          colors,
                        ),
                        _buildPopupMenuItem(
                          2,
                          '2 Columnas',
                          Icons.grid_view_rounded,
                          colors,
                        ),
                        _buildPopupMenuItem(
                          3,
                          '3 Columnas',
                          Icons.view_quilt_rounded,
                          colors,
                        ),
                        const PopupMenuDivider(),
                        _buildPopupMenuItem(
                          0,
                          'Automático',
                          Icons.dynamic_feed_rounded,
                          colors,
                        ),
                      ],
                ),
              ],

              // Contenido del medio (los chips), que se expande
              Expanded(
                child:
                    widget.actionBarContent != null
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: widget.actionBarContent!,
                        )
                        : const SizedBox(),
              ),

              // Botón de "Agregar" a la derecha (solo en desktop)
              if (isDesktopLayout) _buildAddButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    return ElevatedButton.icon(
      onPressed: widget.onAddItem,
      //icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(widget.addItemText),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.backgroundButton,
        foregroundColor: colors.whiteWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 2,
      ),
    );
  }

  /* Widget _buildLayoutControlButton(BuildContext context, dynamic colors) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    IconData iconData;
    if (_userSelectedCrossAxisCount == null ||
        _userSelectedCrossAxisCount! > 1) {
      iconData = Icons.grid_view_rounded;
    } else {
      iconData = Icons.view_list_rounded;
    }

    return PopupMenuButton<int>(
      onSelected: (int value) {
        setState(() {
          _userSelectedCrossAxisCount = (value == 0) ? null : value;
        });
      },
      color: colors.backgroundPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Cambiar vista',

      // La magia está aquí: el child del PopupMenuButton es nuestro HoverableContainer
      child: HoverableActionButton(
        child: Icon(
          iconData,
          size: 22,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),

      // El itemBuilder se mantiene exactamente igual
      itemBuilder:
          (context) => [
            _buildPopupMenuItem(
              1,
              '1 Columna (Fila)',
              Icons.view_list_rounded,
              colors,
            ),
            _buildPopupMenuItem(
              2,
              '2 Columnas',
              Icons.grid_view_rounded,
              colors,
            ),
            _buildPopupMenuItem(
              3,
              '3 Columnas',
              Icons.view_quilt_rounded,
              colors,
            ),
            const PopupMenuDivider(),
            _buildPopupMenuItem(
              0,
              'Automático',
              Icons.dynamic_feed_rounded,
              colors,
            ),
          ],
    );
  } */

  PopupMenuItem<int> _buildPopupMenuItem(
    int value,
    String text,
    IconData icon,
    dynamic colors,
  ) {
    final bool isSelected =
        (_userSelectedCrossAxisCount == value) ||
        (_userSelectedCrossAxisCount == null && value == 0);
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blueAccent : colors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : colors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB(dynamic colors) {
    return FloatingActionButton(
      heroTag: widget.fabHeroTag, // <--- ¡CAMBIO IMPORTANTE!
      onPressed: widget.onAddItem,
      child: const Icon(Icons.add_rounded),
      backgroundColor: colors.backgroundButton,
      foregroundColor: colors.whiteWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // --- Widgets de Estado ---

  Widget _buildResultsCountInfo(dynamic colors) {
    String textoAMostrar;
    if (widget.isLoading) {
      textoAMostrar = widget.loadingText;
    } else if (widget.hasError) {
      textoAMostrar = 'Error al cargar';
    } else if (widget.noItemsFound) {
      textoAMostrar = widget.emptyStateTitle;
    } else {
      textoAMostrar =
          'Mostrando ${widget.items.length} de ${widget.totalItems}';
    }

    return Container(
      height: 25,
      padding: const EdgeInsets.only(left: 18.0, right: 16.0, bottom: 10.0),
      child: Text(
        textoAMostrar,
        style: TextStyle(
          color: colors.textSecondary.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 20),
        Text(
          widget.loadingText,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.emptyStateIcon, size: 60, color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        Text(
          widget.emptyStateTitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.emptyStateSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildErrorState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.wifi_off_rounded, size: 60, color: Colors.red[400]),
        ),
        const SizedBox(height: 24),
        Text(
          'Error de conexión',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class LayoutControlButton extends StatefulWidget {
  final int? userSelectedCrossAxisCount;
  final Function(int) onLayoutSelected;
  // Pasamos la función que construye los items del menú para mantener el código limpio
  final List<PopupMenuEntry<int>> Function(BuildContext, dynamic) itemBuilder;

  const LayoutControlButton({
    super.key,
    required this.userSelectedCrossAxisCount,
    required this.onLayoutSelected,
    required this.itemBuilder,
  });

  @override
  _LayoutControlButtonState createState() => _LayoutControlButtonState();
}

class _LayoutControlButtonState extends State<LayoutControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDarkMode = themeProvider.isDarkMode;

    // Lógica del ícono
    IconData iconData;
    if (widget.userSelectedCrossAxisCount == null ||
        widget.userSelectedCrossAxisCount! > 1) {
      iconData = Icons.grid_view_rounded;
    } else {
      iconData = Icons.view_list_rounded;
    }

    // Lógica de colores del hover
    final Color backgroundColor =
        _isHovered
            ? (isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200)
            : colors.backgroundCard;

    final Color borderColor =
        (isDarkMode ? Colors.grey[700]! : Colors.grey.withOpacity(0.3));

    return PopupMenuButton<int>(
      offset: const Offset(0, 35),
      onSelected: widget.onLayoutSelected,
      color: colors.backgroundPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //tooltip: 'Cambiar vista',
      tooltip: '',

      // El child es el que maneja el hover
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor,
              width: _isHovered ? 1.3 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(
                  _isHovered ? 0.15 : 0.1,
                ),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Icon(
            iconData,
            size: 22,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
      // Usamos la función que nos pasaron para construir los items
      itemBuilder: (context) => widget.itemBuilder(context, colors),
    );
  }
}
