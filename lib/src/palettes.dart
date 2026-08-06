import 'package:flutter/material.dart';

/// Identificador de paleta SUMMA. Determina la "skin" visual del tema.
///
/// La paleta gobierna el `ColorScheme` y elementos cromáticos que cambian
/// entre skins (AppBar, scaffold background, acentos). Los activos de
/// marca (logo, símbolos) se mantienen constantes.
enum SummaPalette {
  lino,       // papel casi-blanco cálido (#FDFBF7) — skin por defecto
  classic,    // crema navy + ámbar — la cálida original (manual v1.0), preservada
  ocean,      // azul océano + turquesa
  forest,     // verde bosque + amarillo trigo
  sunset,     // coral + lila
  graphite,   // gris carbón + azul cobalto
}

extension SummaPaletteX on SummaPalette {
  String get id {
    switch (this) {
      case SummaPalette.lino:     return 'lino';
      case SummaPalette.classic:  return 'classic';
      case SummaPalette.ocean:    return 'ocean';
      case SummaPalette.forest:   return 'forest';
      case SummaPalette.sunset:   return 'sunset';
      case SummaPalette.graphite: return 'graphite';
    }
  }

  String get label {
    switch (this) {
      case SummaPalette.lino:     return 'Papel';
      case SummaPalette.classic:  return 'Crema';
      case SummaPalette.ocean:    return 'Océano';
      case SummaPalette.forest:   return 'Bosque';
      case SummaPalette.sunset:   return 'Atardecer';
      case SummaPalette.graphite: return 'Grafito';
    }
  }

  /// Color representativo para el chip del selector.
  Color get swatch => light.primary;

  static SummaPalette fromId(String? id) {
    for (final p in SummaPalette.values) {
      if (p.id == id) return p;
    }
    return SummaPalette.lino;
  }
}

/// Colores derivados de una paleta. Cada paleta expone dos `ColorScheme`
/// (light y dark) ya cuadrados.
class PaletteColors {
  final ColorScheme light;
  final ColorScheme dark;
  // Marca / acentos cromáticos extra (se usan en widgets puntuales).
  final Color brandDeep;   // navy equivalente — sidebar de marca
  final Color brandAccent; // ámbar equivalente — botón "Aprobar", chips destacados
  const PaletteColors({
    required this.light,
    required this.dark,
    required this.brandDeep,
    required this.brandAccent,
  });

  /// Construye una `PaletteColors` a partir de dos colores de marca.
  ///
  /// - `primary` se usa como `brandDeep` y como `seedColor` del
  ///   `ColorScheme` light / dark generado por `fromSeed` de Material 3.
  /// - `accent` se usa como `brandAccent` y se inyecta como `secondary`
  ///   del scheme.
  ///
  /// Ideal para apps que configuran su theme en runtime — por ejemplo,
  /// a partir de un par de hexs guardados en la base de datos.
  factory PaletteColors.fromBrand({
    required Color primary,
    required Color accent,
  }) {
    final lightBase = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    final darkBase = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    return PaletteColors(
      brandDeep: primary,
      brandAccent: accent,
      light: lightBase.copyWith(
        primary: primary,
        secondary: accent,
      ),
      dark: darkBase.copyWith(
        secondary: accent,
      ),
    );
  }
}


extension PaletteColorsOf on SummaPalette {
  PaletteColors get colors {
    switch (this) {
      case SummaPalette.lino:     return _lino;
      case SummaPalette.classic:  return _classic;
      case SummaPalette.ocean:    return _ocean;
      case SummaPalette.forest:   return _forest;
      case SummaPalette.sunset:   return _sunset;
      case SummaPalette.graphite: return _graphite;
    }
  }
  ColorScheme get light => colors.light;
  ColorScheme get dark  => colors.dark;
}


/// Acceso rápido a los colores de marca de la paleta activa desde
/// cualquier `BuildContext`. Útil cuando un widget necesita el navy/ámbar
/// equivalente del theme actual (que en `classic` son los oficiales pero
/// cambian en otras paletas).
///
/// Ejemplo:
/// ```dart
/// Container(
///   gradient: context.brandGradient,
///   child: Icon(Icons.school, color: context.onBrand),
/// )
/// ```
extension BrandColorsOf on BuildContext {
  /// Color "navy" equivalente — el deep de la paleta activa.
  Color get brandDeep {
    return _resolvePaletteColors(this).brandDeep;
  }

