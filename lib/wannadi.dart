/// wannadi — Material 3 UI kit en Flutter.
///
/// Importa este archivo y tendrás disponible todo el kit en un sólo
/// símbolo:
///
/// ```dart
/// import 'package:wannadi/wannadi.dart';
/// ```
library;

// Tokens semánticos y de marca por defecto.
export 'src/colors.dart';
export 'src/theme_tokens.dart';
export 'src/motion.dart';

// Layout / responsive helpers.
export 'src/responsive.dart';

// Paletas conmutables + extensión BuildContext.brandDeep/.brandAccent.
export 'src/palettes.dart';

// Bloques de presentación.
export 'src/modern_kit.dart';
export 'src/summa_card.dart';
export 'src/letteravatar.dart';
export 'src/shimmer.dart';

// Listas con vistas alternables.
export 'src/multi_view_list.dart' show
    MvColumn,
    MvViewMode,
    MultiViewList,
    MvTableParams,
    MvTableBuilder,
    setMvTableBuilder,
    safeBack;
