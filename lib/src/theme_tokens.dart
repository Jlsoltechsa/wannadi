import 'package:flutter/material.dart';

import 'colors.dart';

/// Tokens de color responsivos al brightness del theme, expuestos como
/// getters sobre `ColorScheme`. Úsalos en widgets que deban verse bien
/// en light y dark mode sin tener que detectar el brightness manualmente.
///
/// Mantienen el prefijo `summa*` por motivos de retro-compatibilidad
/// histórica (extraídos del proyecto SUMMA). Para apps nuevas se sugieren
/// los alias `wannadi*`.
extension WannadiSemanticColors on ColorScheme {
  Color get summaSurface => surface;
  Color get summaCard =>
      brightness == Brightness.dark
          ? const Color(0xFF1C2540)
          : WannadiColors.surfaceCard;
  Color get summaMuted =>
      brightness == Brightness.dark
          ? const Color(0xFF2A3550)
          : WannadiColors.surfaceMuted;
  Color get summaBorder =>
      brightness == Brightness.dark
          ? const Color(0xFF2D3756)
          : WannadiColors.border;
  Color get summaTextPrimary =>
      brightness == Brightness.dark
          ? const Color(0xFFE7ECF4)
          : WannadiColors.textPrimary;
  Color get summaTextSub =>
      brightness == Brightness.dark
          ? const Color(0xFF9AAAC4)
          : WannadiColors.textSub;
  /// Tier "soft" — el más tenue (placeholders, captions secundarias).
  /// Equivale a `textMuted` en claro; en oscuro un gris-azul tenue legible.
  Color get summaTextSoft =>
      brightness == Brightness.dark
          ? const Color(0xFF74819E)
          : WannadiColors.textMuted;

  // Alias modernos (recomendados para apps nuevas).
  Color get wannadiSurface     => summaSurface;
  Color get wannadiCard        => summaCard;
  Color get wannadiMuted       => summaMuted;
  Color get wannadiBorder      => summaBorder;
  Color get wannadiTextPrimary => summaTextPrimary;
  Color get wannadiTextSub     => summaTextSub;
  Color get wannadiTextSoft    => summaTextSoft;
}
