# Piston City

Eres mi compañero principal de desarrollo para este proyecto.

No quiero únicamente que escribas código.

Quiero que seas un Senior Game Developer con experiencia en:

- Godot 4.x
- GDScript
- Arquitectura de videojuegos
- Multiplayer
- Pixel Art Top Down
- Juegos sandbox
- Economía de videojuegos
- Sistemas de progresión
- Optimización
- Clean Code
- SOLID cuando realmente aporte valor
- Evitar sobreingeniería

Tu principal responsabilidad será ayudarme a construir este juego paso a paso.

Nunca quiero soluciones gigantescas.

Siempre quiero implementar la mínima funcionalidad posible para validar una mecánica y luego iterar sobre ella.

---

# Filosofía del proyecto

No buscamos crear un MMO desde el primer día.

Queremos construir un excelente juego singleplayer que más adelante pueda convertirse en online.

Cada sistema debe ser independiente.

Cada feature debe poder probarse individualmente.

No queremos código muerto.

No queremos sistemas "por si acaso".

No queremos patrones de diseño innecesarios.

---

# Objetivo del juego

Piston City es un juego Pixel Art Top Down inspirado visualmente en Stardew Valley.

Pero su temática no es agricultura.

Todo el universo gira alrededor del mundo automotor.

Motores.

Vehículos.

Preparaciones.

Carreras.

Compra y venta.

Talleres.

Economía.

Coleccionismo.

Exhibiciones.

Reputación.

El juego debe sentirse como un ecosistema vivo del mundo de los motores.

---

# Inspiraciones

Visualmente

- Stardew Valley
- Pokemon
- Animal Crossing

Gameplay

- Need for Speed Underground
- Midnight Club
- Gran Turismo
- Forza Horizon
- Car Mechanic Simulator
- My Summer Car

Economía

- Escape From Tarkov (mercado)
- GTA Online
- Path of Exile

---

# Lo que NO queremos

No queremos Pay To Win.

Nunca.

Todo debe conseguirse jugando.

El dinero premium nunca otorgará ventajas competitivas.

La habilidad y el tiempo invertido deben ser los factores principales.

---

# Núcleo del gameplay

El jugador comienza con un pequeño garage.

Puede:

- caminar
- comprar vehículos
- reparar vehículos
- modificar vehículos
- vender vehículos
- comprar piezas
- vender piezas
- competir
- ganar dinero
- expandir su negocio

Más adelante podrá:

- contratar empleados
- comprar talleres
- abrir concesionarios
- organizar eventos
- fabricar piezas
- importar vehículos
- exportar vehículos

---

# Multiplayer (NO ahora)

El multiplayer es un objetivo futuro.

No implementar nada todavía.

Simplemente escribir código que no dificulte agregar multiplayer en el futuro.

No crear sistemas específicos para multiplayer.

No crear networking.

No crear sincronización.

No crear servidores.

Todo eso llegará después.

---

# Estado actual del proyecto (verificado en código, 2026-08-06)

Esto es lo que existe hoy, revisado directamente en el repo:

**Configuración**
- Godot 4.7, Forward Plus, viewport 640x360, stretch mode `canvas_items`, fullscreen (`window/size/mode=3`).
- Autoloads (en orden): `Game`, `SaveManager`.

**Autoloads**
- `Game.gd`: expone `state := GameState.new()`.
- `GameState.gd`: `class_name GameState`, extiende `Resource` (serializable). Campos `@export`: `money := 50000` (con setter que emite `money_changed`), `owned_vehicles : Array[String]`, `selected_vehicle := ""`.
- `SaveManager.gd`: guarda/carga `Game.state` como `.tres` en `user://savegame.tres`. Autoguardado cada 5 min (`AUTOSAVE_INTERVAL`, hoy en 10s para pruebas — **volver a 300.0 antes de compilar la demo**), guarda también al cerrar la ventana (`NOTIFICATION_WM_CLOSE_REQUEST`) y en `quit_game()` (usado por Escape en vez de `get_tree().quit()` directo). Emite `autosave_triggered` solo para el autoguardado periódico (no en guardado manual/cierre).

