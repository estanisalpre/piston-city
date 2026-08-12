extends RefCounted
class_name JobsRepository

## Única puerta de entrada a la lista de encargos. La app de Trabajos
## (celular) nunca debe leer una lista hardcodeada propia: siempre pasa
## por acá. El día que los encargos vengan de otro lado (generados,
## servidor, etc.) solo se cambia esta clase.
##
## Hay 2 encargos por cada nivel (1-5) de cada una de las 10 habilidades
## (ver docs/habilidades-y-escuela.md sección 4 — el texto de cada uno
## sale de lo que ese nivel "desbloquea" ahí). JobsRepository no filtra
## por nivel del jugador: eso lo hace quien consuma get_all_jobs()
## (hoy, Jobs.gd), usando is_job_available().

## Recompensa por trabajo completado, según el nivel que pide (1-5).
## Provisorio — ver docs/habilidades-y-escuela.md sección 2 (misma idea:
## se rebalancea con la economía real, hoy son ~4 trabajos por nivel
## para juntar el umbral de EXP del siguiente).
const LEVEL_REWARDS := [
	{"exp": 25, "money": 400},
	{"exp": 75, "money": 1200},
	{"exp": 175, "money": 3000},
	{"exp": 375, "money": 6000},
	{"exp": 375, "money": 9000},
]

