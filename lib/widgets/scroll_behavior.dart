import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Esta clase habilita el scroll con el ratón y el trackpad en todas las plataformas.
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
  };
}