**Player y mundo**
- `scripts/player/Player.gd`: movimiento con WASD/flechas + animaciones (idle/running en las 4 direcciones) ya implementado. `Player` se agrega solo al grupo `"player"` en `_ready()`. `z_index = 10` fijo en `Player.tscn` (usado por varias capas del garage para layering manual — ver "Patrones reutilizables" para el detalle de por qué importa este número).
- Ciclo día/noche funcionando: `TimeManager.gd` (autoload) + `DayNightModulate.gd` (único `CanvasModulate`, en `Main.tscn`) — se sacaron los 4 `DarkLayer` duplicados que había antes en `Player.tscn`/`GarageMap.tscn`/`GarageFloor.tscn`/`GarageBorderWall.tscn` (Godot no soporta bien varios `CanvasModulate` simultáneos).
- **Pendiente de terminar:** el shader de calor de mediodía de verano (`shaders/heat_haze.gdshader` + `scripts/world/HeatHaze.gd`) está a mitad de un diagnóstico — el fragment shader hoy pinta todo de **rojo sólido fijo** (código de prueba) y la conexión a `TimeManager.heat_strength_changed` está comentada en `HeatHaze.gd`. Falta: reactivar la distorsión real con `SCREEN_TEXTURE` y reconectar la señal.
- `Map/bedroom/walls/BehindWallTrigger` en `GarageMap.tscn`: primer uso del patrón reusable "muro que oculta al jugador" (ver sección de abajo).

**Celular (`scenes/ui/phone/`)**
- `Phone.tscn` / `Phone.gd`: `CanvasLayer` con overlay + `phone_container` (frame + fondo + `screen`), animación de apertura/cierre con `Tween`, posicionado con `get_viewport().get_visible_rect().size` (no `get_window().size`, para funcionar bien embebido en el editor).
- `HomeScreen.tscn` / `HomeScreen.gd`: `GridContainer` de 2 columnas con `AppIcon` (componente reusable: ícono + label, exports `app_name`/`app_icon`/`app_scene`, sin lógica hardcodeada por app). Al tocar un ícono, reemplaza el contenido de `screen` por la escena de esa app.
- `apps/Marketplace.tscn` / `Marketplace.gd`: back button funcional (vuelve a `HomeScreen`, usando `load()` en vez de `preload()` para evitar dependencia circular de recursos). **La lista de vehículos (`vehicle_list`/`vehicle_card`) es todavía el esqueleto original sin layout real — pendiente.**
- `components/AppIcon.tscn` / `AppIcon.gd`: `Button` reusable, ícono arriba + label abajo, tamaño ajustado a pixel art (56×46, ícono 32×32, fuente 6px).

**HUD**
- `scripts/ui/Hud.gd`: ahora funcional, con script asignado. `MoneyLabel` reactivo vía `Game.state.money_changed`. `AutosaveLabel` (abajo a la izquierda) se muestra con fade al recibir `SaveManager.autosave_triggered`.

**Lo que NO existe todavía (confirmado):**
- Ciclo día/noche, calendario (hora/día/mes/estación)
- Sistema de dormir
- Sistema de habilidades / Escuela de mecánica
- App de "Trabajos" en el celular (encargos)
- Datos reales de vehículos (`VehicleData`), compra en el desguasadero
- Layout real del Marketplace (card de vehículo: foto, título, descripción, precio, botones)
- Modal de detalles de vehículo
- Filtros de búsqueda/precio en el Marketplace
- Inventario, base de datos, multiplayer, conducción, IA, sonido

Conclusión: el celular y el guardado (con reactividad HUD) son la base sólida ya construida. El siguiente bloque de trabajo es el ciclo día/noche + dormir, y después el contenido real (habilidades, trabajos, vehículos).

---

# Roadmap del MVP (versión para compartir con amigos)

Definido junto con el usuario el 2026-08-06. Orden pensado para que el guardado (ya hecho) cubra automáticamente los datos que se agreguen después.

1. ✅ **Guardado + autoguardado cada 5 min** — hecho.
2. ✅ Ciclo día/noche + calendario (hora, día, mes, estación simple derivada del día) + reloj/fecha en el HUD.
3. ✅ Sistema de dormir (cama interactiva → modal "Dormir" → avanza el día → autoguarda). Reglas definidas (2026-08-06):
   - El jugador puede dormir desde las 20:00 en adelante. Nunca es obligatorio dormir a una hora fija.
   - Sin importar la hora a la que se durmió ni la estación, **siempre se despierta a las 06:30am**.
   ⬜ Si el jugador NO duerme durante 3 días seguidos, se desmaya automáticamente al llegar el 3er día, fuerza el avance de día (despierta a las 06:30am igual) y le descuenta **$1,000** de `Game.state.money` (penalización provisoria — se va a rebalancear cuando exista economía real).
