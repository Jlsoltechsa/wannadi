import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'colors.dart';
import 'theme_tokens.dart';
import 'modern_kit.dart';

/// Pop seguro para go_router. Si el stack tiene previo, hace `pop()` (y
/// resuelve cualquier `await context.push(...)` del caller). Si no, mira
/// `?from=…` en la URL actual; sino usa `fallback`.
void safeBack(BuildContext context, {String fallback = '/'}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  final state = GoRouterState.of(context);
  final from = state.uri.queryParameters['from'];
  if (from != null && from.isNotEmpty) {
    context.go(Uri.decodeComponent(from));
    return;
  }
  context.go(fallback);
}

/// Configuración de columna para tabla / acceso a campo en cards / kanban.
class MvColumn {
  final String key;
  final String label;
  final bool sortable;
  final double? width; // px en tabla
  final String Function(Map<String, dynamic>)? formatter;
  /// Color opcional del badge según su texto ya formateado. Si devuelve
  /// `null` (o no se define), el badge usa el `steel` por defecto. Útil
  /// para estados: 'Activo' en verde, 'Vencido' en rojo, etc.
  final Color? Function(String value)? badgeColorOf;
  const MvColumn({
    required this.key,
    required this.label,
    this.sortable = true,
    this.width,
    this.formatter,
    this.badgeColorOf,
  });

  String value(Map<String, dynamic> row) {
    final v = _read(row, key);
    if (formatter != null) return formatter!(row);
    if (v == null) return '—';
    return v.toString();
  }

  static dynamic _read(Map<String, dynamic> src, String key) {
    if (!key.contains('.')) return src[key];
    dynamic cur = src;
    for (final p in key.split('.')) {
      if (cur is Map && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        return null;
      }
    }
    return cur;
  }
}

enum MvViewMode { cards, tiles, table, kanban }

/// Parámetros que recibe un [MvTableBuilder] al pintar la vista "tabla".
/// La idea es que el llamador pueda sustituir el render por defecto por su
/// propio widget (por ejemplo un DataGrid externo) sin que `wannadi` tenga
/// que conocerlo.
class MvTableParams {
  final List<Map<String, dynamic>> rows;
  final List<MvColumn> columns;
  final String? sortKey;
  final bool sortAsc;
  final int page;
  final int pageSize;
  final void Function(String key, bool asc) onSort;
  final void Function(int page) onPage;
  final void Function(Map<String, dynamic>)? onTap;

  const MvTableParams({
    required this.rows,
    required this.columns,
    required this.sortKey,
    required this.sortAsc,
    required this.page,
    required this.pageSize,
    required this.onSort,
    required this.onPage,
    this.onTap,
  });
}

/// Función que pinta la vista "tabla". Si está registrada vía
/// [setMvTableBuilder], se usa en lugar del `_TableView` interno.
typedef MvTableBuilder = Widget Function(
    BuildContext context, MvTableParams params);

MvTableBuilder? _mvTableBuilder;

/// Registra (o limpia) el builder externo para la vista de tabla. Llamarla
/// una sola vez al arrancar la app — pasar `null` restaura el render
/// interno.
void setMvTableBuilder(MvTableBuilder? builder) {
  _mvTableBuilder = builder;
}

