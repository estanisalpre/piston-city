# Plan de mañana — Cerrar el ciclo de Cambio de Neumáticos

> Objetivo del día: que el trabajo de Neumáticos deje de ser un botón instantáneo y se resuelva con el minijuego real (B + C + B, ver `docs/habilidades-y-escuela.md` sección 7). Al final del día: aceptás el trabajo en el celular → se abre el minijuego → aflojás 4 tuercas → cambiás el neumático → ajustás 4 tuercas → cobrás plata + EXP.

Hoy no se toca nada de arte/código de otras habilidades. Es intencional — un solo trabajo, de punta a punta, antes de repetir el patrón en los otros 49 desbloqueos.

---

## 1. Arte a dibujar (bloque de la mañana)

Guardar todo en `assets/sprites/minigames/tire_change/`. Estilo: mismo pixel art que el resto del juego (referencia: sprites del garage/HUD ya existentes).

- [ ] `car_frame.png` — auto en vista 3/4 o lateral, con las 4 ruedas bien visibles y separadas (para poder clickear cada una sin ambigüedad). Placeholder de silueta simple está bien para hoy.
- [ ] `tire_old.png` — neumático gastado (más claro/liso).
- [ ] `tire_new.png` — neumático nuevo (más oscuro, con relieve).
- [ ] `nut_tight.png` — tuerca apretada.
- [ ] `nut_loose.png` — tuerca floja (puede ser la misma rotada, o un poco más chica/gris).
- [ ] `wrench_cursor.png` — ícono de llave de cruz, es el "cursor" con el que se clickean las tuercas.
- [ ] `background.png` — fondo simple del box/elevador del garage (no hace falta detalle, es un overlay, no una escena del mundo).

**Nota:** no hace falta animación de sprites (frames) para hoy. Todo el "movimiento" lo da el código (rotar/ocultar/mover el sprite estático), no una animación dibujada.

---

## 2. Arquitectura de código (bloque de la tarde)

Mismo patrón que ya usamos en Trabajos: escenas chicas, un DTO plano, una clase intermediaria. Nada nuevo conceptualmente.

### Archivos nuevos

- `scenes/ui/minigames/TireChange.tscn` — la escena del minijuego (overlay `CanvasLayer`, mismo espíritu que `Phone.tscn`).
- `scripts/ui/minigames/TireChange.gd` — controla los 3 pasos (aflojar → cambiar → ajustar) y emite `signal completed` cuando termina.

### Archivos modificados

- `scripts/resources/JobData.gd` — agregar `@export var minigame_scene: PackedScene` (opcional; si un job no tiene minijuego, sigue funcionando como hasta ahora, instantáneo).
- `scripts/managers/JobsRepository.gd` — agregar el `JobData` real de "Cambio de Neumáticos" (hoy no existe, `oil_check` y `full_paint` son los únicos): `required_skill = SkillIds.NEUMATICOS`, `required_level = 1`, y `minigame_scene` apuntando a `TireChange.tscn`.
- `scripts/ui/phone/Jobs.gd` — en `_on_accept_pressed`: si el job tiene `minigame_scene`, instanciarlo y esperar su señal `completed` antes de dar la recompensa (en vez de darla al toque como ahora). Si no tiene minijuego (los otros 2 jobs), se comporta exactamente igual que hoy.

**Por qué así:** `Jobs.gd` no necesita saber que existe un "minijuego de neumáticos" específico — solo sabe "si el job trae una escena de minijuego, la muestro y espero que me avise que terminó". El día que agreguemos el minijuego de Pintura o el de Mecánica General, no se toca `Jobs.gd` de nuevo.

---

## 3. Los 3 pasos del minijuego (lo que resuelve `TireChange.gd`)

1. **Aflojar (patrón B):** 4 `TextureButton` (uno por tuerca) puestos sobre `car_frame.png`, arrancan con `nut_tight.png`. Click en orden → cambian a `nut_loose.png`. El orden importa (patrón estrella: ej. arriba, abajo-derecha, izquierda, abajo-izquierda) — si clickean fuera de orden, no pasa nada (no penalizar todavía, solo ignorar el click).
2. **Cambiar (patrón C):** una vez las 4 tuercas están flojas, aparece `tire_old.png` sobre la rueda y `tire_new.png` al costado. Drag del viejo hacia afuera (o simplemente un click que lo reemplaza, si el drag real complica mucho el día) y del nuevo hacia la rueda.
3. **Ajustar (patrón B otra vez):** mismas 4 tuercas, mismo patrón estrella, pero ahora pasan de `nut_loose.png` a `nut_tight.png`. Al completar la cuarta, emitir `completed`.

**Simplificación válida para hoy si el tiempo aprieta:** si el drag-and-drop real (mover el mouse arrastrando el sprite) lleva mucho tiempo, reemplazarlo por un solo click sobre el neumático viejo que dispara el cambio automáticamente (visualmente se ve el swap, pero sin arrastre real). Es aceptable para validar el ciclo completo hoy — el drag "de verdad" se puede pulir después sin romper nada de lo demás.

---

## 4. Orden de trabajo sugerido para el día completo

1. Dibujar los 7 sprites de la sección 1.
2. Armar `TireChange.tscn` con los sprites ya puestos en pantalla (sin lógica todavía) — validar que se ve bien.
3. Escribir `TireChange.gd`: paso 1 (aflojar) funcionando y probado solo.
4. Agregar paso 2 (cambio de neumático) y paso 3 (ajustar), probando cada uno antes de seguir al siguiente.
5. Emitir `completed` al terminar paso 3.
6. Conectar todo: `JobData.minigame_scene`, el job nuevo en `JobsRepository`, y el cambio en `Jobs.gd` para abrir el minijuego en vez de dar la recompensa directo.
7. Prueba de punta a punta: celular → Trabajos → Cambio de Neumáticos → minijuego completo → vuelve al celular con la plata y el EXP sumados.

---

## 5. Cómo probar al final del día

- F5 en Godot, abrir el celular, entrar a Trabajos.
- El job de Neumáticos debe aparecer disponible (Neumáticos empieza en nivel 1).
- Al tocar "Aceptar", se abre el minijuego (no debería dar la plata todavía).
- Completar los 3 pasos en orden.
- Al terminar, confirmar que la plata subió (igual que ya probamos con el job de aceite) y que `Game.state.skill_exp[SkillIds.NEUMATICOS]` subió (se puede chequear con el debugger de Godot, todavía no hay UI de EXP).

---

## 6. Qué queda afuera a propósito (no hacer hoy)

- Los otros 49 desbloqueos de habilidades — se repite este mismo patrón más adelante, uno a la vez.
- Penalizar clicks fuera de orden en el patrón B (hoy simplemente se ignoran).
- Animación dibujada (frames) de la llave o el auto — todo el movimiento es por código sobre sprites estáticos.
- UI de barra de EXP — sigue viviendo solo en `GameState`, sin pantalla propia todavía.
- Cooldown o lista de trabajos completados — el job sigue siendo repetible como hoy.
