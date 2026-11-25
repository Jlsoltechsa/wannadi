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
  /// En oscuro `#232E4A` («el intermedio»): sobre el fondo `#14213F` da 1,18:1.
  /// Con el `#1C2540` de antes eran 1,05:1 y la tarjeta no se separaba del fondo.
  Color get summaCard =>
      brightness == Brightness.dark
          ? const Color(0xFF232E4A)
          : WannadiColors.surfaceCard;
  /// Oscuro: `#2F3B58`, un paso por encima de la tarjeta (1,21:1). Con la tarjeta
  /// nueva el `#2A3550` de antes quedaba en 1,10:1 y no se distinguía de ella.
  Color get summaMuted =>
      brightness == Brightness.dark
          ? const Color(0xFF2F3B58)
          : WannadiColors.surfaceMuted;
  /// Oscuro: `#36425F`, sobre la tarjeta 1,35:1 (antes 1,29:1 sobre la vieja);
  /// el `#2D3756` de antes habría quedado en 1,15:1.
  Color get summaBorder =>
      brightness == Brightness.dark
          ? const Color(0xFF36425F)
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
