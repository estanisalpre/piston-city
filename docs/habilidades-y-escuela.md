# Sistema de Habilidades y Escuela de Mecánica

> Documento de diseño. Define el sistema completo a futuro (más allá del MVP). No todo esto se implementa ya — sirve como mapa para que cada feature que construyamos (Trabajos, Escuela, Talleres, Empleados) encaje sin rehacer nada.

---

## 1. Filosofía

El jugador empieza sabiendo lo mínimo de cada área. Todo lo demás se desbloquea **jugando y estudiando**, nunca comprando ventaja directa (coherente con la regla "No Pay To Win" de `CLAUDE.md`).

Hay **10 habilidades**. Cada habilidad tiene **5 niveles**. El nivel 1 es gratis para todas — es el "sentido común" que cualquier persona junta con el auto de su tío. Del nivel 2 al 5 hay que **estudiarlos en la Escuela de Mecánica**, pagando dinero + experiencia acumulada de esa habilidad específica.

Esto significa: dos jugadores pueden terminar el juego con talleres completamente distintos. Uno se especializa en pintura y estética, otro en motor y potencia. Ninguno es "mejor" — son builds distintos, como en un RPG.

---

## 2. Cómo funciona la progresión (mecánica de EXP)

- Cada habilidad tiene su **propia barra de experiencia**, independiente de las demás.
- Se gana EXP de una habilidad **haciendo trabajos de esa habilidad** (ver app "Trabajos"). Cambiar neumáticos da EXP de Neumáticos. Pintar un guardabarros da EXP de Pintura. Nunca se mezclan entre sí.
- La EXP **se acumula hasta el tope del nivel siguiente y ahí se detiene** — no sigue sumando de más. Ejemplo: para pasar de nivel 1 a nivel 2 de Mecánica General se necesitan 100 EXP. Si el jugador junta 100 y no compra el nivel todavía, se queda en 100 (no en 250) hasta que lo compre.
- Comprar el nivel en la Escuela **consume esa EXP** (vuelve a 0) y el contador empieza a acumular hacia el siguiente umbral, que ahora es más alto.
- Comprar un nivel también cuesta **dinero**, además de la EXP. Es una doble inversión: tiempo jugado (EXP) + dinero ganado (costo).
- Si el jugador nunca hace trabajos de una habilidad, esa barra nunca avanza y esa rama de la Escuela queda bloqueada para siempre hasta que la trabaje.

### Tabla de progresión (misma escala para las 10 habilidades — valores provisorios, se rebalancean con la economía real)

| Transición | EXP acumulada requerida | Costo en la Escuela |
|---|---|---|
| Nivel 1 → 2 | 100 | $1.500 |
| Nivel 2 → 3 | 300 | $4.000 |
| Nivel 3 → 4 | 700 | $9.000 |
| Nivel 4 → 5 | 1.500 | $18.000 |

La curva es intencionalmente exponencial: subir de nivel 5 debe sentirse como un logro real, no un trámite.

---

## 3. Relación con la app "Trabajos"

Cada encargo (`JobData`) define:

- `required_skill`: qué habilidad exige.
- `required_level`: nivel mínimo de esa habilidad para poder aceptarlo.
- `reward_money`: paga al completarlo.
- `reward_exp`: EXP que suma a esa habilidad específica (no a otra).

Si `player_level >= required_level` → el encargo aparece **disponible**. Si no, aparece **bloqueado** (mostrando qué habilidad y qué nivel le falta — esto empuja al jugador a decidir en qué especializarse).

Esto es exactamente lo que resuelve `JobsRepository` en código (ver más abajo): es la única puerta de entrada a la lista de encargos, así que cuando en el futuro haya encargos generados dinámicamente o por servidor, no hay que tocar el resto del juego.

---

## 4. Las 10 habilidades

### Habilidad 1 — Lavado y Detailing

| Nivel | Desbloquea |
|---|---|
| 1 | Lavado exterior básico (carrocería) y limpieza interior simple (asientos, pisos). |
| 2 | Abrillantador de llantas y limpieza de rines. |
| 3 | Encerado (wax) que protege la pintura y le da brillo prolongado. |
| 4 | Limpieza profunda de motor (degrasado del compartimento del motor sin dañar cableado). |
| 5 | Detailing profesional completo: pulido de pintura para quitar rayones superficiales, tratamiento de cuero, el vehículo queda "de exhibición". |

