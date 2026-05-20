# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/);
versionado siguiendo [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] — 2026-05-20

### Cambiado — fusión maiwei + cola → wannadi

- El paquete `maiwei` (kit de UI) y `cola` (cola offline) se fusionaron en
  **wannadi** (`https://gitea.gioser.net/sergio/wannadi-flutter`).
- `package:wannadi/wannadi.dart` — el kit de UI Material 3 (antes
  `package:maiwei/maiwei.dart`).
- `package:wannadi/queue.dart` — la cola offline local-first (antes
  `package:cola/cola.dart`). Clases `Cola` / `ColaEvent` / `ColaEventResult`
  sin cambios.
- Sin cambios funcionales: sólo renombre de paquete e imports.

## [0.3.0] — 2026-05-14

### Added — runtime brand colors

- **`PaletteColors.fromBrand(primary, accent)`** — factory que construye una `PaletteColors` a partir de dos colores. El `primary` actúa como seed del `ColorScheme.fromSeed` (light / dark) y como `brandDeep`; el `accent` se inyecta como `secondary` del scheme y como `brandAccent`. Apps que persisten su esquema visual en base de datos pueden construir la paleta en runtime sin un enum de variantes.
- **`setPaletteColorsResolver(fn)`** — setter paralelo a `setPaletteResolver`. Si está registrado, tiene prioridad. Permite que la paleta se resuelva como `PaletteColors` directo en vez de pasar por el enum `SigmaPalette`.

### Changed

- `BrandColorsOf.brandDeep` y `.brandAccent` ahora pasan por `_resolvePaletteColors` (que mira primero el nuevo resolver). Apps que solo registran el resolver legacy siguen funcionando.

## [0.2.0] — 2026-05-14

### Added — SigmaCard

Card unificada que reemplaza la familia de cards ad-hoc dispersas por una app: action tiles, info cards, accent cards (warning/danger), cards colapsables.

- **`SigmaCard`** — header con `leading` + `title` + `subtitle` + `trailing`, body opcional debajo, `onTap` opcional, soporte de hover con elevación animada.
- **`SigmaCardVariant`** — `neutral / info / success / warning / danger / accent` — tinta borde + fondo. `accent` toma `context.brandAccent`.
- **`accentColor`** opcional sobrescribe el color de la variante (útil cuando cada tile tiene su propio color de marca, p.ej. mosaicos admin).
- **`collapsible: true`** esconde el body detrás de un chevron en el header con `AnimatedSize`.
- **`dense: true`** baja padding y typography para listas densas.
- **`SigmaCardIcon`** — helper para construir el cuadrado redondeado con icono tintado que va en `leading`.

Diseñada para uniformidad: usa `cs.sigmaCard` / `cs.sigmaBorder` / `cs.sigmaTextPrimary` / `cs.sigmaTextSub` de `WannadiSemanticColors`, así el dark mode funciona sin trabajo extra del caller.

## [0.1.3] — 2026-05-13

### Added

- `example/` — a small Reminders app that demonstrates `MultiViewList`
  (cards / tiles / table / kanban with drag-drop), `EmptyState`,
  runtime palette switching with `setPaletteResolver`, and
  `dialogMaxWidth`. Persists the list and the selected palette with
  `shared_preferences`. Single-file (~400 lines), `flutter analyze`
  clean. Platform scaffolding is gitignored; generate it with
  `flutter create --platforms=… .` before running.

## [0.1.2] — 2026-05-13

### Docs

- README rewritten in English; removed the colloquial origin-of-name
  blurb, tightened the wording for an external audience.
- Added `USAGE.md` covering the full public API (palettes, semantic
  tokens, responsive helpers, `MultiViewList`, presentation blocks,
  shimmer, brand defaults). Linked from README.
- Acknowledgements section added to the authors block.

## [0.1.1] — 2026-05-13

### Fixed

- `letteravatar.dart`: import sobrante de `colors.dart` (la clase no usa
  tokens — el color lo pasa el caller).

## [0.1.0] — 2026-05-13

### Added — primer release de wannadi

Extracción del UI kit del proyecto SIGMA a una librería independiente:

- **`MultiViewList`** con cuatro vistas alternables (cards, tiles, tabla,
  kanban), búsqueda integrada, ordenamiento por columna, group-by y
  drag-drop entre columnas en modo kanban.
- **Modern kit**: `GradientHero`, `PanelCard`, `EmptyState`,
  `RoleBadge`, `ContextPill`, `LetterAvatar`. Bloques de presentación
  con identidad propia para dashboards.
- **`ShimmerCardList`** — placeholder animado.
- **`responsive.dart`** — `isCompact()` (breakpoint 640px),
  `dialogMaxWidth()`, `responsiveTable()` (doble scroll para DataTables
  estrechas), `ResponsiveTwoPane` (master+detail con drill-down en
  compact).
- **`palettes.dart`** — cinco paletas conmutables (Clásico, Océano,
  Bosque, Atardecer, Grafito) cada una con `ColorScheme` light/dark
  cuadrado y un par `brandDeep`/`brandAccent`. Extension
  `BuildContext.brandDeep` / `.brandAccent` para que cualquier widget
  herede la paleta activa sin acoplarse al provider de theme del host.
