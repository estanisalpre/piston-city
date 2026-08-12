# Sistema de vehículos modulares

Documento de diseño — cómo se estructura un vehículo (arte + datos + código) para que cualquier pieza se pueda desmontar/reemplazar, sin tener que dibujar un sprite nuevo por cada combinación posible, y sin tener que tocar código cada vez que se agrega un auto nuevo.

Nace de la mecánica de "sacar/poner una rueda" (ver `VehicleRepairMenu.gd`), pero está pensado desde el principio para motor, espejos, vidrios, y lo que siga.

---

## 1. El problema que resuelve

Un vehículo tiene piezas de dos naturalezas muy distintas, y si no se separan desde el día 1, el sistema se vuelve un desastre de `if bmw then... if mercedes then...`:

- **Piezas específicas del modelo** — carrocería, espejos, vidrios, luces. La forma exacta depende de CADA auto. El espejo de un BMW no le sirve a un Mercedes, ni visual ni funcionalmente.
- **Piezas intercambiables/genéricas** — ruedas, y a futuro rines de tuning, caños de escape, etc. Diseñadas a propósito para poder montarse en cualquier auto.

Todo el sistema (carpetas, datos, arte, interacción) se organiza alrededor de esta distinción.

**La idea central:** separar **qué es** la pieza (su identidad económica — plata, stock, compra/venta) de **cómo se ve puesta en ESTE auto puntual** (su identidad visual, que cambia por modelo).

---

## 2. Estructura de carpetas

```
assets/sprites/vehicles/
  models/
    sedan_v1/
      body.png              (carrocería base, SIN las piezas desmontables pintadas)
      wheel_front_left.png  (la rueda YA MONTADA en este auto puntual)
      wheel_front_right.png
      mirror_left.png
      mirror_right.png
      glass.png
      lights_front.png
      lights_rear.png
    bmw_e30/                 (el día que exista — mismo esquema, cero código nuevo)
      body.png
      wheel_front_left.png
      mirror_left.png
      ...
  shared/
    wheels/
      sport_v1.png           (ícono AISLADO — inventario, compra, cargado en la cabeza)
      offroad_v1.png
    (a futuro: exhausts/, spoilers/, si llegan a ser piezas que se compran sueltas)
```

- `models/<model_id>/` — todo lo que sea forma única de ESE auto.
- `shared/<categoría>/` — el catálogo de piezas intercambiables, como ícono aislado (no como "puestas en un auto" — ver sección 5).

---

## 3. Cómo dibujar: un solo lienzo, capas separadas

**No se dibuja cada pieza aislada en su propio lienzo chico.** Se dibuja el auto completo en **un único lienzo** (del tamaño final del auto, ej. 96x64), con **una capa por pieza** (`body`, `wheel_front_left`, `mirror_left`, `glass`, ...).

Al exportar, cada capa sale como su propio PNG, **sin recortar** — mismo tamaño de lienzo que el original, con esa pieza dibujada en su lugar real y todo lo demás transparente.

```
body.png              → 96x64, el auto sin la rueda front-left, resto transparente donde falta
wheel_front_left.png  → 96x64, solo la rueda, en su posición real, resto transparente
mirror_left.png       → 96x64, solo el espejo, en su posición real, resto transparente
```

### Por qué esto resuelve el offset

Si todas las piezas de un mismo modelo salen del **mismo lienzo**, entonces en Godot **todas van a `position = (0, 0)`**, siempre — la posición ya está "horneada" en los píxeles transparentes de cada PNG. No hace falta calcular ni ajustar ningún offset a mano, y nunca se puede desalinear entre escenas.

`VehiclePartSlot.offset` (ver sección 4) casi siempre va a ser `(0, 0)` en la práctica — se deja disponible como escape para un ajuste fino puntual, no como el flujo normal de trabajo.

### Herramienta

Cualquier editor con capas (Aseprite, Piskel, GIMP, Krita). Ya hay archivos `.pxo` (Piskel) en el proyecto — mismo criterio: un archivo fuente por auto, con sus capas, del que se exporta cada pieza.