### Habilidad 2 — Mecánica General

| Nivel | Desbloquea |
|---|---|
| 1 | Medir y rellenar aceite, cambiar filtro de aire, cambiar refrigerante. |
| 2 | Cambiar bujías, cambiar filtro de combustible, purgar frenos básico. |
| 3 | Cambiar correa de distribución (sin sincronización fina), diagnosticar ruidos comunes del motor. |
| 4 | Reparar sistema de frenos completo (discos, pastillas, líquido), diagnóstico con scanner OBD. |
| 5 | Mecánico experto: puede resolver casi cualquier falla mecánica reportada, referencia para encargos de "auto no arranca". |

### Habilidad 3 — Desmantelador

| Nivel | Desbloquea |
|---|---|
| 1 | Retirar piezas simples y externas: espejos, manijas, parachoques. |
| 2 | Retirar piezas de interior: asientos, tablero, puertas completas. |
| 3 | Desarmar el motor de su compartimento (extracción completa sin desarmarlo internamente). |
| 4 | Desarme total de la carrocería (chasis desnudo) conservando piezas reutilizables sin dañarlas. |
| 5 | Desmantelador experto: puede desarmar y volver a armar un vehículo completo sin perder ni dañar ninguna pieza — clave para el negocio de repuestos usados. |

### Habilidad 4 — Torque y HP (Preparación de motor)

| Nivel | Desbloquea |
|---|---|
| 1 | Conectar la computadora de diagnóstico y leer el rendimiento actual (HP/torque de fábrica). |
| 2 | Instalar filtro de aire deportivo y escape libre (ganancias pequeñas, sin riesgo). |
| 3 | Reprogramar la ECU (chip tuning) para ajustes de rendimiento moderados. |
| 4 | Instalar turbo/kit de sobrealimentación e intercooler, con ajuste de mezcla aire-combustible. |
| 5 | Preparador experto: motores de competición, forjados internos, mapeos extremos — lleva el vehículo a su máximo HP posible. |

### Habilidad 5 — Pintura y Carrocería

| Nivel | Desbloquea |
|---|---|
| 1 | Quitar abolladuras pequeñas (masillado básico) en un panel. |
| 2 | Lijado y preparación de superficie completa antes de pintar. |
| 3 | Pintura de un panel individual con acabado uniforme (sin diseño). |
| 4 | Pintura completa del vehículo, mezcla de colores personalizados. |
| 5 | Pintor profesional: acabados premium (mate, cromado, degradados), diseños/liveries personalizados — nivel de exhibición/competición. |

### Habilidad 6 — Neumáticos y Suspensión Básica

| Nivel | Desbloquea |
|---|---|
| 1 | Cambiar neumáticos (montaje y desmontaje de rueda). |
| 2 | Balanceo de ruedas. |
| 3 | Alineación de dirección. |
| 4 | Cambiar amortiguadores y resortes estándar. |
| 5 | Suspensión experta: instalar suspensión coilover ajustable, calibrar altura y dureza para uso en pista. |

### Habilidad 7 — Electricidad Automotriz

| Nivel | Desbloquea |
|---|---|
| 1 | Cambiar bombillas/luces, fusibles y batería. |
| 2 | Instalar accesorios eléctricos simples (radio, luces LED, alarma). |
| 3 | Diagnosticar y reparar cortocircuitos o cableado dañado. |
| 4 | Reparar/programar módulos electrónicos (alza-cristales, central de puertas, sensores). |
| 5 | Electricista experto: reprogramación de ECU a nivel eléctrico, instalación de arneses completos personalizados, diagnóstico de fallas eléctricas complejas. |

### Habilidad 8 — Motor (Reconstrucción)

*(Distinta de "Torque y HP": esta es reparar y reconstruir el motor en sí, no potenciarlo).*

| Nivel | Desbloquea |
|---|---|
| 1 | Cambiar bandas y mangueras del motor, revisar juntas simples. |
| 2 | Cambiar junta de tapa de válvulas / retenes simples, sin abrir el bloque. |
| 3 | Rectificar y cambiar la junta de culata (cabeza del motor). |
| 4 | Reparar el bloque del motor: pistones, bielas, cigüeñal (motor parcialmente abierto). |
| 5 | Reconstructor experto: rearma un motor destruido desde cero (bloque desnudo hasta motor funcional) — imprescindible para restaurar vehículos "chatarra". |

