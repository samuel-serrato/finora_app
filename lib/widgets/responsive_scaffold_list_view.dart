// Archivo: lib/widgets/responsive_scaffold_list_view.dart

import 'dart:async';
import 'package:finora_app/providers/theme_provider.dart';
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

  // --- ANIMACIÓN ---
  final AnimationController animationController;
  final Animation<double> fadeAnimation;

  // --- BUILDERS PARA LAS TARJETAS ---
  final Widget Function(BuildContext context, T item) cardBuilder;
  final Widget Function(BuildContext context, T item) tableRowCardBuilder;

  // --- CALLBACKS PARA ACCIONES ---
  final Future<void> Function() onRefresh;
  final void Function() onLoadMore;
  final void Function() onAddItem;
  final void Function(String query) onSearchChanged;
  final ScrollController scrollController;

  // --- WIDGETS DE LA BARRA DE ACCIONES ---
  final Widget? filterButton;
  final Widget sortButton;
  final Widget? actionBarContent;
  
  // --- PARÁMETROS PARA EL LAYOUT (RECIBIDOS DEL PADRE) ---
  /// El número de columnas seleccionado globalmente (viene del UiProvider a través del padre).
  final int? userSelectedCrossAxisCount;
  /// El botón que controla el cambio de vista (construido en el padre, idealmente con GlobalLayoutButton).
  final Widget? layoutControlButton;

  // --- CONFIGURACIÓN VISUAL ---
  final double cardHeight;
  final String appBarTitle;
  final String searchHintText;
  final String addItemText;
  final String loadingText;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final IconData emptyStateIcon;
  final Object? fabHeroTag;

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
    this.actionBarContent,
    this.userSelectedCrossAxisCount,
    this.layoutControlButton,
    // Textos y Configuración
    this.appBarTitle = '',
    this.searchHintText = 'Buscar...',
    this.addItemText = 'Agregar',
    this.loadingText = 'Cargando...',
    this.emptyStateTitle = 'No se encontraron resultados',
    this.emptyStateSubtitle = 'Aún no hay elementos registrados.',
    this.emptyStateIcon = Icons.inbox_rounded,
    this.cardHeight = 220,
    required this.animationController,
    required this.fadeAnimation,
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
  static const double mobileLayoutBreakpoint = 750.0;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopLayout =
            constraints.maxWidth > mobileLayoutBreakpoint;

        return Scaffold(
          backgroundColor: colors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: colors.backgroundPrimary,
            surfaceTintColor: colors.backgroundPrimary,
            elevation: 1.0,
            shadowColor: Colors.black.withOpacity(0.1),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80.0),
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
    if (widget.isLoading && widget.items.isEmpty) {
      return Center(child: _buildModernLoading());
    }
    if (widget.hasError && widget.items.isEmpty) {
      return _buildErrorState(context);
    }
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

    Widget _buildAnimatedItem(Widget child, int index, int totalItems) {
      return FadeTransition(
        opacity: widget.fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: widget.animationController,
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

    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    // Lee el valor que viene desde el padre (que a su vez lo lee del Provider)
    if (isDesktopLayout && widget.userSelectedCrossAxisCount != null) {
      crossAxisCount = widget.userSelectedCrossAxisCount!;
    } else if (isDesktopLayout) {
      const double cardIdealWidth = 380.0;
      crossAxisCount = (screenWidth / cardIdealWidth).floor();
      if (crossAxisCount == 0) crossAxisCount = 1;
    } else {
      crossAxisCount = 1;
    }

    final bool useTableRowLayout = isDesktopLayout && crossAxisCount == 1;

    if (useTableRowLayout) {
      return ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = widget.items[index];
          final card = Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: widget.tableRowCardBuilder(context, item),
          );
          return _buildAnimatedItem(card, index, widget.items.length);
        },
      );
    }

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        mainAxisExtent: widget.cardHeight,
      ),
      itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = widget.items[index];
        final card = widget.cardBuilder(context, item);
        return _buildAnimatedItem(card, index, widget.items.length);
      },
    );
  }

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
          Row(
            children: [
              if (widget.filterButton != null) ...[
                widget.filterButton!,
                const SizedBox(width: 8),
              ],

              widget.sortButton,

              // Simplemente mostramos el botón que nos pasen. No le importa qué hace.
              if (isDesktopLayout && widget.layoutControlButton != null) ...[
                const SizedBox(width: 8),
                widget.layoutControlButton!,
              ],

              Expanded(
                child:
                    widget.actionBarContent != null
                        ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: widget.actionBarContent!,
                        )
                        : const SizedBox(),
              ),

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

  Widget _buildModernFAB(dynamic colors) {
    return FloatingActionButton(
      heroTag: widget.fabHeroTag,
      onPressed: widget.onAddItem,
      child: const Icon(Icons.add_rounded),
      backgroundColor: colors.backgroundButton,
      foregroundColor: colors.whiteWhite,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

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

  // --- Widgets de estado (Loading, Empty, Error) ---
  // (Estos métodos no necesitan cambios)
  
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