⚠️ Al exportar capa por capa, hay que desactivar cualquier opción de "recortar al contenido" (trim) — si el exportador recorta, se pierde la posición y hay que volver a alinear a mano.

---

## 4. Datos: `VehicleModel` y `VehiclePartSlot`

Dos `Resource` planos (DTO, sin lógica de Godot — mismo espíritu que se usará para el marketplace, ver `CLAUDE.md`).

### `VehiclePartSlot`

Un "lugar" desmontable (o no) del auto.

| Campo | Tipo | Qué es |
|---|---|---|
| `slot_id` | `String` | El LUGAR, no el dibujo — ej. `"wheel_front_left"`, `"mirror_left"`. Vocabulario compartido entre modelos. |
| `category` | `String` | De qué familia económica es — `"wheel"`, `"mirror"`, `"glass"`. Conecta con `PartCatalog` (ver sección 6). |
| `removable` | `bool` | Si esta pieza participa del flujo de sacar/poner (ver sección 7). La carrocería base y los vidrios, al menos al principio, no. |
| `default_texture` | `Texture2D` | El PNG de ESE modelo para esa pieza (salido del lienzo completo, ver sección 3). |
| `offset` | `Vector2` | Casi siempre `(0, 0)` si se siguió el flujo de la sección 3. |

### `VehicleModel`

| Campo | Tipo | Qué es |
|---|---|---|
| `model_id` | `String` | `"sedan_v1"`, `"bmw_e30"` — el nombre de la carpeta en `models/`. |
| `display_name` | `String` | `"Sedán clásico"` — para mostrar en UI. |
| `body_texture` | `Texture2D` | La carrocería base. |
| `part_slots` | `Array[VehiclePartSlot]` | Todas las piezas desmontables (y no desmontables) de este modelo. |

### Ejemplo — dos autos reales

```
VehicleModel
  model_id = "sedan_v1"
  body_texture = models/sedan_v1/body.png

  part_slots:
    - slot_id: "wheel_front_left"
      category: "wheel"
      removable: true
      default_texture: models/sedan_v1/wheel_front_left.png
      offset: (0, 0)

    - slot_id: "mirror_left"
      category: "mirror"
      removable: true
      default_texture: models/sedan_v1/mirror_left.png
      offset: (0, 0)
```

```
VehicleModel
  model_id = "bmw_e30"                              ← agregado después, sin tocar código
  body_texture = models/bmw_e30/body.png

  part_slots:
    - slot_id: "wheel_front_left"                    ← mismo LUGAR
      category: "wheel"                              ← misma familia económica
      removable: true
      default_texture: models/bmw_e30/wheel_front_left.png   ← dibujo DISTINTO
      offset: (0, 0)

    - slot_id: "mirror_left"
      category: "mirror"
      removable: true
      default_texture: models/bmw_e30/mirror_left.png        ← espejo de BMW, no del sedán
      offset: (0, 0)
```

`slot_id` se repite a propósito (es el nombre del LUGAR); `default_texture` nunca se repite entre modelos distintos (es el dibujo, único por auto).

---

## 5. Piezas compartidas (ruedas) — dos archivos, no uno

Una rueda "de a pie" — el ícono en la estantería, arriba de tu cabeza mientras la cargás, tirada en el piso, en la lista de compra del celular — es un **sprite chico y aislado**, sin relación con el lienzo de ningún auto. Vive en `shared/wheels/` (ej. `tire_v3.png`, ya existe).

La rueda **puesta en un auto** es una exportación distinta, recortada del lienzo completo de ESE modelo (`models/sedan_v1/wheel_front_left.png`). Puede ser visualmente "el mismo diseño de rueda", pero el archivo es otro, porque el hueco de la rueda no está en el mismo lugar (ni tiene el mismo ángulo/perspectiva) en cada auto.

Por cada diseño de rueda que exista en el juego:
- **1 ícono aislado** (inventario/compra/cargar) — ya está resuelto hoy con `tire_v3.png`.
- **1 versión "puesta"** por cada modelo de auto que la pueda usar.