### Habilidad 9 — Transmisión y Chasis

| Nivel | Desbloquea |
|---|---|
| 1 | Revisar y rellenar líquido de transmisión/caja. |
| 2 | Cambiar embrague (clutch) en cajas manuales. |
| 3 | Reparar/cambiar la caja de cambios completa (manual o automática estándar). |
| 4 | Instalar diferencial de deslizamiento limitado (LSD), ajustar relación de transmisión. |
| 5 | Experto en transmisión y chasis: cajas secuenciales, refuerzo estructural de chasis para alta potencia — nivel competición. |

### Habilidad 10 — Tasación y Negociación

*(Habilidad "económica", no de taller físico — encaja con el pilar de economía de `CLAUDE.md`.)*

| Nivel | Desbloquea |
|---|---|
| 1 | Ver el precio de mercado estimado de un vehículo antes de comprarlo/venderlo. |
| 2 | Detectar defectos ocultos (mecánicos o estéticos) que no se ven a simple vista antes de comprar. |
| 3 | Negociar precio de compra en el desguace/marketplace (descuento moderado). |
| 4 | Identificar vehículos "gema oculta" (piezas raras, ediciones limitadas) antes que otros compradores. |
| 5 | Tasador experto: negocia los mejores precios del juego y nunca paga de más por un vehículo con defectos ocultos — clave para el negocio de compra/venta a escala. |

---

## 5. Notas de escalabilidad (para cuando construyamos la Escuela)

- El costo en dinero y el umbral de EXP por nivel están **centralizados en una tabla única** (sección 2), no hardcodeados por habilidad — así cuando se rebalancee la economía se cambia en un solo lugar.
- La Escuela va a necesitar leer, por cada habilidad: nivel actual, EXP actual, EXP requerida del siguiente nivel, costo del siguiente nivel, y qué desbloquea en texto (las tablas de la sección 4 son ese texto). Eso ya está modelado como datos, no como lógica dispersa.
- Ninguna habilidad depende de otra para desbloquearse (son 10 árboles independientes) — a propósito, para no forzar un build "correcto" único.
- No se implementa todavía: el nodo `PlayerSkills`/EXP por habilidad en `GameState`, ni la escena de la Escuela. Eso llega en el próximo paso del roadmap (punto 4). Lo que sí se implementa ya (ver commit de este paso) es `skill_levels` en `GameState`, porque la app de Trabajos ya necesita saber qué nivel tiene el jugador para decidir qué encargos mostrar disponibles/bloqueados.

---

## 6. Tiendas del mapa (dónde se compra lo que pide cada habilidad)

No es una tienda por habilidad — se agrupan por rubro real de taller, igual que en la vida real un mismo local de repuestos vende aceite y bujías. Son **8 locales**, uno de ellos ya contemplado en el plano de ciudad (`Desguasadero`, roadmap paso 6) y otro que ya existe como concepto pero no vende insumos de habilidad (`Concesionario`, es para vender autos, no piezas).

| # | Tienda | Habilidad(es) que sirve | Qué vende (ejemplos) |
|---|---|---|---|
| 1 | Centro de Detailing | 1 — Lavado y Detailing | Shampoo, abrillantador de llantas, cera (wax), degrasante de motor, kit de pulido, tratamiento de cuero. |
| 2 | Refaccionaria (Autopartes Generales) | 2 — Mecánica General **y** 8 — Motor | Aceite, filtros de aire/aceite/combustible, refrigerante, bujías, correas y mangueras, juntas, líquido de frenos, pistones/bielas/retenes, scanner OBD. |
| 3 | Desguasadero | 3 — Desmantelador | Vehículos completos para desarmar, herramientas de desmontaje, piezas usadas sueltas (también es donde se compra el primer auto, roadmap paso 6). |
| 4 | Taller de Preparación (Performance Shop) | 4 — Torque y HP | Computadora de diagnóstico, filtro de aire deportivo, escape libre, chips de ECU, turbos/intercoolers, kits de sobrealimentación. |
| 5 | Casa de Pintura y Carrocería | 5 — Pintura y Carrocería | Masilla, lijas, pintura (colores base y mezcla), pistola de pintar, barniz, vinilos para diseños/liveries. |
| 6 | Gomería | 6 — Neumáticos y Suspensión Básica | Neumáticos (varias medidas), llantas, equilibradora, alineadora, amortiguadores y resortes, kits coilover. |
| 7 | Casa de Electricidad Automotriz | 7 — Electricidad Automotriz | Baterías, fusibles, bombillas y luces LED, radios/alarmas, arneses, módulos electrónicos (alza-cristales, sensores). |
| 8 | Taller de Transmisión y Chasis | 9 — Transmisión y Chasis | Líquido de caja, kits de embrague, cajas de cambio, diferenciales LSD, refuerzos de chasis. |