/// Lista con 4 vistas alternables: cards · tiles · tabla · kanban.
/// - `cards`: lista de tarjetas compactas (1 línea por registro).
/// - `tiles`: cuadrícula de tarjetas ricas (avatar, meta, stats).
/// - `table`: tabla paginable + ordenable.
/// - `kanban`: columnas agrupadas por `groupBy` con drag-drop entre columnas.
class MultiViewList extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData heroIcon;
  final Color heroColor;

  final List<Map<String, dynamic>> items;
  final List<MvColumn> columns;        // columnas para tabla
  final MvColumn primary;              // columna que actúa como título de card
  final MvColumn? secondary;           // subtítulo de card
  final MvColumn? badge;               // badge en card / chip en tabla

  /// Columnas adicionales que se muestran como filas con icono dentro de la
  /// tarjeta (modo tiles / kanban). Vacía → solo cabecera.
  final List<MvColumn> metaColumns;

  /// Columna que se resalta como "stat" al pie de la tarjeta. Si la columna
  /// expone `formatter`, se usa para el valor; el `label` es el rótulo.
  final MvColumn? statColumn;

  /// Para kanban: agrupar por valor de esta columna. Si null, el modo kanban
  /// igual está disponible y muestra una cuadrícula plana de tiles.
  final MvColumn? groupBy;

  final void Function(Map<String, dynamic>)? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Callback al soltar una card en otra columna (drag-drop kanban). Recibe
  /// el row movido y la nueva clave de grupo. El llamador es responsable de
  /// persistir el cambio (PUT) y refrescar la lista.
  final void Function(Map<String, dynamic> row, String newGroupKey)? onMove;

  /// Callback opcional al pulsar el botón de "atrás" del header. Si null,
  /// usa `_safeBack` (canPop o ir a `/`).
  final VoidCallback? onBack;

  /// Vista inicial. Cada pantalla elige la que mejor describa sus datos
  /// (tabla para admin tipo CRUD, tiles para registros con avatar/meta,
  /// kanban para flujos drag-drop). Default: `cards`.
  final MvViewMode initialView;

  /// Clave que identifica unívocamente cada fila (p. ej. `'id'`). Junto a
  /// [selectedId] permite resaltar el registro activo en master-detail.
  final String? idKey;

  /// Valor de [idKey] del registro actualmente seleccionado. La card / fila
  /// que lo tenga se pinta resaltada. Si null, nada queda resaltado.
  final Object? selectedId;

  const MultiViewList({
    super.key,
    required this.title,
    required this.heroIcon,
    required this.heroColor,
    required this.items,
    required this.columns,
    required this.primary,
    this.subtitle,
    this.secondary,
    this.badge,
    this.metaColumns = const [],
    this.statColumn,
    this.groupBy,
    this.onTap,
    this.actionLabel,
    this.onAction,
    this.onMove,
    this.onBack,
    this.initialView = MvViewMode.cards,
    this.idKey,
    this.selectedId,
  });

  @override
  State<MultiViewList> createState() => _MultiViewListState();
}

