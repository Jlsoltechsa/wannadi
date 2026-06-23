import 'package:flutter/material.dart';

/// Tokens de color genéricos del kit `wannadi`.
///
/// Esta clase NO representa marca: son los semánticos (success / danger /
/// warning / info), las superficies (Material 3) y un conjunto de colores
/// accent neutrales que los widgets usan como defaults. Si tu app necesita
/// marca, configúrala vía paleta (`SummaPalette`) en lugar de hardcodear.
class WannadiColors {
  // ── Marca por defecto — alineada al Manual de Marca SUMMA v1.0 (el host
  // puede cambiarla vía paletas o pasando colores explícitos) ──────────────
  static const navy        = Color(0xFF1F2A4E);  // navy.deep
  static const navyDeep    = Color(0xFF15203C);  // derivado (gradientes)
  static const navyMid     = Color(0xFF2C3A60);  // navy.halo
  static const steel       = Color(0xFF5D8BB6);  // azul.brand
  static const steelDeep   = Color(0xFF416F9A);  // azul.text
  static const steelLight  = Color(0xFFA9C2DA);
  static const amber       = Color(0xFFEAAA2F);  // dorado.brand
  static const amberLight  = Color(0xFFF4C463);
  static const slate       = Color(0xFF6B7592);
  static const mist        = Color(0xFF9AA3BC);
  static const ink         = Color(0xFF12182A);

  // ── Semánticos (manual v1.0, capa 2) ─────────────────────────────────────
  static const success     = Color(0xFF10B981);  // success.brand
  static const warning     = Color(0xFFD97706);  // warning.brand
  static const danger      = Color(0xFFDC2626);  // danger
  static const info        = Color(0xFF4D8AC0);

  // ── Superficies — neutros cálidos crema (manual 10.01) ───────────────────
  static const surface     = Color(0xFFF4EFE5);  // crema.base
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE3DFD9);  // muted cálido
  static const border      = Color(0xFFD6D3D0);  // borde cálido
  static const textPrimary = Color(0xFF1F2A4E);  // navy.deep
  static const textSub     = Color(0xFF6B7592);  // text-muted
  static const textMuted   = Color(0xFF9AA3BC);  // text-soft
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
