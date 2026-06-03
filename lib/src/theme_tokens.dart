import 'package:flutter/material.dart';

import 'colors.dart';

/// Tokens de color responsivos al brightness del theme, expuestos como
/// getters sobre `ColorScheme`. Úsalos en widgets que deban verse bien
/// en light y dark mode sin tener que detectar el brightness manualmente.
///
/// Mantienen el prefijo `sigma*` por motivos de retro-compatibilidad
/// histórica (extraídos del proyecto SIGMA). Para apps nuevas se sugieren
/// los alias `wannadi*`.
extension WannadiSemanticColors on ColorScheme {
  Color get sigmaSurface => surface;
  Color get sigmaCard =>
      brightness == Brightness.dark
          ? const Color(0xFF1C2540)
          : WannadiColors.surfaceCard;
  Color get sigmaMuted =>
      brightness == Brightness.dark
          ? const Color(0xFF2A3550)
          : WannadiColors.surfaceMuted;
  Color get sigmaBorder =>
      brightness == Brightness.dark
          ? const Color(0xFF2D3756)
          : WannadiColors.border;
  Color get sigmaTextPrimary =>
      brightness == Brightness.dark
          ? const Color(0xFFE7ECF4)
          : WannadiColors.textPrimary;
  Color get sigmaTextSub =>
      brightness == Brightness.dark
          ? const Color(0xFF9AAAC4)
          : WannadiColors.textSub;
  /// Tier "soft" — el más tenue (placeholders, captions secundarias).
  /// Equivale a `textMuted` en claro; en oscuro un gris-azul tenue legible.
  Color get sigmaTextSoft =>
      brightness == Brightness.dark
          ? const Color(0xFF74819E)
          : WannadiColors.textMuted;

  // Alias modernos (recomendados para apps nuevas).
  Color get wannadiSurface     => sigmaSurface;
  Color get wannadiCard        => sigmaCard;
  Color get wannadiMuted       => sigmaMuted;
  Color get wannadiBorder      => sigmaBorder;
  Color get wannadiTextPrimary => sigmaTextPrimary;
  Color get wannadiTextSub     => sigmaTextSub;
  Color get wannadiTextSoft    => sigmaTextSoft;
}