class _MultiViewListState extends State<MultiViewList> {
  late MvViewMode _mode = widget.initialView;
  String _query = '';
  String? _sortKey;
  bool _sortAsc = true;
  int _page = 0;
  static const _pageSize = 20;

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    var rows = q.isEmpty
        ? widget.items
        : widget.items.where((row) {
            return widget.columns.any((c) =>
                c.value(row).toLowerCase().contains(q));
          }).toList();
    if (_sortKey != null) {
      rows = [...rows];
      rows.sort((a, b) {
        final ca = widget.columns.firstWhere((c) => c.key == _sortKey,
            orElse: () => widget.primary);
        final av = ca.value(a);
        final bv = ca.value(b);
        return _sortAsc ? av.compareTo(bv) : bv.compareTo(av);
      });
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final pad = isWide ? 28.0 : 16.0;
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.heroIcon,
            color: widget.heroColor,
            count: filtered.length,
            actionLabel: widget.actionLabel,
            onAction: widget.onAction,
            onBack: widget.onBack,
          ),
          const SizedBox(height: 16),
          PanelCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Buscar…',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                    ),
                    onChanged: (v) => setState(() {
                      _query = v;
                      _page = 0;
                    }),
                  ),
                ),
                _ViewToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            PanelCard(
              child: const EmptyState(
                icon: Icons.inbox_rounded,
                title: 'Sin resultados',
              ),
            )
          else
            switch (_mode) {
              MvViewMode.cards  => _CardsView(
                  rows: filtered,
                  primary: widget.primary,
                  secondary: widget.secondary,
                  badge: widget.badge,
                  onTap: widget.onTap,
                  isWide: isWide,
                  idKey: widget.idKey,
                  selectedId: widget.selectedId,
                ),
              MvViewMode.tiles => _TilesView(
                  rows: filtered,
                  primary: widget.primary,
                  secondary: widget.secondary,
                  badge: widget.badge,
                  metaColumns: widget.metaColumns,
                  statColumn: widget.statColumn,
                  heroColor: widget.heroColor,
                  onTap: widget.onTap,
                  isWide: isWide,
                  idKey: widget.idKey,
                  selectedId: widget.selectedId,
                ),
              MvViewMode.table  => _mvTableBuilder != null
                  ? _mvTableBuilder!(
                      context,
                      MvTableParams(
                        rows: filtered,
                        columns: widget.columns,
                        sortKey: _sortKey,
                        sortAsc: _sortAsc,
                        page: _page,
                        pageSize: _pageSize,
                        onSort: (k, asc) => setState(() {
                          _sortKey = k;
                          _sortAsc = asc;
                        }),
                        onPage: (p) => setState(() => _page = p),
                        onTap: widget.onTap,
                      ),
                    )
                  : _TableView(
                      rows: filtered,
                      columns: widget.columns,
                      page: _page,
                      pageSize: _pageSize,
                      sortKey: _sortKey,
                      sortAsc: _sortAsc,
                      onSort: (k, asc) => setState(() {
                        _sortKey = k;
                        _sortAsc = asc;
                      }),
                      onPage: (p) => setState(() => _page = p),
                      onTap: widget.onTap,
                      idKey: widget.idKey,
                      selectedId: widget.selectedId,
                    ),
              MvViewMode.kanban => widget.groupBy == null
                  ? _TilesView(
                      rows: filtered,
                      primary: widget.primary,
                      secondary: widget.secondary,
                      badge: widget.badge,
                      metaColumns: widget.metaColumns,
                      statColumn: widget.statColumn,
                      heroColor: widget.heroColor,
                      onTap: widget.onTap,
                      isWide: isWide,
                    )
                  : _KanbanView(
                      rows: filtered,
                      groupBy: widget.groupBy!,
                      primary: widget.primary,
                      secondary: widget.secondary,
                      badge: widget.badge,
                      metaColumns: widget.metaColumns,
                      statColumn: widget.statColumn,
                      heroColor: widget.heroColor,
                      onTap: widget.onTap,
                      onMove: widget.onMove,
                    ),
            },
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onBack;
  const _Header({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      // En paneles angostos (p. ej. la lista dentro de un master-detail,
      // ~320 px) el ícono hero y el botón de acción comían el ancho y el
      // título quedaba con tan poco espacio que se partía palabra por
      // palabra. En compacto se retira el ícono hero y la acción se
      // reduce a su signo "+".
      final compact = c.maxWidth < 460;
      final iconOnlyAction = c.maxWidth < 380;
      return Row(
        children: [
          IconButton(
            tooltip: 'Atrás',
            onPressed: onBack ?? () => safeBack(context),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.sigmaMuted,
              foregroundColor: cs.sigmaTextPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 12),
          if (!compact) ...[
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: WannadiColors.gradientFor(color),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: cs.sigmaTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '$count ${subtitle ?? "registros"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.sigmaTextSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            if (iconOnlyAction)
              IconButton.filled(
                tooltip: actionLabel,
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
              )
            else
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
          ],
        ],
      );
    });
  }
}

