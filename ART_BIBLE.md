# Piston City — Art Bible

Este documento define las reglas visuales del juego. Es un documento vivo:
se actualiza a medida que aparecen decisiones nuevas, pero nunca se rompe
retroactivamente sin decisión explícita.

Toda IA generadora de imágenes y todo dibujo a mano debe seguir estas reglas.
Ningún asset entra al proyecto si las contradice.

---

## 1. Cámara y perspectiva

- Top-down 2D, estilo Stardew Valley / Pokémon (no isométrico).
- Sin rotación de cámara. Sin perspectiva de 3/4 tipo Zelda: A Link to the Past.

## 2. Escalas

| Elemento | Tamaño (px) |
|---|---|
| Tile de suelo/pared | 32×32 |
| Personaje (player, NPC) | 32×48 |
| Vehículo | 64×96 |

Estas medidas son el punto de partida. Se ajustan solo cuando el primer
sprite real lo exija, y quedan documentadas acá con la fecha del cambio.

## 3. Paleta de color

Paleta oficial: `assets/palettes/palette.png` (referencia en texto:
`assets/palettes/palette.md`).

- Ningún sprite usa colores fuera de esta paleta.
- Las familias de color (grises, asfalto, azules, rojos, amarillos,
  naranjas, verdes, violetas, cyan, rosa neón, luces) ya están agrupadas
  por uso: estructura/asfalto en grises, marcas/neón en los colores
  saturados, luces en la familia "Luces".

## 4. Contornos

- Contorno oscuro de 1px en todos los sprites (no negro puro salvo que
  la paleta lo pida explícitamente).
- Sin contorno de color variable (no "selective outlining" por ahora).

## 5. Nivel de detalle

- Detalle medio: se reconoce la silueta a distancia de gameplay real
  (zoom de juego, no zoom de editor).
- Sin micro-detalle que solo se aprecie ampliado (eso es ruido, no estilo).

## 6. Reflejos de metal (carrocería de vehículos)

- Reflejo como banda de luz diagonal simple (2-3 tonos de la misma
  familia de color), no reflejo fotorrealista ni degradado suave.
- La banda de luz sigue la curva del panel, no es una línea recta fija.

## 7. Luces de neón

- Se representan con halo de 1-2 px del color de la familia "Luces" o
  "Rosa neón"/"Cyan" alrededor de la fuente emisora.
- No usar glow/blur real (post-proceso); el halo es pixel art, no shader,
  salvo que se decida lo contrario más adelante para un efecto puntual.

## 8. Sombras y oclusión

- Sombra de contacto simple (blob u óvalo plano) debajo de personajes y
  vehículos, no sombra proyectada con ángulo de luz dinámico.
- Sin oclusión ambiental dibujada a mano; si hace falta profundidad extra,
  se resuelve con capas/orden de dibujo, no con sombreado adicional.

## 9. Escala de edificios y objetos de entorno

- Edificios y objetos de entorno se escalan en múltiplos del tile (32px):
  un objeto de 2×2 tiles mide 64×64, uno de 1×2 mide 32×64, etc.
- Nada de tamaños arbitrarios que no calcen con la grilla del tileset.

## 10. Estilo de UI

- UI funcional antes que decorativa (ver CLAUDE.md, Sprint 1: HUD sin
  estética, solo información).
- Cuando se defina la estética real de UI, usa la misma paleta oficial;
  no introduce colores nuevos "solo para UI".
- Tipografía: pendiente de definir (carpeta `assets/fonts/`).

---

## Convenciones de organización

- `assets/sprites/player/` — sprites del personaje jugable.
- `assets/sprites/vehicles/` — vehículos, separados por marca/modelo y por
  pieza (body, windows, lights, wheels, spoiler, shadow).
- `assets/sprites/garage/` — piso, paredes, portón, columnas, parking spots.
- `assets/sprites/environment/` — todo lo que no es garage ni vehículo.
- `assets/sprites/ui/` y `assets/ui/` — assets de interfaz (duplicado
  intencional mientras se decide el uso final de cada carpeta).
- `assets/sprites/icons/` — iconografía (piezas, estados, acciones).
- `assets/tilesets/` — tilesets armados en Godot (`.tres`/`.tscn` de
  TileSet), no sprites sueltos.
- `assets/concepts/` — arte de referencia/moodboard, no assets finales de
  juego (no se importa en escenas).

## Historial de cambios

- 2026-08-03 — Documento inicial. Escalas y reglas definidas antes del
  primer sprite real; sujetas a ajuste cuando llegue.