const JOB_TEMPLATES := {
	SkillIds.LAVADO: [
		[
			# 1
			{"title": "Lavado exterior básico", "description": "Lavar la carrocería y dejarla presentable."},
			{"title": "Limpieza interior simple", "description": "Aspirar y limpiar asientos y pisos."},
		],
		[	
			# 2
			{"title": "Abrillantado de llantas", "description": "Limpiar y abrillantar las llantas."},
			{"title": "Limpieza de rines", "description": "Quitar el polvo de freno acumulado en los rines."},
		],
		[
			# 3
			{"title": "Encerado de carrocería", "description": "Aplicar cera (wax) para proteger la pintura."},
			{"title": "Wax de exhibición", "description": "Encerado a fondo para un auto que va a subasta."},
		],
		[
			# 4
			{"title": "Degrasado de motor", "description": "Limpiar el compartimento del motor sin dañar el cableado."},
			{"title": "Detailing de compartimento", "description": "Dejar el motor presentable para una inspección."},
		],
		[
			# 5
			{"title": "Detailing profesional completo", "description": "Pulido de pintura para quitar rayones superficiales."},
			{"title": "Tratamiento de cuero", "description": "Dejar el interior de cuero a nivel de exhibición."},
		],
	],
	SkillIds.MECANICA_GENERAL: [
		[
			# 1
			{"title": "Revisión y relleno de aceite", "description": "Medir el nivel de aceite y rellenar si hace falta."},
			{"title": "Cambio de filtro y refrigerante", "description": "Cambiar el filtro de aire y el refrigerante."},
		],
		[
			# 2
			{"title": "Cambio de bujías", "description": "Reemplazar las bujías del motor."},
			{"title": "Purga básica de frenos", "description": "Purgar el sistema de frenos."},
		],
		[
			# 3
			{"title": "Cambio de correa de distribución", "description": "Reemplazar la correa sin sincronización fina."},
			{"title": "Diagnóstico de ruidos del motor", "description": "Identificar el origen de un ruido común del motor."},
		],
		[
			# 4
			{"title": "Reparación completa de frenos", "description": "Cambiar discos, pastillas y líquido de frenos."},
			{"title": "Diagnóstico con scanner OBD", "description": "Escanear el vehículo y leer los códigos de falla."},
		],
		[
			# 5
			{"title": "Diagnóstico mecánico experto", "description": "Resolver una falla mecánica poco común."},
			{"title": "Reparación de \"no arranca\"", "description": "El cliente reporta que el auto no arranca."},
		],
	],
	SkillIds.DESMANTELADOR: [
		[
			# 1
			{"title": "Retiro de espejos y manijas", "description": "Desmontar espejos y manijas exteriores."},
			{"title": "Retiro de parachoques", "description": "Desmontar el parachoques delantero."},
		],
		[
			# 2
			{"title": "Desarme de asientos y tablero", "description": "Retirar asientos y tablero del interior."},
			{"title": "Retiro de puertas completas", "description": "Desmontar las puertas completas del vehículo."},
		],
		[
			# 3
			{"title": "Extracción del motor", "description": "Sacar el motor completo de su compartimento."},
			{"title": "Desarme de compartimento", "description": "Dejar el compartimento del motor vacío y ordenado."},
		],
		[
			# 4
			{"title": "Desarme total de carrocería", "description": "Dejar el chasis desnudo, sin dañar piezas reutilizables."},
			{"title": "Chasis desnudo", "description": "Terminar el desarme completo para reventa de piezas."},
		],
		[
			# 5
			{"title": "Desarme y rearme completo", "description": "Desarmar el vehículo entero sin perder ninguna pieza."},
			{"title": "Recuperación total de piezas", "description": "Recuperar el máximo de piezas reutilizables de un auto."},
		],
	],
	SkillIds.TORQUE_HP: [
		[
			# 1
			{"title": "Diagnóstico de rendimiento", "description": "Conectar la computadora y leer el HP/torque de fábrica."},
			{"title": "Lectura de HP y torque", "description": "Medir el rendimiento actual antes de preparar el motor."},
		],
		[
			# 2
			{"title": "Instalación de filtro deportivo", "description": "Cambiar el filtro de aire por uno deportivo."},
			{"title": "Instalación de escape libre", "description": "Instalar un sistema de escape libre."},
		],
		[
			# 3
			{"title": "Chip tuning moderado", "description": "Ajustar el mapa de la ECU para ganancias moderadas."},
			{"title": "Reprogramación de ECU", "description": "Reprogramar la ECU con un mapeo intermedio."},
		],
		[
			# 4
			{"title": "Instalación de turbo", "description": "Instalar turbo/intercooler y ajustar la mezcla aire-combustible."},
			{"title": "Ajuste de mezcla aire-combustible", "description": "Calibrar la mezcla tras instalar sobrealimentación."},
		],
		[
			# 5
			{"title": "Motor de competición", "description": "Preparar un motor a su máximo HP posible."},
			{"title": "Mapeo extremo de ECU", "description": "Ajustar un mapeo extremo con internos forjados."},
		],
	],
	SkillIds.PINTURA: [
		[
			# 1
			{"title": "Masillado de abolladura", "description": "Quitar una abolladura pequeña de un panel."},
			{"title": "Reparación de panel simple", "description": "Masillar y dejar liso un panel golpeado."},
		],
		[
			# 2
			{"title": "Lijado de superficie", "description": "Lijar la carrocería completa antes de pintar."},
			{"title": "Preparación previa a pintura", "description": "Dejar la superficie lista para recibir pintura."},
		],
		[
			# 3
			{"title": "Pintura de panel individual", "description": "Pintar un panel con acabado uniforme."},
			{"title": "Acabado uniforme de panel", "description": "Igualar el color de un panel repintado."},
		],
		[
			# 4
			{"title": "Pintura completa del vehículo", "description": "Pintar el auto entero con un color personalizado."},
			{"title": "Mezcla de color personalizado", "description": "Mezclar un color a pedido del cliente."},
		],
		[
			# 5
			{"title": "Acabado premium de exhibición", "description": "Acabado mate o cromado de nivel de exhibición."},
			{"title": "Diseño personalizado (livery)", "description": "Aplicar un diseño/livery a pedido del cliente."},
		],
	],
	SkillIds.NEUMATICOS: [ # gomeria - tires_shop
		[
			# 1
			{"title": "Cambio de neumáticos", "description": "Desmontar y montar un juego de neumáticos."}, 
			# 1.1 = ¿Qué acción se hará?
			

			{"title": "Montaje y desmontaje de rueda", "description": "Cambiar una rueda dañada por una nueva."},
			# 1.2 = ¿Qué acción se hará?
			# Nos dará 25 exp.
			# Se acepta el trabajo por el celular.
			# Se recibe el vehículo.
			# Nos acercamos al vehículo y elegimos el ícono de "Neumáticos"
			# Nos aparece otras opciones (tipo radial) que será: Quitar ruedas

			# Quitar rueda nos lleva a mostrar la rueda con los tornillos. Tenemos que hacer lo siguiente:
			# B + C + B — aflojar 4 tuercas en patrón estrella, 
			# Aparece el personaje con sprite manos alzadas y encima el ícono de lo que agarró (neumático) 
			# Tiene que ir a dejarlo al mismo lugar de donde cogió la otra rueda (si no la agarró aún no pasa nada). 
			# Este lugar sería donde se ponen las ruedas en el garage. Esta rueda "usada" ocupa un lugar tambien. Si no tiene ruedas "nuevas", va a la gomeria a comprar (ya implementado)

			# Deja la rueda con click derecho. Agarra una nueva (se desaparece del lugar de los neumáticos. Ahora la tiene encima de la cabeza otra vez).
			# Camina al auto, click derecho y misma animación y sistema para colocar el neumático.
			# Ya el vehiculo aparece con el neumático puesto. 
			# Celular ahora sí aparece "Entregar vehículo" que hace lo mismo que "avisarle al...". 
			# El npc empieza camino a buscar el carro.
			# Mismo sistema entregando, obteniendo dinero, sumando exp a este nivel específico.
		],
		[
			# 2
			{"title": "Balanceo de ruedas", "description": "Balancear las cuatro ruedas del vehículo."},
			{"title": "Balanceo delantero y trasero", "description": "Balancear ruedas después de un cambio de neumáticos."},
		],
		[
			# 3
			{"title": "Alineación de dirección", "description": "Alinear la dirección del vehículo."},
			{"title": "Ajuste de convergencia", "description": "Corregir la convergencia tras un cambio de suspensión."},
		],
		[
			# 4
			{"title": "Cambio de amortiguadores", "description": "Reemplazar los amortiguadores estándar."},
			{"title": "Cambio de resortes", "description": "Reemplazar los resortes de suspensión estándar."},
		],
		[
			# 5
			{"title": "Instalación de coilover", "description": "Instalar una suspensión coilover ajustable."},
			{"title": "Calibración de altura y dureza", "description": "Calibrar el coilover para uso en pista."},
		],
	],
	SkillIds.ELECTRICIDAD: [
		[
			# 1
			{"title": "Cambio de batería", "description": "Cambiar la batería y revisar fusibles."},
			{"title": "Cambio de bombillas", "description": "Reemplazar bombillas de luces quemadas."},
		],
		[
			# 2
			{"title": "Instalación de radio", "description": "Instalar un equipo de audio nuevo."},
			{"title": "Instalación de LED y alarma", "description": "Instalar luces LED y una alarma."},
		],
		[
			# 3
			{"title": "Reparación de cortocircuito", "description": "Encontrar y reparar un cortocircuito."},
			{"title": "Diagnóstico de cableado dañado", "description": "Diagnosticar cableado dañado por humedad o roedores."},
		],
		[
			# 4
			{"title": "Reparación de alza-cristales", "description": "Reparar el mecanismo eléctrico de una ventanilla."},
			{"title": "Programación de módulo", "description": "Programar un módulo electrónico de reemplazo."},
		],
		[
			# 5
			{"title": "Instalación de arnés completo", "description": "Instalar un arnés eléctrico personalizado."},
			{"title": "Diagnóstico eléctrico complejo", "description": "Resolver una falla eléctrica difícil de aislar."},
		],
	],
	SkillIds.MOTOR: [
		[
			# 1
			{"title": "Cambio de bandas y mangueras", "description": "Reemplazar bandas y mangueras del motor."},
			{"title": "Revisión de juntas simples", "description": "Revisar juntas simples en busca de pérdidas."},
		],
		[
			# 2
			{"title": "Cambio de tapa de válvulas", "description": "Cambiar la junta de la tapa de válvulas."},
			{"title": "Cambio de retenes simples", "description": "Reemplazar retenes sin abrir el bloque."},
		],
		[
			# 3
			{"title": "Rectificado de culata", "description": "Rectificar la culata del motor."},
			{"title": "Cambio de junta de culata", "description": "Reemplazar la junta de la cabeza del motor."},
		],
		[
			# 4
			{"title": "Reparación de pistones y bielas", "description": "Reparar pistones y bielas con el bloque abierto."},
			{"title": "Reparación de cigüeñal", "description": "Reparar el cigüeñal del motor."},
		],
		[
			# 5
			{"title": "Reconstrucción completa de motor", "description": "Rearmar un motor desde el bloque desnudo."},
			{"title": "Motor \"chatarra\" a funcional", "description": "Devolver a la vida un motor dado por perdido."},
		],
	],
	SkillIds.TRANSMISION_CHASIS: [
		[
			# 1
			{"title": "Relleno de líquido de transmisión", "description": "Revisar y rellenar el líquido de la caja."},
			{"title": "Revisión de caja de cambios", "description": "Revisar el estado general de la caja de cambios."},
		],
		[
			# 2
			{"title": "Cambio de embrague", "description": "Reemplazar el embrague en una caja manual."},
			{"title": "Cambio de disco de clutch", "description": "Cambiar el disco de embrague desgastado."},
		],
		[
			# 3
			{"title": "Reparación de caja de cambios", "description": "Reparar una caja manual o automática estándar."},
			{"title": "Cambio de caja completa", "description": "Reemplazar la caja de cambios completa."},
		],
		[
			# 4
			{"title": "Instalación de diferencial LSD", "description": "Instalar un diferencial de deslizamiento limitado."},
			{"title": "Ajuste de relación de transmisión", "description": "Ajustar la relación de transmisión del vehículo."},
		],
		[
			# 5
			{"title": "Instalación de caja secuencial", "description": "Instalar una caja de cambios secuencial."},
			{"title": "Refuerzo estructural de chasis", "description": "Reforzar el chasis para alta potencia."},
		],
	],
	SkillIds.TASACION: [
		[
			# 1
			{"title": "Tasación de mercado", "description": "Estimar el precio de mercado de un vehículo."},
			{"title": "Estimación de precio de venta", "description": "Calcular a cuánto conviene vender un vehículo."},
		],
		[
			# 2
			{"title": "Detección de defectos ocultos", "description": "Encontrar defectos que no se ven a simple vista."},
			{"title": "Inspección previa a compra", "description": "Inspeccionar un vehículo antes de comprarlo."},
		],
		[
			# 3
			{"title": "Negociación en el desguace", "description": "Negociar un descuento en el desguasadero."},
			{"title": "Negociación en marketplace", "description": "Negociar el precio de un vehículo del marketplace."},
		],
		[
			# 4
			{"title": "Identificación de \"gema oculta\"", "description": "Detectar un vehículo con piezas raras antes que otros."},
			{"title": "Búsqueda de edición limitada", "description": "Encontrar una edición limitada entre varios listados."},
		],
		[
			# 5
			{"title": "Negociación experta", "description": "Cerrar el mejor precio posible en una negociación difícil."},
			{"title": "Tasación con defectos ocultos", "description": "Tasar un vehículo con defectos ocultos sin pagar de más."},
		],
	],
}