No es tan pesado como suena: una vez armado el lienzo completo de un auto, "poner" ahí una rueda ya diseñada es más una tarea de copiar/ajustar que de dibujar desde cero.

---

## 6. `PartCatalog` — el puente entre economía y visual

Un catálogo chico (no un `Resource` por instancia, más bien una tabla estática) que dice de qué `category` es cada `part_id` económico:

```
PartCatalog:
  "neumatico"       -> category "wheel"
  "neumatico_usado" -> category "wheel"
```

Sirve para una sola pregunta, en todos lados por igual: *"¿la pieza que cargo en la cabeza puede ir en este hueco?"*

```
¿PartCatalog.category_of(pieza_cargada) == slot.category?  → sí, entra. No → no entra.
```

El día que una pieza nueva sea comprable (ej. `"espejo_generico"`), se agrega una línea a `PartCatalog` — nada del sistema de slots/interacción cambia.

---

## 7. Cómo se arma y se interactúa en tiempo real

En vez de dibujar a mano un `Area2D` por pieza en cada escena de auto (lo que no escala a 15 piezas × N modelos), el auto se **arma en código, en tiempo de ejecución**, a partir de su `VehicleModel`:

1. `Vehicle.gd` (generalización de lo que hoy es `JobVehicle.gd`) recibe un `model_id`.
2. Carga el `VehicleModel` correspondiente (a través de una clase intermediaria, nunca cargando el Resource directo desde cualquier lado — mismo criterio que se va a usar para el marketplace).
3. Pone el `body_texture` como capa base.
4. Por cada `part_slot`, instancia **un `Sprite2D` + un `Area2D` genérico** (un solo script reusable, `VehiclePartInteraction.gd`, no uno por pieza), con el `CollisionShape2D` calculado automáticamente del tamaño de esa textura.
5. Ese script genérico, al recibir el click, ya sabe su propio `slot_id` y `removable` — si es desmontable, dispara el mismo flujo que ya existe hoy (radial → minijuego si corresponde → `PlayerCarry`), pero escrito **una sola vez**, para cualquier pieza de cualquier auto.

---

## 8. Qué de lo ya construido se queda igual, y qué se generaliza

**Se queda exactamente igual** (no le importa si la pieza es una rueda o un espejo):
- `PartsInventory` (stock, `deposit_in_zone`, `take_from_zone`).
- `PlayerCarry` (cargar/soltar/consumir).
- `PartStorageZone` (la estantería del garage).
- `ButtonSequenceMinigame` (la secuencia de teclas).
- `RadialMenu` / `OptionsModal` / `PurchaseModal`.

**Se generaliza** (de "una rueda hardcodeada" a "cualquier pieza de cualquier modelo"):
- `JobVehicle.gd` → pasa a construirse desde un `VehicleModel` en vez de tener un `Sprite2D` + `Wheel` fijos en la escena.
- El nodo `Wheel` que existe hoy se convierte en el primer `VehiclePartSlot` real, del primer `VehicleModel` (`sedan_v1`, o el nombre que se le quiera dar al auto actual).
- `VehicleRepairMenu.gd` → su lógica de "quitar/poner rueda" pasa a vivir en el script genérico de interacción por pieza, en vez de un script pensado solo para ruedas.

---

## 9. Próximos pasos

1. Rehacer el arte del auto actual siguiendo el flujo de capas (sección 3) — un lienzo, `body` + `wheel_front_left` como capas separadas.
2. Armar `VehiclePartSlot.gd` y `VehicleModel.gd` como `Resource` en Godot.
3. Armar `PartCatalog` (mínimo, con `"neumatico"`/`"neumatico_usado"` → `"wheel"`).
4. Armar el script genérico `VehiclePartInteraction.gd` (reemplaza la parte de detección de click de `VehicleRepairMenu.gd`).
5. Migrar el auto actual (`JobVehicle.tscn`) a este sistema — validar que sacar/poner la rueda siga funcionando igual que hoy, ya generalizado.
6. Recién ahí, un segundo modelo de auto es puro dato — cero código nuevo.
