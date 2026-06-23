# wannadi

A Material 3 UI kit for Flutter, focused on data-dense, multi-role
applications. Provides switchable list views (cards / tiles / table /
kanban), responsive layout helpers, and a set of pluggable color
palettes that any consumer app can switch at runtime.

Originally extracted from the SUMMA project and published as a standalone
library so other Flutter apps can adopt the same primitives.

## Features

- **`MultiViewList`** — a single list widget with four interchangeable
  presentations (cards, tiles, table, kanban), integrated search,
  per-column sorting, and group-by with drag-and-drop in kanban mode.
- **Presentation blocks** — `GradientHero`, `PanelCard`, `EmptyState`,
  `RoleBadge`, `ContextPill`, `LetterAvatar`. Opinionated building
  blocks for dashboards.
- **`ShimmerCardList`** — an animated placeholder for loading states.
- **Responsive helpers** — `isCompact()`, `dialogMaxWidth()`,
  `responsiveTable()`, `ResponsiveTwoPane` for screens that need to
  scale from phone to desktop without bespoke layouts per breakpoint.
- **Palette system** — five interchangeable palettes (Classic, Ocean,
  Forest, Sunset, Graphite). Each ships a light and dark `ColorScheme`
  plus a `brandDeep` / `brandAccent` pair, accessible from any widget
  via `context.brandDeep` and `context.brandAccent`.

## Installation

Add wannadi as a git dependency:

```yaml
dependencies:
  wannadi:
    git:
      url: https://gitea.gioser.net/sergio/wannadi.git
      ref: main
```

Or, if you are vendoring it as a submodule:

```yaml
dependencies:
  wannadi:
    path: packages/wannadi
```

## Quick start

```dart
import 'package:wannadi/wannadi.dart';

MultiViewList(
  title: 'Students',
  heroIcon: Icons.school_rounded,
  heroColor: context.brandDeep,
  items: rows,
  primary: const MvColumn(key: 'name', label: 'Name'),
  columns: const [
    MvColumn(key: 'name', label: 'Name', width: 200),
    MvColumn(key: 'id', label: 'ID', width: 120),
  ],
  onTap: (row) => openDetail(row),
);
```

See **[USAGE.md](USAGE.md)** for the full API reference, configuration
options, palette wiring, and end-to-end examples.

A runnable sample app lives in **[`example/`](example/)** — a small
reminders manager that persists locally with `shared_preferences` and
demonstrates `MultiViewList` (all four view modes), palette switching,
and the responsive helpers.

## Versioning

Follows [Semantic Versioning](https://semver.org/). Release notes live
in [`CHANGELOG.md`](CHANGELOG.md).

## Maintenance

wannadi is developed alongside SUMMA, its primary consumer. It lives as
a Git submodule inside `summa_frontend/packages/wannadi`, but the
repository is independent: changes are committed here first and SUMMA
bumps the submodule reference afterwards.

## Authors

- **Sergio Velásquez Zeballos** — original author and maintainer.
- **Claude** (Anthropic) — co-author of the framework extraction and
  the refactor into a reusable library.

### Acknowledgements

Thanks to Luis Mora, Jonathan López, and Jonathan Blando for their
support and trust, which made the development of this library possible.

## License

MIT — see [`LICENSE`](LICENSE).
