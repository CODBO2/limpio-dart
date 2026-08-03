import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contenedor global de Riverpod (sobrevive a navegación y share intents).
late final ProviderContainer appContainer;

/// Clave de navegación global (compartida con el bootstrap).
class LimpioApp {
  LimpioApp._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
