import 'package:flutter/material.dart';

import 'colors.dart';
import 'palettes.dart';
import 'theme_tokens.dart';

import 'motion.dart';
/// Variante semántica de [SummaCard]. Define color de borde, tinte de
/// fondo y color del chip de status (cuando aplica).
enum SummaCardVariant {
  /// Sin tinte. Borde gris suave. Para listados y cards informativas.
  neutral,

  /// Azul informativo.
  info,

  /// Verde.
  success,

  /// Ámbar.
  warning,

  /// Rojo.
  danger,

  /// Sigue la paleta de marca activa (vía `context.brandAccent`).
  accent,
}

/// Card unificada del kit. Reemplaza la familia de cards ad-hoc que
/// vivían dispersas por una app: action tiles, info cards, accent
/// cards (warning/danger), cards colapsables, etc.
///
/// Funcionalidad:
/// - Header con `leading` (icono/avatar opcional), `title`, `subtitle`.
/// - `trailing` opcional al final del header (chip, badge…).
/// - `body` opcional debajo del header.
/// - `onTap` para hacer la card tappable, con hover y ripple.
/// - `variant` para tintar borde/fondo según semántica.
/// - `accentColor` para sobrescribir el color de la variante (útil
///   cuando cada tile tiene su propio color, p.ej. menús admin).
/// - `collapsible` esconde el body detrás de un chevron en el header.
///
/// Theming:
/// - Fondo claro: blanco; oscuro: `cs.summaCard` (navy oscuro). Ambos
///   con el tinte de variant aplicado al 6% (claro) / 12% (oscuro).
/// - Borde: color de la variant al 35% de opacidad por default; sube a
///   80% cuando está hovered.
/// - Texto: `cs.summaTextPrimary` y `cs.summaTextSub`.
class SummaCard extends StatefulWidget {
  const SummaCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.body,
    this.trailing,
    this.onTap,
    this.variant = SummaCardVariant.neutral,
    this.accentColor,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.padding,
    this.dense = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? body;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SummaCardVariant variant;

  /// Si está presente, sobrescribe el color que tomaría la variante.
  /// Útil para tiles donde cada uno tiene su propio color de marca.
  final Color? accentColor;

  final bool collapsible;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? padding;

  /// Modo compacto: padding más pequeño, fuente del título 14 en vez
  /// de 15. Para usar en filas densas (listas, mosaicos compactos).
  final bool dense;

  @override
  State<SummaCard> createState() => _SummaCardState();
}

class _SummaCardState extends State<SummaCard> {
  bool _hover = false;
  late bool _expanded = widget.initiallyExpanded;

  Color _variantColor(BuildContext context) {
    if (widget.accentColor != null) return widget.accentColor!;
    switch (widget.variant) {
      case SummaCardVariant.neutral:
        return Theme.of(context).colorScheme.outline;
      case SummaCardVariant.info:
        return WannadiColors.info;
      case SummaCardVariant.success:
        return WannadiColors.success;
      case SummaCardVariant.warning:
        return WannadiColors.warning;
      case SummaCardVariant.danger:
        return WannadiColors.danger;
      case SummaCardVariant.accent:
        return context.brandAccent;
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final color = _variantColor(context);
    final tappable = widget.onTap != null || widget.collapsible;

    // Tinte de fondo. Neutral en dark se queda con summaCard pelado.
    final Color tint = widget.variant == SummaCardVariant.neutral
        ? Colors.transparent
        : color.withValues(alpha: isDark ? 0.12 : 0.06);
    final Color base = cs.summaCard;
    final Color background = tint == Colors.transparent
        ? base
        : Color.alphaBlend(tint, base);

    // Borde: más fuerte en hover.
    final double borderAlpha = widget.variant == SummaCardVariant.neutral
        ? (_hover ? 0.45 : 0.0)
        : (_hover ? 0.8 : 0.35);
    final Color borderColor = widget.variant == SummaCardVariant.neutral
        ? (_hover
            ? color.withValues(alpha: borderAlpha)
            : cs.summaBorder)
        : color.withValues(alpha: borderAlpha);

    final EdgeInsets pad = (widget.padding ??
            EdgeInsets.all(widget.dense ? 12 : 16))
        .resolve(Directionality.of(context));

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.trailing,
          color: color,
          dense: widget.dense,
          collapsible: widget.collapsible,
          expanded: _expanded,
        ),
        if (widget.body != null) ...[
          if (widget.collapsible)
            AnimatedSize(
              duration: SummaMotion.base,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expanded ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          height: 1,
                          color: cs.summaBorder,
                        ),
                        const SizedBox(height: 12),
                        widget.body!,
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: widget.body!,
            ),
        ],
      ],
    );

    Widget content = AnimatedContainer(
      duration: SummaMotion.base,
      padding: pad,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: _hover ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.variant == SummaCardVariant.neutral
                    ? Colors.black
                    : color)
                .withValues(alpha: _hover ? 0.12 : 0.04),
            blurRadius: _hover ? 14 : 8,
            offset: Offset(0, _hover ? 6 : 3),
          ),
        ],
      ),
      child: inner,
    );

    if (!tappable) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          if (widget.collapsible && widget.onTap == null) {
            _toggle();
          } else {
            widget.onTap?.call();
          }
        },
        child: content,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    required this.dense,
    required this.collapsible,
    required this.expanded,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color color;
  final bool dense;
  final bool collapsible;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: dense ? 10 : 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: dense ? 13.5 : 15,
                  fontWeight: FontWeight.w800,
                  color: cs.summaTextPrimary,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: dense ? 2 : 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: dense ? 11.5 : 12.5,
                    color: cs.summaTextSub,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
        if (collapsible) ...[
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: expanded ? 0.0 : -0.25,
            duration: SummaMotion.base,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: cs.summaTextSub,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }
}

/// Helper de uso frecuente: cuadrado redondeado con un icono tintado
/// del color de la card. Pensado para pasarlo a [SummaCard.leading].
class SummaCardIcon extends StatelessWidget {
  const SummaCardIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