class _ViewToggle extends StatelessWidget {
  final MvViewMode mode;
  final ValueChanged<MvViewMode> onChanged;
  const _ViewToggle({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SegmentedButton<MvViewMode>(
      style: SegmentedButton.styleFrom(
        side: BorderSide(color: cs.sigmaBorder),
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(
          value: MvViewMode.cards,
          icon: Icon(Icons.view_agenda_rounded, size: 16),
          tooltip: 'Tarjetas',
        ),
        ButtonSegment(
          value: MvViewMode.tiles,
          icon: Icon(Icons.dashboard_rounded, size: 16),
          tooltip: 'Mosaico',
        ),
        ButtonSegment(
          value: MvViewMode.table,
          icon: Icon(Icons.table_rows_rounded, size: 16),
          tooltip: 'Tabla',
        ),
        ButtonSegment(
          value: MvViewMode.kanban,
          icon: Icon(Icons.view_kanban_rounded, size: 16),
          tooltip: 'Kanban',
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARDS view
// ─────────────────────────────────────────────────────────────────────────────

class _CardsView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final void Function(Map<String, dynamic>)? onTap;
  final bool isWide;
  final String? idKey;
  final Object? selectedId;
  const _CardsView({
    required this.rows,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.onTap,
    required this.isWide,
    this.idKey,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final cols = isWide ? 2 : 1;
    return LayoutBuilder(builder: (ctx, c) {
      const spacing = 12.0;
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final row in rows)
            SizedBox(
              width: w,
              child: _PersonaCard(
                row: row,
                primary: primary,
                secondary: secondary,
                badge: badge,
                onTap: onTap == null ? null : () => onTap!(row),
                selected: idKey != null && selectedId != null &&
                    row[idKey] == selectedId,
              ),
            ),
        ],
      );
    });
  }
}

/// Tarjeta compacta (1 línea, modo `cards`).
class _PersonaCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final VoidCallback? onTap;
  final bool selected;

  const _PersonaCard({
    required this.row,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.onTap,
    this.selected = false,
  });

  String _initials(String s) {
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = primary.value(row);
    final sub = secondary?.value(row);
    final badgeText = badge?.value(row);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? WannadiColors.steel.withValues(alpha: 0.10)
                : cs.sigmaCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? WannadiColors.steel : cs.sigmaBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:
                    cs.brightness == Brightness.dark ? 0.18 : 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: WannadiColors.gradientFor(WannadiColors.steel),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cs.sigmaTextPrimary,
                      ),
                    ),
                    if (sub != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.sigmaTextSub,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (badgeText != null && badgeText != '—')
                Builder(builder: (_) {
                  final bc = badge?.badgeColorOf?.call(badgeText)
                      ?? WannadiColors.steel;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bc.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: bc,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta rica (avatar grande, meta rows, stat). Se usa en `tiles` y kanban.
class _RichTile extends StatefulWidget {
  final Map<String, dynamic> row;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final List<MvColumn> metaColumns;
  final MvColumn? statColumn;
  final Color accent;
  final VoidCallback? onTap;
  final bool dense;
  final bool selected;
  const _RichTile({
    required this.row,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.metaColumns,
    required this.statColumn,
    required this.accent,
    required this.onTap,
    this.dense = false,
    this.selected = false,
  });
  @override
  State<_RichTile> createState() => _RichTileState();
}

class _RichTileState extends State<_RichTile> {
  bool _hover = false;

  String _initials(String s) {
    final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  IconData _iconForKey(String key) {
    if (key.contains('email')) return Icons.alternate_email_rounded;
    if (key.contains('phone') || key.contains('tel')) {
      return Icons.phone_rounded;
    }
    if (key.contains('cedula') || key.contains('document')) {
      return Icons.badge_rounded;
    }
    if (key.contains('seccion') || key.contains('grado')) {
      return Icons.class_rounded;
    }
    if (key.contains('parentesco') || key.contains('rol')) {
      return Icons.family_restroom_rounded;
    }
    if (key.contains('cargo') || key.contains('especialidad')) {
      return Icons.work_outline_rounded;
    }
    if (key.contains('inscripcion')) return Icons.confirmation_number_rounded;
    if (key.contains('departamento')) return Icons.apartment_rounded;
    if (key.contains('fecha') || key.contains('date')) {
      return Icons.event_rounded;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.primary.value(widget.row);
    final sub = widget.secondary?.value(widget.row);
    final badgeText = widget.badge?.value(widget.row);
    final hasBadge = badgeText != null && badgeText != '—';
    final visibleMeta = widget.metaColumns
        .where((c) {
          final v = c.value(widget.row);
          return v.isNotEmpty && v != '—';
        })
        .toList();
    final statValue = widget.statColumn?.value(widget.row);
    final hasStat = statValue != null && statValue.isNotEmpty && statValue != '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accent.withValues(alpha: 0.08)
                  : cs.sigmaCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.selected ? widget.accent : cs.sigmaBorder,
                width: widget.selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:
                      _hover ? 0.18 : (cs.brightness == Brightness.dark ? 0.18 : 0.05)),
                  blurRadius: _hover ? 14 : 8,
                  offset: Offset(0, _hover ? 6 : 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Franja superior con el color de acento (clip a las
                // esquinas del contenedor padre via clipBehavior).
                Container(height: 3, color: widget.accent),
                Padding(
                  padding: EdgeInsets.all(widget.dense ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: widget.dense ? 40 : 50,
                      height: widget.dense ? 40 : 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.accent,
                            widget.accent.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                          fontSize: widget.dense ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.dense ? 13 : 15,
                              fontWeight: FontWeight.w800,
                              color: cs.sigmaTextPrimary,
                            ),
                          ),
                          if (sub != null && sub != '—')
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasBadge)
                      Builder(builder: (_) {
                        final bc = widget.badge
                                ?.badgeColorOf?.call(badgeText)
                            ?? widget.accent;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bc.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: bc,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                if (visibleMeta.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: cs.sigmaBorder),
                  const SizedBox(height: 10),
                  for (int i = 0; i < visibleMeta.length; i++) ...[
                    Row(
                      children: [
                        Icon(_iconForKey(visibleMeta[i].key),
                            size: 14, color: cs.sigmaTextSub),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            visibleMeta[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.sigmaTextSub,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            visibleMeta[i].value(widget.row),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.sigmaTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (i < visibleMeta.length - 1) const SizedBox(height: 6),
                  ],
                ],
                if (hasStat) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.statColumn!.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.sigmaTextSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          statValue,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: widget.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula de tiles (modo `tiles` o kanban sin groupBy).
class _TilesView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final List<MvColumn> metaColumns;
  final MvColumn? statColumn;
  final Color heroColor;
  final void Function(Map<String, dynamic>)? onTap;
  final bool isWide;
  final String? idKey;
  final Object? selectedId;
  const _TilesView({
    required this.rows,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.metaColumns,
    required this.statColumn,
    required this.heroColor,
    required this.onTap,
    required this.isWide,
    this.idKey,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      const spacing = 14.0;
      final cols = c.maxWidth >= 1100
          ? 3
          : c.maxWidth >= 720
              ? 2
              : 1;
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final row in rows)
            SizedBox(
              width: w,
              child: _RichTile(
                row: row,
                primary: primary,
                secondary: secondary,
                badge: badge,
                metaColumns: metaColumns,
                statColumn: statColumn,
                accent: heroColor,
                onTap: onTap == null ? null : () => onTap!(row),
                selected: idKey != null && selectedId != null &&
                    row[idKey] == selectedId,
              ),
            ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE view (paginable + ordenable)
// ─────────────────────────────────────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final List<MvColumn> columns;
  final int page;
  final int pageSize;
  final String? sortKey;
  final bool sortAsc;
  final void Function(String, bool) onSort;
  final ValueChanged<int> onPage;
  final void Function(Map<String, dynamic>)? onTap;
  final String? idKey;
  final Object? selectedId;
  const _TableView({
    required this.rows,
    required this.columns,
    required this.page,
    required this.pageSize,
    required this.sortKey,
    required this.sortAsc,
    required this.onSort,
    required this.onPage,
    required this.onTap,
    this.idKey,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, rows.length);
    final pageRows = rows.sublist(start, end);
    final totalPages = (rows.length / pageSize).ceil().clamp(1, 9999);

    return PanelCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Cabecera
          Container(
            decoration: BoxDecoration(
              color: cs.sigmaMuted,
              border: Border(bottom: BorderSide(color: cs.sigmaBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in columns)
                    _HeaderCell(
                      label: c.label,
                      width: c.width ?? 160,
                      sorted: sortKey == c.key,
                      ascending: sortAsc,
                      sortable: c.sortable,
                      onTap: c.sortable
                          ? () => onSort(c.key,
                              sortKey == c.key ? !sortAsc : true)
                          : null,
                    ),
                ],
              ),
            ),
          ),
          // Filas
          for (int i = 0; i < pageRows.length; i++)
            InkWell(
              onTap: onTap == null ? null : () => onTap!(pageRows[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: (idKey != null && selectedId != null &&
                          pageRows[i][idKey] == selectedId)
                      ? WannadiColors.steel.withValues(alpha: 0.10)
                      : (i.isEven ? cs.sigmaCard : cs.sigmaSurface),
                  border: Border(bottom: BorderSide(color: cs.sigmaBorder)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in columns)
                        _BodyCell(
                          width: c.width ?? 160,
                          text: c.value(pageRows[i]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // Paginación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${start + 1}-$end de ${rows.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.sigmaTextSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed:
                      page == 0 ? null : () => onPage(page - 1),
                ),
                Text(
                  '${page + 1} / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                IconButton(
                  tooltip: 'Siguiente',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: page + 1 >= totalPages
                      ? null
                      : () => onPage(page + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final bool sorted;
  final bool ascending;
  final bool sortable;
  final VoidCallback? onTap;
  const _HeaderCell({
    required this.label,
    required this.width,
    required this.sorted,
    required this.ascending,
    required this.sortable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: sorted
                      ? WannadiColors.steel
                      : Theme.of(context).colorScheme.sigmaTextSub,
                ),
              ),
            ),
            if (sortable)
              Icon(
                sorted
                    ? (ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                    : Icons.unfold_more_rounded,
                size: 14,
                color: sorted ? WannadiColors.steel : WannadiColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final double width;
  final String text;
  const _BodyCell({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.sigmaTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KANBAN view
// ─────────────────────────────────────────────────────────────────────────────

class _KanbanView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final MvColumn groupBy;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final List<MvColumn> metaColumns;
  final MvColumn? statColumn;
  final Color heroColor;
  final void Function(Map<String, dynamic>)? onTap;
  final void Function(Map<String, dynamic>, String)? onMove;
  const _KanbanView({
    required this.rows,
    required this.groupBy,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.metaColumns,
    required this.statColumn,
    required this.heroColor,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final g = groupBy.value(r);
      groups.putIfAbsent(g, () => []).add(r);
    }
    final orden = groups.keys.toList()..sort();

    return SizedBox(
      height: 620,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final key in orden)
              _KanbanColumn(
                groupKey: key,
                rows: groups[key]!,
                primary: primary,
                secondary: secondary,
                badge: badge,
                metaColumns: metaColumns,
                statColumn: statColumn,
                heroColor: heroColor,
                onTap: onTap,
                onAccept: onMove == null
                    ? null
                    : (row) => onMove!(row, key),
              ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  final String groupKey;
  final List<Map<String, dynamic>> rows;
  final MvColumn primary;
  final MvColumn? secondary;
  final MvColumn? badge;
  final List<MvColumn> metaColumns;
  final MvColumn? statColumn;
  final Color heroColor;
  final void Function(Map<String, dynamic>)? onTap;
  final void Function(Map<String, dynamic>)? onAccept;

  const _KanbanColumn({
    required this.groupKey,
    required this.rows,
    required this.primary,
    required this.secondary,
    required this.badge,
    required this.metaColumns,
    required this.statColumn,
    required this.heroColor,
    required this.onTap,
    required this.onAccept,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _highlight = false;

  Color _colorForKey() {
    final h = widget.groupKey.codeUnits.fold<int>(0, (a, b) => a + b);
    return WannadiColors.subjectAt(h);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _colorForKey();
    final canDrop = widget.onAccept != null;

    Widget content = Container(
      width: 300,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: _highlight
            ? color.withValues(alpha: 0.10)
            : cs.sigmaMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _highlight ? color : cs.sigmaBorder,
          width: _highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera. Stripe izquierda como Positioned dentro de Stack
          // (Border non-uniform + radius es ilegal).
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  color: color.withValues(alpha: 0.14),
                  child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.groupKey,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.sigmaCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.rows.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
                ),
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(width: 4, color: color),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.rows.length,
              itemBuilder: (_, i) {
                final r = widget.rows[i];
                final card = _RichTile(
                  row: r,
                  primary: widget.primary,
                  secondary: widget.secondary,
                  badge: widget.badge,
                  metaColumns: widget.metaColumns,
                  statColumn: widget.statColumn,
                  accent: color,
                  onTap: widget.onTap == null ? null : () => widget.onTap!(r),
                  dense: true,
                );
                final wrapped = canDrop
                    ? LongPressDraggable<Map<String, dynamic>>(
                        data: r,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                          child: SizedBox(width: 280, child: card),
                        ),
                        childWhenDragging: Opacity(opacity: 0.4, child: card),
                        child: card,
                      )
                    : card;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: wrapped,
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!canDrop) return content;
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final draggedKey = widget.primary.value(details.data);
        final draggedGroup = (details.data['__group__'] as String?) ?? '';
        // Evitar resaltar si la card ya está en esta columna (acepta pero
        // no hay efecto visual fuerte).
        setState(() => _highlight = true);
        return draggedKey != widget.groupKey || draggedGroup != widget.groupKey;
      },
      onLeave: (_) => setState(() => _highlight = false),
      onAcceptWithDetails: (details) {
        setState(() => _highlight = false);
        widget.onAccept!(details.data);
      },
      builder: (_, __, ___) => content,
    );
  }
}