**Habilidad 10 (Tasación y Negociación) no tiene tienda propia** — es una habilidad "pasiva": se usa en el momento de comprar/vender en el Desguasadero, el Marketplace o el futuro Concesionario, no consume insumos.

**Nota de escala para el mapa:** no hace falta una manzana entera por tienda. En una ciudad chica, varias de estas (por ejemplo Gomería + Electricidad + Transmisión) pueden convivir como locales contiguos sobre una misma "Calle Taller" — igual que en el plano ya armado. Cuando llegue el momento de dibujarlas, la referencia es el plano de `docs` (o el artifact de la ciudad) y esta tabla — cada local necesita, como mínimo: un `Node2D` con su interior/exterior y, más adelante, un inventario (`Resource` plano, mismo patrón que `JobData`) filtrado por el nivel de habilidad del jugador.

---

## 7. Qué hace el jugador en cada desbloqueo (interacción/animación)

Definido el 2026-08-08. Objetivo: que ningún trabajo se sienta como "apretar un botón y listo", sin caer en minijuegos complejos ni animaciones costosas de dibujar. Para eso, cada uno de los 50 desbloqueos (10 habilidades × 5 niveles) se resuelve con una combinación de **5 patrones reusables**, pensados para armarse una sola vez como escenas/mecánicas genéricas y reutilizarse en todos los trabajos que correspondan (mismo espíritu que `WallBehindTrigger` o `DayNightVisibility`).

Estos minijuegos corren en un **overlay** (`CanvasLayer` con `Tween` de apertura/cierre, mismo patrón que `Phone.tscn`), no como animación del `Player` caminando por el mundo — así no depende de tener sprites de animación por cada herramienta.

### Los 5 patrones

| Patrón | Mecánica | Para qué sirve |
|---|---|---|
| **A — Mantener herramienta** | Sostener el cursor/ícono sobre la pieza durante una barra de progreso. | Limpiar, lijar, degrasar, pulir, encerar. |
| **B — Secuencia de puntos** | Tocar varios puntos calientes en un orden específico (ej. tuercas en patrón estrella). | Aflojar/ajustar tornillería, purgar frenos, conexiones múltiples. |
| **C — Arrastrar y soltar** | Arrastrar una pieza desde un inventario/pila hasta su lugar en el vehículo (o viceversa para retirarla). | Reemplazar piezas: filtros, batería, neumáticos, bujías, turbo, asientos. |
| **D — Precisión de tiempo** | Frenar una barra o aguja en la zona correcta (QTE simple). | Torque exacto, alineación, calibración de suspensión, mezcla aire-combustible, mapeo de ECU. |
| **E — Diagnóstico/negociación** | "Escanear" o "inspeccionar" y elegir la opción correcta entre varias. | Diagnósticos de fallas, detectar defectos ocultos, tasar, negociar precio. |

Los niveles altos (4-5) casi siempre **combinan 2-3 patrones en secuencia fija** — no porque sea un patrón nuevo, sino porque la tarea real tiene más pasos. Eso es intencional: se siente más "experto" sin escribir mecánica nueva.

### Habilidad 1 — Lavado y Detailing

| Nivel | Interacción |
|---|---|
| 1 | **A** — mantener esponja/trapo sobre carrocería y asientos hasta llenar la barra. |
| 2 | **A** — mantener cepillo sobre cada rin (uno por uno) hasta que brille. |
| 3 | **A** (más lenta/exigente) — aplicar cera en pasadas, con una segunda pasada de **A** para "sacar brillo". |
| 4 | **C + A** — retirar tapa del motor (drag), luego mantener degrasante sobre el compartimento evitando el área marcada del cableado (si tocás esa zona, se reinicia la barra). |
| 5 | **A + D** — pulido con máquina: mantener sobre el rayón (A) y frenar la pasada final en la zona de "brillo óptimo" (D) para no quemar la pintura. |