  /// Color "ámbar" equivalente — el accent de la paleta activa.
  Color get brandAccent {
    return _resolvePaletteColors(this).brandAccent;
  }

  /// Color del texto/icono apropiado para fondos `brandDeep`.
  Color get onBrand => const Color(0xFFFFFFFF);

  /// Gradient diagonal para heros y sidebars: brandDeep oscuro → brandDeep.
  LinearGradient get brandGradient {
    final deep = brandDeep;
    return LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [deep, Color.lerp(deep, Colors.black, 0.35) ?? deep],
    );
  }
}


/// Resuelve la paleta activa. Prioridad:
///
/// 1. `_paletteColorsResolver` si está registrado — permite que la app
///    construya un `PaletteColors` arbitrario en runtime (por ejemplo,
///    a partir de un par de colores configurados en backend).
/// 2. `_paletteResolver` (legacy) que devuelve un `SummaPalette` enum.
/// 3. `SummaPalette.classic` como fallback.
PaletteColors _resolvePaletteColors(BuildContext context) {
  try {
    final pc = _paletteColorsResolver?.call(context);
    if (pc != null) return pc;
  } catch (_) {/* ignore */}
  try {
    final p = _paletteResolver?.call(context);
    if (p != null) return p.colors;
  } catch (_) {/* ignore */}
  return SummaPalette.classic.colors;
}

/// Setter externo para que el caller registre cómo obtener la paleta
/// activa desde el contexto. Se setea una vez al iniciar la app desde
/// `main.dart` o desde `HomeShell`. Esto desacopla `palettes.dart` de
/// `theme_provider.dart`.
SummaPalette? Function(BuildContext)? _paletteResolver;
void setPaletteResolver(SummaPalette? Function(BuildContext) fn) {
  _paletteResolver = fn;
}

/// Setter alternativo para resolver la paleta como un `PaletteColors`
/// directo. Útil cuando la app construye el theme a partir de datos
/// runtime (p.ej. los `brand_color_primary` y `brand_color_accent` de
/// la sucursal activa). Tiene prioridad sobre `setPaletteResolver`.
PaletteColors? Function(BuildContext)? _paletteColorsResolver;
void setPaletteColorsResolver(PaletteColors? Function(BuildContext) fn) {
  _paletteColorsResolver = fn;
}


// ── Definiciones de paletas ─────────────────────────────────────────────────

// Paleta oficial SUMMA — fiel al Manual de Marca v1.0 (capas 1 y 2 +
// neutros cálidos crema de 10.01). Las demás paletas (ocean/forest/…) son
// skins alternativas y NO siguen el manual a propósito.
const _classic = PaletteColors(
  brandDeep:   Color(0xFF1F2A4E),  // navy.deep
  brandAccent: Color(0xFFEAAA2F),  // dorado.brand
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5D8BB6),  onPrimary: Color(0xFFFFFFFF),       // azul.brand
    primaryContainer: Color(0xFFD8E5F1), onPrimaryContainer: Color(0xFF1F2A4E),
    secondary: Color(0xFFEAAA2F), onSecondary: Color(0xFF1F2A4E),    // dorado.brand
    secondaryContainer: Color(0xFFFAE6BB), onSecondaryContainer: Color(0xFF1F2A4E),
    tertiary: Color(0xFF1F2A4E), onTertiary: Color(0xFFFFFFFF),      // navy.deep
    tertiaryContainer: Color(0xFFCDD6E5), onTertiaryContainer: Color(0xFF1F2A4E),
    error: Color(0xFFDC2626), onError: Color(0xFFFFFFFF),            // danger
    errorContainer: Color(0xFFFADADA), onErrorContainer: Color(0xFF1F2A4E),
    surface: Color(0xFFF4EFE5), onSurface: Color(0xFF1F2A4E),        // crema.base / navy text
    surfaceContainerHighest: Color(0xFFFAF7F0),                      // crema.light
    onSurfaceVariant: Color(0xFF6B7592),                             // text-muted
    outline: Color(0xFFD6D3D0), outlineVariant: Color(0xFFE3DFD9),   // bordes cálidos
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5D8BB6),  onPrimary: Color(0xFF0A1430),
    primaryContainer: Color(0xFF1B3A5C), onPrimaryContainer: Color(0xFFA9C2DA),
    secondary: Color(0xFFEAAA2F), onSecondary: Color(0xFF0A1430),
    secondaryContainer: Color(0xFF4D3A18), onSecondaryContainer: Color(0xFFF4C463),
    tertiary: Color(0xFFA9C2DA), onTertiary: Color(0xFF0A1430),
    tertiaryContainer: Color(0xFF24375C), onTertiaryContainer: Color(0xFFA9C2DA),
    error: Color(0xFFFF6B6B), onError: Color(0xFF0A1430),
    errorContainer: Color(0xFF4A1818), onErrorContainer: Color(0xFFFFB3B3),
    surface: Color(0xFF14213F), onSurface: Color(0xFFE7ECF4),
    surfaceContainerHighest: Color(0xFF2A3550),
    outline: Color(0xFF2D3756), outlineVariant: Color(0xFF1F2A48),
  ),
);

