import 'package:flutter/material.dart';

class AppColors {
  // Singleton pattern
  static final AppColors _instance = AppColors._internal();
  factory AppColors() => _instance;
  AppColors._internal();

  // Estado del tema (claro u oscuro)
  bool _isDarkMode = false;

  // Getter para el estado actual del tema
  bool get isDarkMode => _isDarkMode;

  // Método para establecer un tema específico
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  // Base Color Palette
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _primaryBrand = Color(0xFF03DAC6);
  static const _errorRed = Color(0xFFB00020);

  // Neutral Colors (Grey Scale)
  static const _grey50 = Color(0xFFFAFAFA);
  static const _grey70 = Color(0xFFF7F8FA);
  static const _grey100 = Color(0xFFF5F5F5);
  static const _grey150 = Color(0xFFF0F0F0);
  static const _grey200 = Color(0xFFEEEEEE);
  static const _grey300 = Color(0xFFE0E0E0);
  static const _grey400 = Color(0xFFBDBDBD);
  static const _grey500 = Color(0xFF9E9E9E);
  static const _grey600 = Color(0xFF757575);
  static const _grey700 = Color(0xFF616161);
  static const _grey800 = Color(0xFF424242);
  static const _grey900 = Color(0xFF212121);

  // Colores para modo claro
  static const Color _lightBackground = Color(0xFFF9FAFC);
  static const Color _lightBackgroundSecondary = Color(0xFFF1F4F9);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF4E5B6D);
  static const Color _lightDivider = Color(0xFFE2E8F0);
  static const Color _lightCard = Color(0xFFFFFFFF);

  // Colores para modo oscuro
  static const Color _darkBackground = Color(0xFF11192B);
  static const Color _darkBackgroundSecondary = Color(0xFF1E293B);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkText = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);
  static const Color _darkDivider = Color(0xFF334155);
  static const Color _darkCard = Color(0xFF1E293B);
  static const Color _darkMediumCard = Color(0xFF142034);

  static const Color _darkBlueBlack = Color(0xFF121621);

  // Colores de marca (basados en #7FF9CB)
  static const Color primary = Color(0xFF5162F6); //
  static const Color primaryLight = Color(0xFF7B8AF8); // Versión más clara
  static const Color primaryDark = Color(0xFF3D4ED4); // Versión más oscura
  static const Color secondary = Color(0xFF14B8A6); //
  static const Color accent = Color(
    0xFFF43F5E,
  ); // Rose (como color de acento/error)
  static const Color success = Color(0xFF10B981); // Emerald para éxito
  static const Color warning = Color(0xFFF59E0B); // Amber para advertencias
  static const Color info = Color(0xFF3B82F6); // Blue para información

  // NUEVOS COLORES PARA HOME SCREEN
  // Colores del gradiente de la tarjeta de bienvenida
  static const Color homeGradientStart = Color(0xFF6A88F7);
  static const Color homeGradientEnd = Color(0xFF5162F6);

  // Colores para las tarjetas de estadísticas
  static const Color statCardCreditos = Color(0xFF5162F6); // Azul para créditos
  static const Color statCardSuccess = Color(
    0xFF6BC950,
  ); // Verde para finalizados
  static const Color statCardTeal = Color(
    0xFF4ECDC4,
  ); // Teal para individuales/grupales
  static const Color statCardPayments = Color(0xFFFF6B6B); // Coral para pagos

  // Color de fondo principal del Home
  static const Color homeBackground = Color(0xFFF7F8FA);

  Color get brandPrimaryTheme => _isDarkMode ? primary : primaryLight.withOpacity(0.1);
    Color get brandPrimaryThemeText => _isDarkMode ? _white : primary;

  // Colores base para el tooltip
  static const Color _lightTooltipBackground = Color(0xFF718EB6);
  static const Color _lightTooltipTextPrimary = Color(0xFFF1F5F9);
  static const Color _lightTooltipTextSecondary = Color(0xFFF1F5F9);

  static const Color _darkTooltipBackground = Color(0xFF334155);
  static const Color _darkTooltipTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTooltipTextSecondary = Color(0xFF94A3B8);

  static const Color tooltipLightBackground = Color(0xFFB3D1FB);

  // Getters dinámicos que cambian con el tema
  Color get tooltipBackground =>
      _isDarkMode ? _darkTooltipBackground : const Color(0xFF5A7AA8);
  Color get tooltipTextPrimary =>
      _isDarkMode ? _darkTooltipTextPrimary : _lightTooltipTextPrimary;
  Color get tooltipTextSecondary =>
      _isDarkMode ? _darkTooltipTextSecondary : _lightTooltipTextSecondary;

  Color get tooltipBorder =>
      _isDarkMode ? Colors.transparent : _darkTooltipTextSecondary;

  // Dark mode (ya tienes)
  final Color colorRecaudadoDark = Colors.green;
  final Color colorIdealDark = Colors.blueAccent.withOpacity(0.7);

  // Light mode (variante)
  final Color colorRecaudadoLight = const Color(
    0xFF3FDE37,
  ); // verde más profundo y visible sobre blanco
  final Color colorIdealLight =
      Colors.lightBlueAccent; // azul más suave y brillante

  Color get colorRecaudado =>
      _isDarkMode ? colorRecaudadoDark : colorRecaudadoDark;
  Color get colorIdeal => _isDarkMode ? colorIdealDark : colorIdealDark;

  Color get colorRecaudadoText =>
      _isDarkMode ? colorRecaudadoDark : colorRecaudadoLight;

  Color get colorIdealText => _isDarkMode ? colorIdealDark : colorIdealLight;

  // Métodos para obtener los colores según el modo
  //Color get backgroundPrimary => _isDarkMode ? _grey900 : _lightBackground;
  Color get backgroundPrimary =>
      _isDarkMode ? _darkBlueBlack : _lightBackground;

  Color get backgroundHeader => _isDarkMode ? brandPrimary : _darkBackground;

  Color get backgroundCard => _isDarkMode ? _darkSurface : _white;

  Color get disabledCard =>
      _isDarkMode ? const Color(0xFF1D2024) : Colors.blueGrey.shade50;

  Color get backgroundCardDark => _isDarkMode ? _darkBackground : _white;

  Color get backgroundCardDark2 => _isDarkMode ? _darkBackground : _grey150;

  Color get backgroundCardDarkRedondeo =>
      isDarkMode ? _darkBackground : _grey100;

  Color get backgroundSecondary =>
      _isDarkMode ? _darkBackgroundSecondary : _lightBackgroundSecondary;

  Color get surface => _isDarkMode ? _darkSurface : _lightSurface;

  Color get textPrimary => _isDarkMode ? _darkText : _lightText;

  Color get textSecondary =>
      _isDarkMode ? _darkTextSecondary : _lightTextSecondary;

  Color get textHeader => _isDarkMode ? _darkBackground : _darkText;

  Color get divider => _isDarkMode ? Colors.transparent : _lightDivider;

  Color get divider2 => _isDarkMode ? _lightDivider : _darkDivider;

  Color get divider3 => _isDarkMode ? _darkTextSecondary : _lightDivider;

  Color get card => _isDarkMode ? _darkCard : _lightCard;

  Color get buttonCreditAction =>
      _isDarkMode ? const Color(0xFF5C6777) : _lightText;

  Color get selectedMenu =>
      _isDarkMode
          ? primaryLight.withOpacity(0.2)
          : primaryLight.withOpacity(0.1);

  Color get whiteBlack => _isDarkMode ? Colors.black : Colors.white;

  Color get whiteWhite => _isDarkMode ? Colors.white : Colors.white;

  Color get blackWhite => _isDarkMode ? Colors.white : Colors.black;

  Color get blacBlack => _isDarkMode ? Colors.black : Colors.black;

  Color get error => accent;

  Color get iconColor => _isDarkMode ? _lightBackground : _darkBackground;

  // Brand Colors
  Color get brandPrimary => _isDarkMode ? primaryDark : primary;
  Color get brandSecondary => secondary;
  Color get brandLight => primaryLight;
  Color get brandDark => primaryDark;
  Color get lightgreyblue => Color(0xFFF2F3F7);

  // HOME SCREEN COLORS - Métodos dinámicos según el tema
  Color get homeBackgroundColor => _isDarkMode ? _grey900 : homeBackground;

  Color get homeWelcomeGradientStart =>
      _isDarkMode ? const Color(0xFF1D2649) : homeGradientStart;
  Color get homeWelcomeGradientEnd =>
      _isDarkMode ? const Color(0xFF131738) : homeGradientEnd;

  Color get DrawerGradientStart =>
      _isDarkMode ? const Color(0xFF1D2649) : homeGradientStart;
  Color get DrawerGradientEnd =>
      _isDarkMode ? const Color(0xFF131738) : const Color(0xFF141A4D);

  // Colores para iconos y texto de error
  Color get homeErrorIcon => Colors.red[300]!;
  Color get homeDialogError => Colors.red;
  Color get homeLogoutIcon => Colors.red[700]!;

  // Inputs
  Color get inputFill =>
      _isDarkMode ? _grey700 : lightgreyblue; // fondo del input
  Color get inputBorder =>
      _isDarkMode ? _grey700 : _grey800; // borde en dark y sin borde en light
  Color get inputText =>
      _isDarkMode ? _white : const Color(0xFF111827); // texto principal
  Color get inputHint =>
      _isDarkMode ? _grey400 : const Color(0xFF9CA3AF); // hint text
  Color get inputLabel =>
      _isDarkMode ? _grey300 : const Color(0xFF374151); // etiquetas
  Color get inputIcon =>
      _isDarkMode ? _grey400 : const Color(0xFF6B7280); // iconos
  Color get inputFocusedBorder =>
      _isDarkMode ? _white : _black; // borde al enfocar

  //BOTONES
  Color get backgroundButton => isDarkMode ? primaryDark : primary;
  Color get textButton => isDarkMode ? _darkBackground : _white;
  Color get textButton2 => isDarkMode ? _white : primary;
  Color get iconButton => isDarkMode ? _darkBackground : _white;
  Color get iconButton2 => isDarkMode ? _darkBackground : _white;

  // Gradientes
  LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent.withOpacity(0.8)],
  );

  // Gradiente para la tarjeta de bienvenida del Home
  LinearGradient get homeWelcomeGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [homeWelcomeGradientStart, homeWelcomeGradientEnd],
  );

  // Gradiente para el menú Drawer
  LinearGradient get drawerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [DrawerGradientStart, DrawerGradientEnd],
  );

  // NAVIGATOR
  Color get navigatorBackground =>
      isDarkMode ? _darkBackground : _lightBackground;
  Color get navigatorBorder => divider;
  Color get navigatorIconColor => textPrimary;
  Color get navigatorSelectedIconColor => whiteBlack;
  Color get navigatorSelectedBgColor => isDarkMode ? primary : _darkBackground;
  Color get navigatorHoverColor => textPrimary.withOpacity(0.1);
  Color get navigatorTitleColor => blackWhite;
  Color get navigatorCompactWidth =>
      isDarkMode ? _darkBackgroundSecondary : _lightBackgroundSecondary;
  Color get navigatorLogoBackground =>
      isDarkMode ? primary.withOpacity(0.1) : primaryLight.withOpacity(0.1);
  Color get navigatorFooterColor => textSecondary;

  //MENU LATERAL ANIMATEDCONTAINER
  Color get backgroundMenuLeft => isDarkMode ? _darkBackground : _white;

  //CUSTOMAPPBAR
  Color get appbarIcon => isDarkMode ? primary : _darkBackground;

  // Table Colors
  Color get tableHeaderBackground => _isDarkMode ? surface : _white;
  Color get tableHeaderText => textPrimary;
  Color get tableRowBackground => surface;
  Color get tableRowText => textSecondary;
  Color get tableBorder => divider;

  // SearchBar Colors
  Color get searchBarBackground => _isDarkMode ? _darkSurface : _white;
  Color get searchBarBorder => _isDarkMode ? _grey700 : _grey300;
  Color get searchBarIcon => _isDarkMode ? _grey400 : _grey600;
  Color get searchBarText => _isDarkMode ? _white : _grey900;
  Color get searchBarHint => _isDarkMode ? _grey400 : _grey700;
  Color get searchBarCursor => _isDarkMode ? _primaryBrand : _grey700;

  // Agregar estos colores a tu clase AppColors

  // BOTTOM NAVIGATION BAR COLORS
  // Color base para el BottomNavigationBar
  static const Color bottomNavBase = Color(0xFF5162F6);
  static const Color bottomNavLight = Color(0xFF7B8AF8);
  static const Color bottomNavDark = Color(0xFF3D4ED4);

  // Métodos para BottomNavigationBar según el modo
  //Color get bottomNavBackground => _isDarkMode ? _grey900 : _white;
  Color get bottomNavBackground => _isDarkMode ? _darkBlueBlack : _white;

  Color get bottomNavSelectedItem =>
      _isDarkMode ? bottomNavLight : bottomNavBase;

  Color get bottomNavUnselectedItem => _isDarkMode ? _grey400 : _grey600;

  Color get bottomNavSelectedIconBackground =>
      _isDarkMode
          ? bottomNavBase.withOpacity(0.2)
          : bottomNavLight.withOpacity(0.1);

  Color get bottomNavBorder => _isDarkMode ? _darkDivider : _grey200;

  Color get bottomNavRipple =>
      _isDarkMode
          ? bottomNavLight.withOpacity(0.1)
          : bottomNavBase.withOpacity(0.1);

  // Gradiente opcional para efectos especiales
  LinearGradient get bottomNavGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _isDarkMode ? [_grey900, _grey800] : [_white, _grey50],
  );

  //Card pequeña
  Color get smallCard =>
      _isDarkMode ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.1);
  Color get smallCardBorder => _isDarkMode ? const Color(0xFF161E2B) : _grey200;

  //Card Moratorios creditos
  Color get moratoriosCard =>
      _isDarkMode ? const Color(0xFF32090F) : Color(0xFFFFEBEE);
  Color get moratoriosCardBorder =>
      _isDarkMode ? const Color(0xFF491019) : Color(0xFFF44336);

  //BORDE
  Color get bordeButton =>
      isDarkMode ? Colors.grey.withOpacity(0.3) : Colors.grey.withOpacity(0.3);

  //SIDEMENU
  Color get backgroundSideMenu =>
      _isDarkMode ? _darkMediumCard : _lightBackground;

  //SIDEMENU
  Color get backgroundDialog =>
      _isDarkMode ? _darkMediumCard : _lightBackground;
}
