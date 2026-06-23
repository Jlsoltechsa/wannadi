# wannadi — Usage Guide

This document describes the public API of wannadi and how to wire it into
a Flutter app. For a one-paragraph overview, see [README.md](README.md);
for release notes, see [CHANGELOG.md](CHANGELOG.md).

## Table of contents

1. [Installation](#installation)
2. [The single import](#the-single-import)
3. [Palettes and runtime theming](#palettes-and-runtime-theming)
4. [Semantic color tokens](#semantic-color-tokens)
5. [Responsive helpers](#responsive-helpers)
6. [`MultiViewList`](#multiviewlist)
7. [Presentation blocks](#presentation-blocks)
8. [Loading states](#loading-states)
9. [Brand defaults and fonts](#brand-defaults-and-fonts)
10. [Conventions](#conventions)

---

## Installation

### Git dependency

```yaml
dependencies:
  wannadi:
    git:
      url: https://gitea.gioser.net/sergio/wannadi.git
      ref: main
```

### Submodule + path dependency

```bash
git submodule add https://gitea.gioser.net/sergio/wannadi.git packages/wannadi
```

```yaml
dependencies:
  wannadi:
    path: packages/wannadi
```

Run `flutter pub get` and you are set.

---

## The single import

Every public symbol is re-exported from a single barrel file:

```dart
import 'package:wannadi/wannadi.dart';
```

There is no need to drill into `src/`. Internal files are considered
private and may be reorganized without notice.

---

## Palettes and runtime theming

wannadi ships five interchangeable palettes via the `SummaPalette` enum:

| Palette | Identifier | `brandDeep` | `brandAccent` |
|---|---|---|---|
| Classic | `classic` | Navy `#0E2452` | Amber `#EAAA2F` |
| Ocean | `ocean` | Deep blue `#0B2E4A` | Turquoise `#20C5B7` |
| Forest | `forest` | Forest green `#1F3D1E` | Wheat `#E0B344` |
| Sunset | `sunset` | Plum `#4A1A3A` | Coral `#FF8C5A` |
| Graphite | `graphite` | Charcoal `#1A1F2A` | Cobalt `#4A9EFF` |

Each palette exposes a fully-tuned `ColorScheme` for both light and dark
mode plus a `brandDeep` / `brandAccent` pair used by the presentation
widgets.

### Accessing the active palette from a widget

```dart
final palette = SummaPalette.ocean;
final scheme  = palette.light;  // or .dark
final deep    = palette.colors.brandDeep;
final accent  = palette.colors.brandAccent;
```

From any `BuildContext`:

```dart
Container(
  decoration: BoxDecoration(gradient: context.brandGradient),
  child: Icon(Icons.school, color: context.onBrand),
);
```

`context.brandDeep`, `context.brandAccent`, `context.onBrand`, and
`context.brandGradient` resolve against the palette returned by the
*palette resolver*. If no resolver is registered, the extension falls
back to `SummaPalette.classic`.

### Registering a palette resolver

If your app stores the active palette in a `ChangeNotifier` (or any
other inherited state), register a resolver once at startup. This lets
wannadi’s `context.brandDeep` etc. work without coupling the package to
your state management of choice.

```dart
import 'package:wannadi/wannadi.dart';
import 'package:provider/provider.dart';

void main() {
  setPaletteResolver((ctx) {
    return ctx.read<MyThemeProvider>().palette;
  });
  runApp(const MyApp());
}
```

The resolver is `SummaPalette? Function(BuildContext)`. Return `null`
to fall back to `SummaPalette.classic`.

### Persisting the choice

`SummaPaletteX` exposes `.id` and `.fromId(String?)` for round-tripping
the enum through `SharedPreferences`, query strings, or any other
string store:

```dart
final id = SummaPalette.forest.id;       // "forest"
final p  = SummaPaletteX.fromId('forest'); // SummaPalette.forest
```

### `.label` and `.swatch`

`palette.label` returns a localized display name (Spanish, since the
package was extracted from a Spanish-speaking project). `palette.swatch`
returns the primary color, useful for chip pickers.

---

## Semantic color tokens

The extension `WannadiSemanticColors on ColorScheme` exposes a small set
of tokens that adapt automatically to the brightness of the active
`ThemeData`:

| Getter | Light value | Dark value |
|---|---|---|
| `summaSurface` | `surface` | `surface` |
| `summaCard` | `#FFFFFF` | `#1C2540` |
| `summaMuted` | `#E7ECF4` | `#2A3550` |
| `summaBorder` | `#D9DEE9` | `#2D3756` |
| `summaTextPrimary` | `#12182A` | `#E7ECF4` |
| `summaTextSub` | `#5A6A8A` | `#9AAAC4` |

```dart
final cs = Theme.of(context).colorScheme;
Container(
  color: cs.summaCard,
  child: Text('Hello', style: TextStyle(color: cs.summaTextPrimary)),
);
```

For new code the package also ships the alias forms `wannadiCard`,
`wannadiMuted`, etc. (same values, friendlier name for projects with no
SUMMA heritage).

---

## Responsive helpers

```dart
const kCompactBreakpoint = 640;  // logical pixels
const kTabletBreakpoint  = 960;
```

Helpers:

- `isCompact(context)` — width < 640 px
- `isTablet(context)` — 640 ≤ width < 960 px
- `isDesktop(context)` — width ≥ 960 px
- `responsivePadding(context, {compact, desktop})` — adaptive
  `EdgeInsets.all`.
- `dialogMaxWidth(context, {preferred = 460})` — width capped to the
  viewport minus 48 px on small screens.
- `responsiveTable({required child})` — wraps a tabular widget
  (e.g. `DataTable`) with vertical + horizontal scroll so it never
  overflows.

### `ResponsiveTwoPane`

Master/detail layout that collapses to drill-down navigation on compact
screens.

```dart
ResponsiveTwoPane(
  hasSelection: selectedId != null,
  onBack: () => setState(() => selectedId = null),
  masterWidth: 320,
  master: StudentList(onTap: (id) => setState(() => selectedId = id)),
  detail: selectedId == null
      ? const EmptyState(icon: Icons.school, title: 'Select a student')
      : StudentDetail(id: selectedId!),
);
```

On compact screens the widget shows `master` by default and swaps to
`detail` with a floating back button once `hasSelection` is `true`.
On tablet/desktop both panels render side by side.

---

## `MultiViewList`

A single list widget with four interchangeable presentations.

### Columns

```dart
class MvColumn {
  final String key;        // path into the row; supports dotted paths
  final String label;      // header label
  final bool sortable;     // table mode only
  final double? width;     // table column width in px
  final String Function(Map<String, dynamic>)? formatter;
}
```

Dotted keys traverse nested maps: `MvColumn(key: 'address.city', ...)`.

### Modes

```dart
enum MvViewMode { cards, tiles, table, kanban }
```

- **cards** — compact one-line-per-record list.
- **tiles** — grid of rich cards with avatar, meta rows, optional stat.
- **table** — sortable, paginated `DataTable` with horizontal scroll.
- **kanban** — columns grouped by `groupBy`, with drag-and-drop between
  columns.

The user toggles between modes from the header. The first mode is
`cards`.

### Minimal example

```dart
MultiViewList(
  title: 'Students',
  heroIcon: Icons.school_rounded,
  heroColor: context.brandDeep,
  items: rows,
  primary: const MvColumn(key: 'name', label: 'Name'),
  columns: const [
    MvColumn(key: 'name',  label: 'Name',  width: 200),
    MvColumn(key: 'grade', label: 'Grade', width: 80),
  ],
  onTap: (row) => openDetail(row),
);
```

### Full example (all features)

```dart
MultiViewList(
  title: 'Students',
  subtitle: '${rows.length} enrolled',
  heroIcon: Icons.school_rounded,
  heroColor: context.brandDeep,

  items: rows,
  primary:   const MvColumn(key: 'name',   label: 'Name'),
  secondary: const MvColumn(key: 'email',  label: 'Email'),
  badge:     const MvColumn(key: 'status', label: 'Status'),

  metaColumns: const [
    MvColumn(key: 'grade',   label: 'Grade'),
    MvColumn(key: 'section', label: 'Section'),
  ],
  statColumn: MvColumn(
    key: 'average',
    label: 'Average',
    formatter: (r) => (r['average'] as num).toStringAsFixed(1),
  ),

  columns: const [
    MvColumn(key: 'name',    label: 'Name',    width: 200),
    MvColumn(key: 'grade',   label: 'Grade',   width: 100),
    MvColumn(key: 'section', label: 'Section', width: 100),
    MvColumn(key: 'average', label: 'Avg.',    width: 80),
  ],

  // Kanban grouping
  groupBy: const MvColumn(key: 'status', label: 'Status'),
  onMove: (row, newStatus) async {
    await api.updateStatus(row['id'], newStatus);
    refresh();
  },

  // Header action
  actionLabel: 'New',
  onAction: () => openCreateDialog(),

  onTap: (row) => openDetail(row),
  onBack: () => Navigator.of(context).pop(),
);
```

### `safeBack`

A drop-in `Navigator.maybePop` replacement that falls back to the root
route when the navigator cannot pop. Used internally by the header back
button when no `onBack` is provided.

```dart
safeBack(context);  // pops if possible, otherwise goes to '/'
```

---

## Presentation blocks

All of these accept their primary color as a parameter; pass
`context.brandDeep` to inherit the active palette.

### `GradientHero`

Top-of-screen hero block with gradient, decorative circles, optional
trailing chips. If `baseColor` is omitted, falls back to
`context.brandDeep`.

```dart
GradientHero(
  greeting: 'Good morning, María',
  subtitle: 'You have 3 pending alerts.',
  trailing: [
    ContextPill(icon: Icons.event, label: '2025-2026'),
    ContextPill(icon: Icons.group, label: 'Section A'),
  ],
);
```

### `PanelCard`

Theme-aware container (white in light mode, navy in dark mode) with a
subtle border and shadow. Use it whenever you would reach for `Card`
but want consistency with the rest of wannadi.

```dart
PanelCard(
  padding: const EdgeInsets.all(20),
  child: Column(children: [...]),
);
```

### `EmptyState`

```dart
EmptyState(
  icon: Icons.inbox_rounded,
  title: 'No messages',
  message: 'Inbox will populate once a teacher writes to this section.',
);
```

### `RoleBadge`

Compact pill colored by role name. The role-to-color mapping lives in
`WannadiColors.forRole(String?)` and currently understands `Admin`,
`Profesor`, `Representante`, `Estudiante`, and `Empleado`. Override by
extending the class or passing your own colored widget.

```dart
RoleBadge(role: 'Profesor', selected: true, onTap: () { /* … */ });
```

### `SectionHeader`

```dart
SectionHeader(
  title: 'Recent activity',
  icon: Icons.history,
  action: 'View all',
  onAction: () => Navigator.pushNamed(context, '/activity'),
);
```

### `ActivityRow`

```dart
ActivityRow(
  icon: Icons.payment_rounded,
  color: Colors.green,
  title: 'Tuition payment received',
  subtitle: 'María Pérez · Section A',
  trailing: 'just now',
  onTap: () => openTransaction(),
);
```

### `ModernStatCard` and `ActionCard`

KPI tile and quick-action tile respectively. Both take an icon, a
color, and a tap handler; see source for the few remaining knobs.

### `ContextPill`

Small chip used inside hero blocks (transparent background, light text).

### `DemoBanner`

An amber banner reminding the user a screen is showing seed data.
Useful during early development.

### `LetterAvatar`

```dart
LetterAvatar(letter: 'M', color: context.brandAccent, size: 40);
```

---

## Loading states

### `Shimmer`

Animated placeholder rectangle. Three named constructors cover the
common shapes:

```dart
Shimmer.line(width: 140, height: 12);
Shimmer.box(width: 80, height: 80, r: 12);
Shimmer.circle(size: 40);
```

### `ShimmerCardList`

Pre-composed card-row skeleton list — useful as the loading state for
any vertical list.

```dart
if (isLoading) return const ShimmerCardList(items: 6);
```

---

## Brand defaults and fonts

`WannadiColors` exposes the default brand palette (navy / amber), the
semantic colors (success / warning / danger / info), the surface tokens
used by light mode, and a `subject` list of six neutral accents for
categorical chips:

```dart
Color c = WannadiColors.subjectAt(i);  // wraps around
LinearGradient g = WannadiColors.gradientFor(WannadiColors.steel);
```

`WannadiFonts` lists the typography the kit prefers:

| Token | Suggested family | Fallback chain |
|---|---|---|
| `WannadiFonts.display` | Plus Jakarta Sans | DM Sans, Roboto, Helvetica, Arial, sans-serif |
| `WannadiFonts.body` | DM Sans | Plus Jakarta Sans, Roboto, … |
| `WannadiFonts.mono` | JetBrains Mono | — |

If the suggested families are not bundled with the app, Flutter falls
back to the platform default automatically.

---

## Conventions

- Every public widget accepts `super.key`.
- Color parameters always accept `Color`, never `MaterialColor`. Pass
  `context.brandDeep`, `Theme.of(context).colorScheme.primary`, or a
  raw `Color(0x…)`.
- Strings inside the kit (header labels, “Demo”, “Volver”) are Spanish
  by default. Wrap wannadi in your own localization layer if you need
  another language.
- Internal files under `lib/src/` are considered private.

---

## Reporting issues

Open an issue at the [wannadi tracker on Gitea](https://gitea.gioser.net/sergio/wannadi/issues).