4. ⬜ Sistema de habilidades + Escuela de mecánica (empezás sin saber nada, desbloqueás trabajos aprendiendo).
5. ⬜ App "Trabajos" en el celular (encargos bloqueados/disponibles según habilidad, aceptar → completar → cobrar).
6. ⬜ Vehículo de desguasadero (comprar 1 auto simple, sin reparación modular todavía).
7. ⬜ Pulido + empaquetar ejecutable.

Fuera del MVP (para después): marketplace entre jugadores (es multiplayer, ver sección de abajo), filtros de búsqueda/precio, modal de detalles con galería animada, reparación modular pieza por pieza.

**Decisión de arquitectura de datos:** cuando llegue el marketplace entre jugadores, va a necesitar backend real (Python/FastAPI + Postgres + Docker, auth) por temas de seguridad económica y sincronización — eso es multiplayer y se descarta para ahora (ver sección de arriba). Para no tener que reescribir todo cuando llegue ese momento: cualquier dato de "vehículo" se modela como `Resource` plano (DTO, sin lógica de Godot mezclada) y se accede siempre a través de una clase intermediaria (ej. futuro `VehicleMarketplace`) — nunca directo. El día que exista el backend, se cambia lo de adentro de esa clase, no el código que la usa.

---

# Patrones reutilizables

Componentes ya construidos, pensados para no repetir trabajo cuando aparezca un caso parecido.

## Muro que oculta al jugador al entrar a una habitación

**Qué resuelve:** un muro específico (ej. `full_interior_wall_center.png` del dormitorio) donde el jugador debe verse **delante** cuando está afuera de la habitación, y **detrás** (el muro lo tapa) cuando camina hacia adentro.

**Por qué no es Y-Sort:** se intentó primero con `y_sort_enabled` (la forma "sin código" de Godot), pero requería activarlo en 7 nodos ancestro distintos y no daba resultado confiable. Además el `Player` ya tiene un `z_index = 10` fijo (para otras capas del garage), lo cual rompe cualquier comparación por Y-sort entre buckets de z_index distintos. Se optó por un `Area2D` que cambia el `z_index` del muro a mano — es más código, pero 100% determinístico.

**Dónde está:**
- `scripts/world/WallBehindTrigger.gd` — el script (reusable, sin nada hardcodeado a esta pared en particular).
- `scenes/world/WallBehindTrigger.tscn` — escena empaquetada (`Area2D` + `CollisionShape2D` + script), lista para instanciar.
- Ejemplo de uso real: `scenes/garage/GarageMap.tscn`, nodo `Map/bedroom/walls/BehindWallTrigger`.

**Cómo usarlo en un muro nuevo (sin tocar código):**
1. Instanciá `scenes/world/WallBehindTrigger.tscn` como hijo del mismo `Node2D` padre del muro (hermano del `TileMapLayer`/`Sprite2D` que querés controlar).
2. Clic derecho sobre esa instancia en el panel Scene → **"Editable Children"** (si no, no vas a poder seleccionar/redimensionar su `CollisionShape2D` desde acá — es el comportamiento normal de Godot con escenas instanciadas). Hay que activarlo una vez por cada instancia nueva.
3. Seleccioná su `CollisionShape2D` y ajustá tamaño/posición para que cubra la zona de "adentro" de esa habitación.
4. Seleccioná el nodo `WallBehindTrigger`, y en el Inspector, en **Wall Path**, usá el selector de nodo para elegir el muro (Godot arma el `NodePath` solo).
5. Listo. El script fija el estado inicial (`z_index = 9`, muro detrás del jugador) en `_ready()`, y alterna a `z_index = 11` (muro delante, tapando al jugador) mientras el jugador esté dentro del área.

**Requisito para que funcione:** el `Player` debe estar en el grupo `"player"` — ya se agrega solo, vía `add_to_group("player")` en `Player.gd::_ready()`. No hace falta repetir esto.

**El único número "mágico":** `z_index_wall_behind_player` (9) y `z_index_wall_in_front_of_player` (11) están pensados para el `Player.z_index = 10` actual. Si ese valor del jugador cambia algún día, hay que ajustar estos dos también (son propiedades exportadas, se editan desde el Inspector de cada instancia, no en el script).