### Habilidad 2 — Mecánica General

| Nivel | Interacción |
|---|---|
| 1 | **C** — retirar tapón de aceite (drag), verter aceite nuevo (drag), cambiar filtro de aire (drag). |
| 2 | **C + B** — cambiar bujías (drag por cada una) + purgar frenos (secuencia B en 2 puntos). |
| 3 | **B + A** — aflojar tensor y retirar correa (B), diagnosticar ruido escuchando 3 clips de audio y eligiendo el correcto (E, ver nota abajo). |
| 4 | **B + D** — desarmar sistema de frenos (B en 4 puntos: pastillas/discos) + purgar con precisión de presión (D). |
| 5 | **E + combinación libre** — "escanear" con el OBD (E) y el resultado indica qué combinación de A/B/C/D del propio árbol de Mecánica General hay que aplicar (reutiliza lo ya construido, no agrega mecánica nueva). |

### Habilidad 3 — Desmantelador

| Nivel | Interacción |
|---|---|
| 1 | **C** — arrastrar espejos, manijas y parachoques hacia la pila de "piezas retiradas". |
| 2 | **C** (más piezas) — asientos, tablero, puertas completas, una por una. |
| 3 | **B + C** — aflojar soportes del motor (B) y luego arrastrarlo completo fuera del compartimento (C, con una barra de "cuidado" tipo D para no dañarlo). |
| 4 | **B + C** en más puntos — desarme total de carrocería: cada panel se afloja (B) y se retira (C) hasta dejar el chasis desnudo. |
| 5 | **Secuencia larga B/C invertible** — desarma TODO el auto (repite lo de niveles 1-4 en cadena) y además puede rearmarlo en el mismo orden inverso sin penalidad. |

### Habilidad 4 — Torque y HP

| Nivel | Interacción |
|---|---|
| 1 | **E** — conectar la computadora (C, un solo drag) y leer un resultado (pantalla de datos, sin decisión todavía). |
| 2 | **C** — instalar filtro deportivo y escape libre (drag de cada pieza a su lugar). |
| 3 | **D** — chip tuning: mover una curva/aguja de mapa de ECU y frenarla en la zona "segura" (si te pasás, pierde rendimiento en vez de ganar). |
| 4 | **C + D** — instalar turbo/intercooler (drag de piezas grandes) + calibrar mezcla aire-combustible (D, más exigente que nivel 3). |
| 5 | **D (extremo) + C** — mapeo extremo con ventana de acierto más angosta (D) + instalación de internos forjados (C, piezas más pequeñas y más pasos). |

### Habilidad 5 — Pintura y Carrocería

| Nivel | Interacción |
|---|---|
| 1 | **A** — masillar un panel (mantener espátula, rellenar la abolladura marcada). |
| 2 | **A** (toda la carrocería) — lijar panel por panel hasta que no queden imperfecciones marcadas. |
| 3 | **A + D** — aplicar pintura con pasadas parejas (A) y frenar la pistola en la distancia correcta (D) para que no queden goteos. |
| 4 | **A + E** — pintura completa (A en todos los paneles) + elegir/mezclar color en un selector (E: elegís proporciones hasta acertar el tono pedido). |
| 5 | **A + E + D** — acabado premium: mezcla de color (E), aplicación (A) y una pasada de barniz con timing (D) para el brillo final. Diseños/liveries se resuelven eligiendo una plantilla (E), no dibujando libre. |

### Habilidad 6 — Neumáticos y Suspensión Básica

| Nivel | Interacción |
|---|---|
| 1 | **B + C + B** — aflojar 4 tuercas en patrón estrella, cambiar el neumático (drag viejo → pila, drag nuevo → rueda), ajustar tuercas en patrón estrella. *(primer trabajo a implementar)* |
| 2 | **D** — balanceo: frenar una aguja vibrando en el centro (zona verde) para cada rueda. |
| 3 | **D** — alineación: centrar 2 barras (una por eje) en la zona correcta, más exigente que el balanceo. |
| 4 | **B + C** — retirar amortiguador viejo (B para pernos + C para sacarlo) e instalar el nuevo (C). |
| 5 | **C + D** — instalar coilover (C) y calibrar altura/dureza con dos sliders que hay que frenar en el rango pedido por el trabajo (D). |

