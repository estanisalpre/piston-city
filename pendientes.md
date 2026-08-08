1. Crear variaciones de "manchas" en vereda (sidewalk)
2. Animación izquierda del personaje tiene que agacharse - como hace a la derecha
3. Bajar intensidad de transiciones de atardeceres-amaneceres filtros
4. Arreglar el filtro de calor cuando es verano de 12:00pm a 17:00pm
5. cuando corre en diagonal que priorice la animacion de "costado" para el lado que esta apretando la diagonal


# ==== > NPCS < ====
1. Los Npcs al entrar al garage, que sigan su curso dentro del garage hacia la puerta de su auto a buscarme. Ahora lo que sucede es que estoy entrando al garage y ellos empiezan a camibar al auto desde el respawn dentro del garage, caundo yo ingreso, si yo no ingreso no se mueven. Deben moverse y esperar allí.
2. Los npcs, en sus recorridos que vayan hasta el punto antes del garage, para que no todos caminen al garage siempre, sino que hagan el loop desde el b_point al point final de la ruta. Claro, si los llamo a reclamar o para que traigan el auto, entonces ahi si toman en cuenta el punto al garage y lo continuan.
3. Puntos de estadia entre medio. Es deicr, un npc puede tener la ruta que va a ir a un café, entonces lo dejo pararse en el café por x tiempo (tiempo del juego). Como configuramos los puntos para que se tome en cuenta eso y hacerlo yo manualmente desde godot, al armar las rutas.
4. Si cierro el juego, se debe guardar o en el autoguardado, siempre la ruta en la que estan los npcs, no reiniciarse. Las rutas tambien modificarles el tiempo a cada una, ejemplo: ruta que va desde las 06:30am a las 09:00am, y asi ponerle fechas. Si un usuario la completa, entonces aleatoriamente se elije otra para que cambie su rutina y toma otra con respecto a la hora en la que está.