## Filtro temporal de testeo — con un id acá, get_all_jobs() devuelve
## SOLO ese encargo (ignora todos los demás), para probar una mecánica
## puntual sin que el resto ensucie la lista del celular. Dejalo en ""
## para volver a ver todos los encargos.
const DEBUG_ONLY_JOB_ID := "neumaticos_lvl1_2"

## Igual de temporal — fuerza qué NPC trae el encargo de prueba, para no
## depender del horario de un NPC dueño de local mientras testeás (ver
## JobsRepository.is_job_available/NpcDirector.is_workplace_open).
## Dejalo en "" para volver al reparto automático de siempre.
const DEBUG_FORCE_NPC_ID := "npc_02"

static func get_all_jobs() -> Array[JobData]:
	var jobs: Array[JobData] = []
	var npc_counter := 0

	for skill_id in JOB_TEMPLATES:
		var levels: Array = JOB_TEMPLATES[skill_id]
		for level_index in levels.size():
			var level := level_index + 1
			var rewards: Dictionary = LEVEL_REWARDS[level_index]
			var variants: Array = levels[level_index]
			for variant_index in variants.size():
				var template: Dictionary = variants[variant_index]
				var job := JobData.new()
				job.id = "%s_lvl%d_%d" % [skill_id, level, variant_index + 1]

				if DEBUG_ONLY_JOB_ID != "" and job.id != DEBUG_ONLY_JOB_ID:
					npc_counter += 1
					continue

				job.title = template.title
				job.description = template.description
				job.required_skill = skill_id
				job.required_level = level
				job.reward_money = rewards.money
				job.reward_exp = rewards.exp
				# Reparto parejo entre los NPCs del roster — siempre el
				# mismo NPC para el mismo id de encargo.
				job.npc_id = DEBUG_FORCE_NPC_ID if DEBUG_FORCE_NPC_ID != "" else NpcRoster.ALL[npc_counter % NpcRoster.ALL.size()]
				npc_counter += 1
				jobs.append(job)

	return jobs

static func is_job_available(job: JobData) -> bool:
	var player_level: int = Game.state.skill_levels.get(job.required_skill, 1)
	if player_level < job.required_level:
		return false

	if Game.state.day < Game.state.npc_cooldowns.get(job.npc_id, 0):
		return false  # ese NPC no está ofreciendo trabajos nuevos todavía

	if Game.state.day < Game.state.job_cooldowns.get(job.id, 0):
		return false  # este encargo puntual ya se hizo hace poco

	if NpcDirector.is_workplace_open(job.npc_id):
		return false  # está atendiendo su propio local ahora mismo, no puede salir a traerte un encargo

	return true

static func get_job(job_id: String) -> JobData:
	for job in get_all_jobs():
		if job.id == job_id:
			return job
	return null