### Habilidad 7 — Electricidad Automotriz

| Nivel | Interacción |
|---|---|
| 1 | **C** — cambiar bombilla, fusible y batería (drag de cada una a su lugar). |
| 2 | **C** — instalar radio/luces LED/alarma (drag del accesorio al hueco marcado en el tablero). |
| 3 | **E + B** — "escanear" el cableado para encontrar el corte (E, elegís el tramo dañado entre varios) y reconectarlo (B, 2-3 puntos en orden). |
| 4 | **C + E** — reemplazar el módulo dañado (C) y programarlo (E: elegís la configuración correcta entre opciones). |
| 5 | **B (largo) + E** — instalar arnés completo: conectar una secuencia larga de puntos (B, 8-10 conexiones) + diagnóstico final de fallas complejas (E). |

### Habilidad 8 — Motor (Reconstrucción)

| Nivel | Interacción |
|---|---|
| 1 | **C** — cambiar bandas y mangueras (drag), revisar juntas simples (A corta, "revisar" = mantener un ícono de lupa). |
| 2 | **B + C** — aflojar tapa de válvulas (B) y cambiar retenes (C). |
| 3 | **B + C + D** — aflojar culata (B en varios puntos, orden específico como en la realidad — de afuera hacia adentro), cambiar junta (C), ajustar torque de vuelta con precisión (D). |
| 4 | **B + C** (bloque abierto) — retirar pistones/bielas/cigüeñal en orden (B para pernos, C para extraer cada pieza), igual para instalar los nuevos. |
| 5 | **Secuencia larga combinada** — repite niveles 2-4 en cadena desde bloque desnudo hasta motor funcional (reusa toda la mecánica ya construida, sin patrón nuevo). |

### Habilidad 9 — Transmisión y Chasis

| Nivel | Interacción |
|---|---|
| 1 | **C** — rellenar líquido de caja (drag del bidón al conducto). |
| 2 | **B + C** — retirar caja vieja de embrague (B para pernos + C para sacarla) e instalar la nueva (C). |
| 3 | **B + C** (más piezas) — caja de cambios completa: mismo patrón que el embrague pero con más puntos de sujeción. |
| 4 | **C + D** — instalar diferencial LSD (C) y ajustar relación de transmisión con un slider de precisión (D). |
| 5 | **D (extremo) + C** — caja secuencial (C) + refuerzo estructural: reforzar puntos del chasis marcados uno por uno (B) con torque de precisión (D). |

### Habilidad 10 — Tasación y Negociación

*(Sin taller físico — se resuelve entera con el patrón E, en el momento de comprar/vender.)*

| Nivel | Interacción |
|---|---|
| 1 | **E** — al inspeccionar un vehículo, se revela el precio de mercado estimado (sin decisión, solo información). |
| 2 | **E** — inspección más profunda: elegís dónde "revisar" (motor/carrocería/interior) y se revelan defectos ocultos si elegís bien. |
| 3 | **E** — negociación: se ofrecen 2-3 líneas de diálogo con distinto tono (agresivo/neutral/amistoso), cada una con distinta chance de descuento. |
| 4 | **E** — entre varios vehículos listados, identificás cuál es la "gema oculta" antes de que se agote (ventana de tiempo, sin patrón nuevo). |
| 5 | **E (combinado)** — combina niveles 2+3+4 en una sola negociación compleja con más opciones y más riesgo si elegís mal. |

### Nota sobre el patrón E y "diagnóstico por audio/texto"

Algunos casos de **E** (ej. Mecánica General nivel 3, "diagnosticar ruidos") no necesitan arte nuevo: alcanza con 2-3 opciones de texto/ícono entre las que elegir, no hace falta grabar audio para la v1. Se puede iterar después si se quiere sumar sonido.

### Qué NO se dibuja todavía

Ningún nivel de esta sección necesita animación del `Player` en el mundo ni sprites de personaje haciendo la tarea — todo pasa en el overlay del minijuego, sobre sprites estáticos de la pieza/vehículo. Esto es deliberado: permite validar las 50 interacciones con arte mínimo (2-4 sprites por trabajo) antes de invertir en animaciones más costosas.
