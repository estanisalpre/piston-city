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
