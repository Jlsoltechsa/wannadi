import 'package:flutter/material.dart';

/// Tokens de color genéricos del kit `wannadi`.
///
/// Esta clase NO representa marca: son los semánticos (success / danger /
/// warning / info), las superficies (Material 3) y un conjunto de colores
/// accent neutrales que los widgets usan como defaults. Si tu app necesita
/// marca, configúrala vía paleta (`SigmaPalette`) en lugar de hardcodear.
class WannadiColors {
  // ── Marca por defecto (paleta clásica navy/ámbar; el host puede cambiarla
  // vía paletas o pasando colores explícitos) ─────────────────────────────
  static const navy        = Color(0xFF0E2452);
  static const navyDeep    = Color(0xFF0A1B3D);
  static const navyMid     = Color(0xFF1A3470);
  static const steel       = Color(0xFF5C8AB5);
  static const steelDeep   = Color(0xFF3F6A93);
  static const steelLight  = Color(0xFFA9C2DA);
  static const amber       = Color(0xFFEAAA2F);
  static const amberLight  = Color(0xFFF4C463);
  static const slate       = Color(0xFF5A6A8A);
  static const mist        = Color(0xFF9AAAC4);
  static const ink         = Color(0xFF12182A);

  // ── Semánticos ───────────────────────────────────────────────────────────
  static const success     = Color(0xFF2BA876);
  static const warning     = Color(0xFFE89A2D);
  static const danger      = Color(0xFFD8584D);
  static const info        = Color(0xFF4D8AC0);

  // ── Superficies ──────────────────────────────────────────────────────────
  static const surface     = Color(0xFFF3F5FA);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE7ECF4);
  static const border      = Color(0xFFD9DEE9);
  static const textPrimary = Color(0xFF12182A);
  static const textSub     = Color(0xFF5A6A8A);
  static const textMuted   = Color(0xFF8C99B0);
  static const snowWhite   = Color(0xFFFFFFFF);

  // ── Aliases ──────────────────────────────────────────────────────────────
  static const blue        = steel;
  static const teal        = Color(0xFF1C9C9F);
  static const green       = success;
  static const red         = danger;
  static const purple      = Color(0xFF6E63A6);
  static const navyLight   = navyMid;

  // ── Colores por índice (útil para chips/categorías sin significado fijo) ─
  static const List<Color> subject = [
    steel, teal, success, amber, danger, purple,
  ];
  static Color subjectAt(int i) => subject[i % subject.length];

  /// Gradient ligado a un color base; usado por `GradientHero`.
  static LinearGradient gradientFor(Color base) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base, Color.lerp(base, navy, 0.4) ?? base],
      );

  // ── Color por rol — defaults genéricos del UI kit ───────────────────────
  static Color forRole(String? role) {
    switch (role) {
      case 'Admin':         return navy;
      case 'Profesor':      return steel;
      case 'Representante': return purple;
      case 'Estudiante':    return teal;
      case 'Empleado':      return amber;
      default:              return steel;
    }
  }
}


/// Tipografía sugerida del kit. Si los fonts no están registrados en la app,
/// Flutter cae automáticamente al fallback Material por defecto.
class WannadiFonts {
  static const display = 'Plus Jakarta Sans';
  static const body    = 'DM Sans';
  static const mono    = 'JetBrains Mono';

  static const _fallback = ['Roboto', 'Helvetica', 'Arial', 'sans-serif'];
  static const List<String> displayFallback = [body, ..._fallback];
  static const List<String> bodyFallback    = [display, ..._fallback];
}
