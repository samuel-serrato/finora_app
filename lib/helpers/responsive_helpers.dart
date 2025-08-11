// lib/src/utils/responsive_helpers.dart
import 'package:flutter/material.dart';

// Define tus breakpoints en un solo lugar
const double kTabletBreakpoint = 768.0;
const double kDesktopBreakpoint = 1000.0;

extension ResponsiveContext on BuildContext {
  /// Devuelve true si el ancho de la pantalla es menor que el breakpoint de tablet.
  bool get isMobile {
    return MediaQuery.of(this).size.width < kTabletBreakpoint;
  }

  /// Devuelve true si el ancho es mayor o igual que el breakpoint de tablet.
  bool get isTablet {
    final width = MediaQuery.of(this).size.width;
    return width >= kTabletBreakpoint && width < kDesktopBreakpoint;
  }
    
  /// Devuelve true si el ancho es mayor o igual que el breakpoint de desktop.
  bool get isDesktop {
    return MediaQuery.of(this).size.width >= kDesktopBreakpoint;
  }
}