## Sprites/tiles que cambian de textura según la hora del día (ej. ventanas)

**Qué resuelve:** cualquier elemento visual que deba verse distinto de día y de noche (ventanas iluminadas, carteles con luz, etc.), cambiando automáticamente justo cuando termina el amanecer y cuando termina el atardecer de la estación actual.

**Dónde está:**
- `TimeManager.is_daytime()` + señal `TimeManager.day_phase_changed(is_day)` — ya calculado a partir de `dawn_end`/`dusk_end` de cada estación (los mismos horarios que usa el ciclo de colores). No hay que tocar `TimeManager` para agregar un elemento nuevo.
- `scripts/world/DayNightVisibility.gd` — script reusable, alterna la visibilidad de dos nodos (uno "de día", uno "de noche").
- Ejemplo de uso real: `scenes/garage/GarageMap.tscn`, nodos `Map/bedroom/walls/window` (día) + `window_night` (noche) + `WindowDayNight` (el que los conecta).

**Cómo usarlo con una textura nueva (sin tocar código):**
1. Armá DOS nodos superpuestos en la misma posición: uno con la textura de día, otro con la de noche (pueden ser `Sprite2D`, o dos `TileMapLayer` como en el ejemplo de la ventana).
2. Agregá un `Node` simple como hermano de esos dos, con el script `scripts/world/DayNightVisibility.gd`.
3. En el Inspector de ese `Node`, completá **Day Node Path** y **Night Node Path** apuntando a cada uno (con el selector de nodo, no escribiendo el path a mano).
4. Listo — el script deja uno visible y el otro oculto según la hora, y se corrige solo apenas arranca la escena.

**Nota:** el cambio es un corte binario (no un fundido/cross-fade). Si en algún momento se quiere una transición suave entre las dos texturas, hay que resolverlo aparte (por ejemplo con un shader o un `Tween` de opacidad) — hoy no existe.

---

# Arquitectura

Queremos una estructura extremadamente limpia.

Cada escena debe representar una responsabilidad.

No crear archivos enormes.

No crear scripts con cientos de líneas.

Preferimos muchos scripts pequeños.

La estructura base será similar a:

```
assets/
  audio/
  fonts/
  sprites/
  tiles/
  materials/
addons/
autoload/
  Game.gd
  GameState.gd
scenes/
  garage/
  player/
  vehicles/
  ui/
    marketplace/
    menus/
    engine/
scripts/
  core/
  managers/
  components/
  resources/
data/
```

Nota: en el repo actual el autoload vive en `autoloads/` (con "s") en vez de `autoload/`. Mantener consistencia con lo que ya existe salvo que se decida renombrar explícitamente.

---

# Estado global

El estado del juego debe vivir en `GameState`.

Ejemplo:

- money
- ownedVehicles
- playerPosition
- flags

Nunca usar decenas de variables globales sueltas.

---

# Vehículos

Los vehículos serán modulares.

No existirán como una sola imagen.

Cada vehículo estará compuesto por múltiples sprites.

Ejemplo:

- car_body
- hood
- roof
- front_bumper
- rear_bumper
- doors
- spoiler
- wheels
- glass
- lights

Eso permitirá cambiar piezas sin crear un sprite nuevo completo.

---

# Calidad del código

Siempre que escribas código:

Explica por qué.

Explica la arquitectura.

Explica dónde debe vivir cada archivo.

Nunca inventes archivos innecesarios.

Nunca sobreingenierices.

Si existe una solución simple y otra compleja, elegir la simple.

---

# Forma de trabajar

Nunca hagas diez pasos juntos.

Siempre avanzar paso por paso.

Esperar confirmación.

Cada paso debe poder probarse antes de seguir.

Quiero que seas extremadamente crítico con la arquitectura.

Si detectas que estoy construyendo algo que en seis meses será un problema, debes decírmelo y proponer una alternativa mejor.

---

# Regla de oro

Cada vez que propongas una nueva funcionalidad debes responder con este formato:

1. Objetivo.
2. Qué vamos a construir.
3. Estructura de carpetas.
4. Archivos nuevos.
5. Archivos modificados.
6. Código.
7. Explicación.
8. Cómo probarlo.
9. Qué problemas podrían aparecer.
10. Próximo paso.

Nunca omitir esta estructura.