// Papel — skin por defecto: casi-blanco cálido, más fresca/nativa que el crema.
// Idéntica a _classic salvo el fondo de página (surface). El crema original se
// preserva como la skin `classic`. El casi-blanco sigue siendo cálido
// (R>G>B), así que respeta "cálido, nunca frío" del manual. Modo oscuro sin cambios.
const _lino = PaletteColors(
  brandDeep:   Color(0xFF1F2A4E),  // navy.deep
  brandAccent: Color(0xFFEAAA2F),  // dorado.brand
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF5D8BB6),  onPrimary: Color(0xFFFFFFFF),       // azul.brand
    primaryContainer: Color(0xFFD8E5F1), onPrimaryContainer: Color(0xFF1F2A4E),
    secondary: Color(0xFFEAAA2F), onSecondary: Color(0xFF1F2A4E),    // dorado.brand
    secondaryContainer: Color(0xFFFAE6BB), onSecondaryContainer: Color(0xFF1F2A4E),
    tertiary: Color(0xFF1F2A4E), onTertiary: Color(0xFFFFFFFF),      // navy.deep
    tertiaryContainer: Color(0xFFCDD6E5), onTertiaryContainer: Color(0xFF1F2A4E),
    error: Color(0xFFDC2626), onError: Color(0xFFFFFFFF),            // danger
    errorContainer: Color(0xFFFADADA), onErrorContainer: Color(0xFF1F2A4E),
    surface: Color(0xFFFDFBF7), onSurface: Color(0xFF1F2A4E),        // papel casi-blanco cálido
    surfaceContainerHighest: Color(0xFFFAF7F0),                      // crema.light (elevado)
    onSurfaceVariant: Color(0xFF6B7592),                             // text-muted
    outline: Color(0xFFD6D3D0), outlineVariant: Color(0xFFE3DFD9),   // bordes cálidos
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5D8BB6),  onPrimary: Color(0xFF0A1430),
    primaryContainer: Color(0xFF1B3A5C), onPrimaryContainer: Color(0xFFA9C2DA),
    secondary: Color(0xFFEAAA2F), onSecondary: Color(0xFF0A1430),
    secondaryContainer: Color(0xFF4D3A18), onSecondaryContainer: Color(0xFFF4C463),
    tertiary: Color(0xFFA9C2DA), onTertiary: Color(0xFF0A1430),
    tertiaryContainer: Color(0xFF24375C), onTertiaryContainer: Color(0xFFA9C2DA),
    error: Color(0xFFFF6B6B), onError: Color(0xFF0A1430),
    errorContainer: Color(0xFF4A1818), onErrorContainer: Color(0xFFFFB3B3),
    surface: Color(0xFF14213F), onSurface: Color(0xFFE7ECF4),
    surfaceContainerHighest: Color(0xFF2A3550),
    outline: Color(0xFF2D3756), outlineVariant: Color(0xFF1F2A48),
  ),
);

