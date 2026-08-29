/// Sistema de **movimiento** SUMMA — duraciones, curvas y física.
///
/// Vive en el paquete de diseño y no en la app **por la misma razón que los
/// colores**: wannadi no puede depender de `summa_frontend` (sería un ciclo),
/// así que un token que viva arriba es un token que sus propios widgets no
/// pueden usar. La app lo reexporta desde `lib/themes/summa_tokens.dart`, de
/// modo que quien ya escribía `SummaMotion.base` no se entera de nada.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Sistema de **movimiento** SUMMA — duraciones y curvas de animación.
///
/// Filosofía: **sobrio y sutil**. Transiciones cortas que se sienten pulidas sin
/// llamar la atención. Usar siempre un token, nunca un `Duration(milliseconds: …)`
/// suelto.
///
/// ```dart
/// AnimatedContainer(duration: SummaMotion.fast, curve: SummaMotion.standard, …)
/// ```
///
/// **Tres peldaños, y no más.** Vale aquí la misma disciplina que en `SummaSpacing`
/// («el manual omite 5, 7, 9…»): si necesitás 180 ms, casi siempre querías
/// [base]. La diferencia de 20 ms no se percibe; treinta valores distintos
/// conviviendo, sí — se ven como descuido. Al migrar, el mapa es:
///
/// | Lo que había | Va a |
/// |---|---|
/// | ≤ 140 ms | [fast] |
/// | 150–220 ms | [base] |
/// | 240–400 ms | [slow] |
///
/// El corte de arriba **no es redondo por gusto**: hecho el inventario del repo
/// entero, los valores llegan hasta 400 y el siguiente es 600. El hueco es real,
/// así que la frontera cae donde los datos ya se separaban.
///
/// **Lo que NO entra en la escala**, y por dos motivos distintos:
///
/// * **Bucles ambientales** — shimmer, pulso, la campana. No van a ningún sitio:
///   respiran. Su tiempo es una cadencia, no una transición.
/// * **Revelación de un dato** — una barra que se llena hasta su valor (600,
///   900 ms). Tampoco es una transición de UI: está **contando una magnitud**, y
///   su tiempo lo manda la lectura, no el sistema. Acelerarla al ritmo del cromo
///   la volvería un parpadeo.
///
/// Los dos se quedan con su valor escrito donde se usan, y con el porqué al lado.
class SummaMotion {
  SummaMotion._();

  /// Micro-interacciones (hover, press, cambio de estado de un control).
  static const Duration fast = Duration(milliseconds: 120);

  /// Transiciones de UI (entradas, expand/collapse, selección).
  static const Duration base = Duration(milliseconds: 200);

  /// Movimientos mayores (hero, overlays, entradas escalonadas).
  static const Duration slow = Duration(milliseconds: 320);

  /// Curva estándar — la que se usa por defecto (sin rebote).
  static const Curve standard = Curves.easeOutCubic;

  /// Curva de énfasis para entradas — un poco más marcada, aún sin rebote.
  static const Curve emphasis = Curves.easeOut;

  /// El espejo de [standard], para el camino de **vuelta**.
  ///
  /// Una transición reversible entra y sale por el mismo camino: si la ida
  /// desacelera al llegar, la vuelta acelera al salir. Usar `standard` en ambos
  /// sentidos hace que el regreso se sienta pesado al arrancar.
  static const Curve standardReverse = Curves.easeInCubic;
}

/// Sistema de **física** SUMMA — resortes para lo que el dedo toca.
///
/// Una curva con duración fija no puede responder a una entrada nueva: si el
/// destino cambia a mitad de camino, reinicia desde velocidad cero y se siente
/// un «muro de ladrillo». Un resorte sí — arranca del valor que hay en pantalla
/// y acepta la velocidad que traía el gesto.
///
/// **Cuándo cada cosa:**
///
/// * Cambio de estado que nadie empujó → [SummaMotion] (curva + duración).
/// * Algo que el dedo arrastró y soltó → un resorte de aquí.
///
/// ### El rebote no es un estilo: es la física del gesto que lo lanzó (D-026)
///
/// Si nadie empujó, no rebota. Si el dedo lanzó, rebotar es contar la verdad
/// física del gesto. **Techo duro `ratio ≥ 0.85`**: ningún resorte de SUMMA
/// oscila visiblemente más de una vez — en una consola operativa, un rebote
/// grande se lee como juguete.
///
/// ### De Apple a Flutter
///
/// Apple describe sus resortes con `response` (segundos hasta alcanzar el
/// destino) y `damping ratio`. Flutter pide `stiffness`. La conversión es
/// exacta, y por eso vive en el código y no como un número mágico:
///
/// ```
/// stiffness = mass · (2π / response)²
/// ```
class SummaSpring {
  SummaSpring._();

  /// Traduce los parámetros de diseñador de Apple a los de Flutter.
  static SpringDescription _apple({
    required double response,
    required double ratio,
  }) => SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
    ratio: ratio,
  );

  /// **Sin rebote** (`response 0.4 s`, `ratio 1.0` → `stiffness ≈ 247`).
  ///
  /// Reposicionar algo, o cualquier cambio de estado que nadie empujó. Es el
  /// default: en la duda, éste.
  static final SpringDescription firme = _apple(response: 0.4, ratio: 1.0);

  /// **Hoja o panel arrastrable** (`response 0.3 s`, `ratio 0.85` → `≈ 439`).
  ///
  /// Más seco que [firme] porque una hoja tiene que llegar antes de que la
  /// vista se pregunte si llegó, y con un solo sobrepaso mínimo porque el dedo
  /// la soltó con velocidad.
  static final SpringDescription hoja = _apple(response: 0.3, ratio: 0.85);

  /// **Lanzamiento** de una ficha o tarjeta (`response 0.4 s`, `ratio 0.85`).
  ///
  /// Recorre más distancia que una hoja, así que se toma el mismo tiempo que
  /// [firme] pero conserva el acuse del lanzamiento.
  static final SpringDescription lanzada = _apple(response: 0.4, ratio: 0.85);

  /// Dónde habría parado el gesto si lo dejaras correr — la **proyección de
  /// momento** de Apple.
  ///
  /// No ancles al punto donde el dedo soltó: proyectá, y desde ahí elegí el
  /// ancla más cercana. Eso es lo que hace que un lanzamiento se sienta lanzado.
  ///
  /// ```dart
  /// final destino = anclaMasCercana(y + SummaSpring.proyecta(velocidadPxs));
  /// ```
  ///
  /// [velocidad] en px/s (tal cual sale de `DragEndDetails.velocity`).
  /// [desaceleracion] `0.998` da la sensación de un scroll normal; `0.99`, más
  /// seco. La fórmula de libro (`v²/2a`) **no** es ésta: Apple usa el
  /// decaimiento exponencial de su código de muestra.
  static double proyecta(double velocidad, [double desaceleracion = 0.998]) =>
      (velocidad / 1000) * desaceleracion / (1 - desaceleracion);

  /// **Banda elástica**: cuanto más te pasás del borde, menos te sigue.
  ///
  /// Un tope duro se lee como «se trabó»; la resistencia progresiva se lee como
  /// «responde, pero aquí se acabó». Las listas ya lo traen
  /// (`BouncingScrollPhysics`); los arrastres propios, no.
  ///
  /// [exceso] cuántos px te pasaste del límite · [dimension] el tamaño del eje
  /// que se arrastra.
  static double bandaElastica(
    double exceso,
    double dimension, {
    double constante = 0.55,
  }) =>
      (exceso * dimension * constante) /
      (dimension + constante * exceso.abs());
}
