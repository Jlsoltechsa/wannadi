import 'package:flutter/material.dart';

/// Breakpoint canónico SUMMA: bajo 640 lógico-px ⇒ móvil/compact.
const double kCompactBreakpoint = 640;
const double kTabletBreakpoint = 960;

bool isCompact(BuildContext c) =>
    MediaQuery.sizeOf(c).width < kCompactBreakpoint;
bool isTablet(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  return w >= kCompactBreakpoint && w < kTabletBreakpoint;
}
bool isDesktop(BuildContext c) =>
    MediaQuery.sizeOf(c).width >= kTabletBreakpoint;


/// Layout de dos paneles (lista lateral + detalle) que en pantallas
/// compact se colapsa a navegación drill-down: muestra el `master` por
/// defecto y al tener `selectedId` no nulo, muestra el `detail` con un
/// botón de "volver" en el AppBar.
///
/// El widget no asume cuál es la "selección"; la pantalla pasa `hasSelection`
/// y cuál panel renderizar.
class ResponsiveTwoPane extends StatelessWidget {
  /// Ancho del panel master en desktop.
  final double masterWidth;
  /// Si hay selección activa (en compact, se muestra el detail).
  final bool hasSelection;
  /// Callback para volver al master en compact (limpia selección).
  final VoidCallback? onBack;
  final Widget master;
  final Widget detail;

  const ResponsiveTwoPane({
    super.key,
    this.masterWidth = 320,
    required this.hasSelection,
    required this.master,
    required this.detail,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact(context)) {
      // Drill-down: master por defecto, detail cuando hay selección.
      if (hasSelection) {
        return Stack(children: [
          detail,
          Positioned(
            top: 8, left: 8,
            child: SafeArea(
              child: Material(
                color: Theme.of(context).colorScheme.surface
                    .withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Volver',
                  onPressed: onBack,
                ),
              ),
            ),
          ),
        ]);
      }
      return master;
    }
    // Desktop/tablet: paneles lado a lado. `stretch` da a ambos paneles
    // la altura completa; sin él, un master más corto que el detail se
    // centraba verticalmente (su título quedaba a media pantalla).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1),
        Expanded(child: detail),
      ],
    );
  }
}


/// Devuelve un padding adaptativo (más pequeño en compact).
EdgeInsets responsivePadding(BuildContext c,
    {double compact = 12, double desktop = 20}) =>
    EdgeInsets.all(isCompact(c) ? compact : desktop);


/// Ancho máximo razonable para un Dialog, evitando que en mobile sea más
/// ancho que el viewport.
double dialogMaxWidth(BuildContext c, {double preferred = 460}) {
  final w = MediaQuery.sizeOf(c).width;
  return w < preferred + 48 ? w - 48 : preferred;
}


/// Envuelve un widget tabular (típicamente `DataTable`) con doble scroll
/// (horizontal + vertical) para que no desborde en pantallas estrechas.
Widget responsiveTable({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(16),
}) {
  return SingleChildScrollView(
    padding: padding,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: child,
    ),
  );
}