const _ocean = PaletteColors(
  brandDeep:   Color(0xFF0B2E4A),
  brandAccent: Color(0xFF20C5B7),
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1A6FA8),  onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCFE4F4), onPrimaryContainer: Color(0xFF0B2E4A),
    secondary: Color(0xFF20C5B7), onSecondary: Color(0xFF002B2A),
    secondaryContainer: Color(0xFFB8EDE8), onSecondaryContainer: Color(0xFF002B2A),
    tertiary: Color(0xFF0B2E4A), onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB8C9D8), onTertiaryContainer: Color(0xFF0B2E4A),
    error: Color(0xFFD24A4A), onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFAD7D7), onErrorContainer: Color(0xFF400A0A),
    surface: Color(0xFFEEF6FB), onSurface: Color(0xFF0E1A26),
    surfaceContainerHighest: Color(0xFFD9E8F2),
    outline: Color(0xFFB8CEDC), outlineVariant: Color(0xFFD9E8F2),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4FA7DA),  onPrimary: Color(0xFF051826),
    primaryContainer: Color(0xFF103E60), onPrimaryContainer: Color(0xFFB8DCF1),
    secondary: Color(0xFF20C5B7), onSecondary: Color(0xFF002B2A),
    secondaryContainer: Color(0xFF134642), onSecondaryContainer: Color(0xFFA8E6E0),
    tertiary: Color(0xFFB8C9D8), onTertiary: Color(0xFF051826),
    tertiaryContainer: Color(0xFF1A2E42), onTertiaryContainer: Color(0xFFB8C9D8),
    error: Color(0xFFFF7676), onError: Color(0xFF051826),
    errorContainer: Color(0xFF4A1A1A), onErrorContainer: Color(0xFFFFC2C2),
    surface: Color(0xFF0E1A26), onSurface: Color(0xFFE0EDF5),
    surfaceContainerHighest: Color(0xFF1F2E40),
    outline: Color(0xFF2A3D52), outlineVariant: Color(0xFF1A2A3A),
  ),
);

const _forest = PaletteColors(
  brandDeep:   Color(0xFF1F3D1E),
  brandAccent: Color(0xFFE0B344),
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF3D7C3F),  onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7EAD3), onPrimaryContainer: Color(0xFF1F3D1E),
    secondary: Color(0xFFE0B344), onSecondary: Color(0xFF2D2200),
    secondaryContainer: Color(0xFFF7E7B5), onSecondaryContainer: Color(0xFF2D2200),
    tertiary: Color(0xFF1F3D1E), onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC5D6C0), onTertiaryContainer: Color(0xFF1F3D1E),
    error: Color(0xFFC04B3F), onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8D5D0), onErrorContainer: Color(0xFF3C0A04),
    surface: Color(0xFFF4F7EE), onSurface: Color(0xFF1A2014),
    surfaceContainerHighest: Color(0xFFE5EBD8),
    outline: Color(0xFFC2CFB4), outlineVariant: Color(0xFFE5EBD8),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7DC07F),  onPrimary: Color(0xFF0E1A0E),
    primaryContainer: Color(0xFF2A4A2A), onPrimaryContainer: Color(0xFFC5E5C5),
    secondary: Color(0xFFE0B344), onSecondary: Color(0xFF2D2200),
    secondaryContainer: Color(0xFF4D3D14), onSecondaryContainer: Color(0xFFF7D87E),
    tertiary: Color(0xFFC5D6C0), onTertiary: Color(0xFF0E1A0E),
    tertiaryContainer: Color(0xFF243524), onTertiaryContainer: Color(0xFFC5D6C0),
    error: Color(0xFFFF7B66), onError: Color(0xFF0E1A0E),
    errorContainer: Color(0xFF4A1812), onErrorContainer: Color(0xFFFFCABF),
    surface: Color(0xFF14201A), onSurface: Color(0xFFE2E8DE),
    surfaceContainerHighest: Color(0xFF1F2E26),
    outline: Color(0xFF2E3D33), outlineVariant: Color(0xFF1C2922),
  ),
);

const _sunset = PaletteColors(
  brandDeep:   Color(0xFF4A1A3A),
  brandAccent: Color(0xFFFF8C5A),
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB85A7C),  onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5D8E1), onPrimaryContainer: Color(0xFF4A1A3A),
    secondary: Color(0xFFFF8C5A), onSecondary: Color(0xFF3D1500),
    secondaryContainer: Color(0xFFFFD9C2), onSecondaryContainer: Color(0xFF3D1500),
    tertiary: Color(0xFF7E5BB0), onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0D2EE), onTertiaryContainer: Color(0xFF2D1A4A),
    error: Color(0xFFC0392B), onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8D5D0), onErrorContainer: Color(0xFF3C0A04),
    surface: Color(0xFFFDF6F4), onSurface: Color(0xFF24181C),
    surfaceContainerHighest: Color(0xFFF1E3E3),
    outline: Color(0xFFD8C2C8), outlineVariant: Color(0xFFF1E3E3),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF098B5),  onPrimary: Color(0xFF24081A),
    primaryContainer: Color(0xFF5C2A42), onPrimaryContainer: Color(0xFFF8D8E2),
    secondary: Color(0xFFFF8C5A), onSecondary: Color(0xFF3D1500),
    secondaryContainer: Color(0xFF5C2A14), onSecondaryContainer: Color(0xFFFFD9C2),
    tertiary: Color(0xFFC5A8E2), onTertiary: Color(0xFF24081A),
    tertiaryContainer: Color(0xFF3E2A5C), onTertiaryContainer: Color(0xFFE0D2EE),
    error: Color(0xFFFF6E6E), onError: Color(0xFF24081A),
    errorContainer: Color(0xFF4A1818), onErrorContainer: Color(0xFFFFB6B6),
    surface: Color(0xFF1F141A), onSurface: Color(0xFFEDDFE3),
    surfaceContainerHighest: Color(0xFF332026),
    outline: Color(0xFF3D2A35), outlineVariant: Color(0xFF2A1A22),
  ),
);

const _graphite = PaletteColors(
  brandDeep:   Color(0xFF1A1F2A),
  brandAccent: Color(0xFF4A9EFF),
  light: ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4A5A78),  onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD8DDE8), onPrimaryContainer: Color(0xFF1A1F2A),
    secondary: Color(0xFF4A9EFF), onSecondary: Color(0xFF002145),
    secondaryContainer: Color(0xFFCFE0F5), onSecondaryContainer: Color(0xFF002145),
    tertiary: Color(0xFF1A1F2A), onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC8CCD4), onTertiaryContainer: Color(0xFF1A1F2A),
    error: Color(0xFFCC4444), onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8D5D5), onErrorContainer: Color(0xFF3C0A0A),
    surface: Color(0xFFF5F6F8), onSurface: Color(0xFF14171E),
    surfaceContainerHighest: Color(0xFFE5E8ED),
    outline: Color(0xFFC8CDD6), outlineVariant: Color(0xFFE5E8ED),
  ),
  dark: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA8B6CC),  onPrimary: Color(0xFF0E121A),
    primaryContainer: Color(0xFF2A3145), onPrimaryContainer: Color(0xFFC8D2E2),
    secondary: Color(0xFF4A9EFF), onSecondary: Color(0xFF002145),
    secondaryContainer: Color(0xFF1A3654), onSecondaryContainer: Color(0xFFB8DAF5),
    tertiary: Color(0xFFC8CCD4), onTertiary: Color(0xFF0E121A),
    tertiaryContainer: Color(0xFF1F2530), onTertiaryContainer: Color(0xFFC8CCD4),
    error: Color(0xFFFF6E6E), onError: Color(0xFF0E121A),
    errorContainer: Color(0xFF4A1818), onErrorContainer: Color(0xFFFFB6B6),
    surface: Color(0xFF14171E), onSurface: Color(0xFFE0E3EA),
    surfaceContainerHighest: Color(0xFF1F242E),
    outline: Color(0xFF2E3340), outlineVariant: Color(0xFF1A1E26),
  ),
);
