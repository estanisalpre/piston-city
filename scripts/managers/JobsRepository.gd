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
			{"title": "Lavado exterior básico", "description": "Lavar la carrocería y dejarla presentable."},
			{"title": "Limpieza interior simple", "description": "Aspirar y limpiar asientos y pisos."},
		],
		[
			{"title": "Abrillantado de llantas", "description": "Limpiar y abrillantar las llantas."},
			{"title": "Limpieza de rines", "description": "Quitar el polvo de freno acumulado en los rines."},
		],
		[
			{"title": "Encerado de carrocería", "description": "Aplicar cera (wax) para proteger la pintura."},
			{"title": "Wax de exhibición", "description": "Encerado a fondo para un auto que va a subasta."},
		],
		[
			{"title": "Degrasado de motor", "description": "Limpiar el compartimento del motor sin dañar el cableado."},
			{"title": "Detailing de compartimento", "description": "Dejar el motor presentable para una inspección."},
		],
		[
			{"title": "Detailing profesional completo", "description": "Pulido de pintura para quitar rayones superficiales."},
			{"title": "Tratamiento de cuero", "description": "Dejar el interior de cuero a nivel de exhibición."},
		],
	],
	SkillIds.MECANICA_GENERAL: [
		[
			{"title": "Revisión y relleno de aceite", "description": "Medir el nivel de aceite y rellenar si hace falta."},
			{"title": "Cambio de filtro y refrigerante", "description": "Cambiar el filtro de aire y el refrigerante."},
		],
		[
			{"title": "Cambio de bujías", "description": "Reemplazar las bujías del motor."},
			{"title": "Purga básica de frenos", "description": "Purgar el sistema de frenos."},
		],
		[
			{"title": "Cambio de correa de distribución", "description": "Reemplazar la correa sin sincronización fina."},
			{"title": "Diagnóstico de ruidos del motor", "description": "Identificar el origen de un ruido común del motor."},
		],
		[
			{"title": "Reparación completa de frenos", "description": "Cambiar discos, pastillas y líquido de frenos."},
			{"title": "Diagnóstico con scanner OBD", "description": "Escanear el vehículo y leer los códigos de falla."},
		],
		[
			{"title": "Diagnóstico mecánico experto", "description": "Resolver una falla mecánica poco común."},
			{"title": "Reparación de \"no arranca\"", "description": "El cliente reporta que el auto no arranca."},
		],
	],
	SkillIds.DESMANTELADOR: [
		[
			{"title": "Retiro de espejos y manijas", "description": "Desmontar espejos y manijas exteriores."},
			{"title": "Retiro de parachoques", "description": "Desmontar el parachoques delantero."},
		],
		[
			{"title": "Desarme de asientos y tablero", "description": "Retirar asientos y tablero del interior."},
			{"title": "Retiro de puertas completas", "description": "Desmontar las puertas completas del vehículo."},
		],
		[
			{"title": "Extracción del motor", "description": "Sacar el motor completo de su compartimento."},
			{"title": "Desarme de compartimento", "description": "Dejar el compartimento del motor vacío y ordenado."},
		],
		[
			{"title": "Desarme total de carrocería", "description": "Dejar el chasis desnudo, sin dañar piezas reutilizables."},
			{"title": "Chasis desnudo", "description": "Terminar el desarme completo para reventa de piezas."},
		],
		[
			{"title": "Desarme y rearme completo", "description": "Desarmar el vehículo entero sin perder ninguna pieza."},
			{"title": "Recuperación total de piezas", "description": "Recuperar el máximo de piezas reutilizables de un auto."},
		],
	],
	SkillIds.TORQUE_HP: [
		[
			{"title": "Diagnóstico de rendimiento", "description": "Conectar la computadora y leer el HP/torque de fábrica."},
			{"title": "Lectura de HP y torque", "description": "Medir el rendimiento actual antes de preparar el motor."},
		],
		[
			{"title": "Instalación de filtro deportivo", "description": "Cambiar el filtro de aire por uno deportivo."},
			{"title": "Instalación de escape libre", "description": "Instalar un sistema de escape libre."},
		],
		[
			{"title": "Chip tuning moderado", "description": "Ajustar el mapa de la ECU para ganancias moderadas."},
			{"title": "Reprogramación de ECU", "description": "Reprogramar la ECU con un mapeo intermedio."},
		],
		[
			{"title": "Instalación de turbo", "description": "Instalar turbo/intercooler y ajustar la mezcla aire-combustible."},
			{"title": "Ajuste de mezcla aire-combustible", "description": "Calibrar la mezcla tras instalar sobrealimentación."},
		],
		[
			{"title": "Motor de competición", "description": "Preparar un motor a su máximo HP posible."},
			{"title": "Mapeo extremo de ECU", "description": "Ajustar un mapeo extremo con internos forjados."},
		],
	],
	SkillIds.PINTURA: [
		[
			{"title": "Masillado de abolladura", "description": "Quitar una abolladura pequeña de un panel."},
			{"title": "Reparación de panel simple", "description": "Masillar y dejar liso un panel golpeado."},
		],
		[
			{"title": "Lijado de superficie", "description": "Lijar la carrocería completa antes de pintar."},
			{"title": "Preparación previa a pintura", "description": "Dejar la superficie lista para recibir pintura."},
		],
		[
			{"title": "Pintura de panel individual", "description": "Pintar un panel con acabado uniforme."},
			{"title": "Acabado uniforme de panel", "description": "Igualar el color de un panel repintado."},
		],
		[
			{"title": "Pintura completa del vehículo", "description": "Pintar el auto entero con un color personalizado."},
			{"title": "Mezcla de color personalizado", "description": "Mezclar un color a pedido del cliente."},
		],
		[
			{"title": "Acabado premium de exhibición", "description": "Acabado mate o cromado de nivel de exhibición."},
			{"title": "Diseño personalizado (livery)", "description": "Aplicar un diseño/livery a pedido del cliente."},
		],
	],
	SkillIds.NEUMATICOS: [
		[
			{"title": "Cambio de neumáticos", "description": "Desmontar y montar un juego de neumáticos."},
			{"title": "Montaje y desmontaje de rueda", "description": "Cambiar una rueda dañada por una nueva."},
		],
		[
			{"title": "Balanceo de ruedas", "description": "Balancear las cuatro ruedas del vehículo."},
			{"title": "Balanceo delantero y trasero", "description": "Balancear ruedas después de un cambio de neumáticos."},
		],
		[
			{"title": "Alineación de dirección", "description": "Alinear la dirección del vehículo."},
			{"title": "Ajuste de convergencia", "description": "Corregir la convergencia tras un cambio de suspensión."},
		],
		[
			{"title": "Cambio de amortiguadores", "description": "Reemplazar los amortiguadores estándar."},
			{"title": "Cambio de resortes", "description": "Reemplazar los resortes de suspensión estándar."},
		],
		[
			{"title": "Instalación de coilover", "description": "Instalar una suspensión coilover ajustable."},
			{"title": "Calibración de altura y dureza", "description": "Calibrar el coilover para uso en pista."},
		],
	],
	SkillIds.ELECTRICIDAD: [
		[
			{"title": "Cambio de batería", "description": "Cambiar la batería y revisar fusibles."},
			{"title": "Cambio de bombillas", "description": "Reemplazar bombillas de luces quemadas."},
		],
		[
			{"title": "Instalación de radio", "description": "Instalar un equipo de audio nuevo."},
			{"title": "Instalación de LED y alarma", "description": "Instalar luces LED y una alarma."},
		],
		[
			{"title": "Reparación de cortocircuito", "description": "Encontrar y reparar un cortocircuito."},
			{"title": "Diagnóstico de cableado dañado", "description": "Diagnosticar cableado dañado por humedad o roedores."},
		],
		[
			{"title": "Reparación de alza-cristales", "description": "Reparar el mecanismo eléctrico de una ventanilla."},
			{"title": "Programación de módulo", "description": "Programar un módulo electrónico de reemplazo."},
		],
		[
			{"title": "Instalación de arnés completo", "description": "Instalar un arnés eléctrico personalizado."},
			{"title": "Diagnóstico eléctrico complejo", "description": "Resolver una falla eléctrica difícil de aislar."},
		],
	],
	SkillIds.MOTOR: [
		[
			{"title": "Cambio de bandas y mangueras", "description": "Reemplazar bandas y mangueras del motor."},
			{"title": "Revisión de juntas simples", "description": "Revisar juntas simples en busca de pérdidas."},
		],
		[
			{"title": "Cambio de tapa de válvulas", "description": "Cambiar la junta de la tapa de válvulas."},
			{"title": "Cambio de retenes simples", "description": "Reemplazar retenes sin abrir el bloque."},
		],
		[
			{"title": "Rectificado de culata", "description": "Rectificar la culata del motor."},
			{"title": "Cambio de junta de culata", "description": "Reemplazar la junta de la cabeza del motor."},
		],
		[
			{"title": "Reparación de pistones y bielas", "description": "Reparar pistones y bielas con el bloque abierto."},
			{"title": "Reparación de cigüeñal", "description": "Reparar el cigüeñal del motor."},
		],
		[
			{"title": "Reconstrucción completa de motor", "description": "Rearmar un motor desde el bloque desnudo."},
			{"title": "Motor \"chatarra\" a funcional", "description": "Devolver a la vida un motor dado por perdido."},
		],
	],
	SkillIds.TRANSMISION_CHASIS: [
		[
			{"title": "Relleno de líquido de transmisión", "description": "Revisar y rellenar el líquido de la caja."},
			{"title": "Revisión de caja de cambios", "description": "Revisar el estado general de la caja de cambios."},
		],
		[
			{"title": "Cambio de embrague", "description": "Reemplazar el embrague en una caja manual."},
			{"title": "Cambio de disco de clutch", "description": "Cambiar el disco de embrague desgastado."},
		],
		[
			{"title": "Reparación de caja de cambios", "description": "Reparar una caja manual o automática estándar."},
			{"title": "Cambio de caja completa", "description": "Reemplazar la caja de cambios completa."},
		],
		[
			{"title": "Instalación de diferencial LSD", "description": "Instalar un diferencial de deslizamiento limitado."},
			{"title": "Ajuste de relación de transmisión", "description": "Ajustar la relación de transmisión del vehículo."},
		],
		[
			{"title": "Instalación de caja secuencial", "description": "Instalar una caja de cambios secuencial."},
			{"title": "Refuerzo estructural de chasis", "description": "Reforzar el chasis para alta potencia."},
		],
	],
	SkillIds.TASACION: [
		[
			{"title": "Tasación de mercado", "description": "Estimar el precio de mercado de un vehículo."},
			{"title": "Estimación de precio de venta", "description": "Calcular a cuánto conviene vender un vehículo."},
		],
		[
			{"title": "Detección de defectos ocultos", "description": "Encontrar defectos que no se ven a simple vista."},
			{"title": "Inspección previa a compra", "description": "Inspeccionar un vehículo antes de comprarlo."},
		],
		[
			{"title": "Negociación en el desguace", "description": "Negociar un descuento en el desguasadero."},
			{"title": "Negociación en marketplace", "description": "Negociar el precio de un vehículo del marketplace."},
		],
		[
			{"title": "Identificación de \"gema oculta\"", "description": "Detectar un vehículo con piezas raras antes que otros."},
			{"title": "Búsqueda de edición limitada", "description": "Encontrar una edición limitada entre varios listados."},
		],
		[
			{"title": "Negociación experta", "description": "Cerrar el mejor precio posible en una negociación difícil."},
			{"title": "Tasación con defectos ocultos", "description": "Tasar un vehículo con defectos ocultos sin pagar de más."},
		],
	],
}

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
				job.title = template.title
				job.description = template.description
				job.required_skill = skill_id
				job.required_level = level
				job.reward_money = rewards.money
				job.reward_exp = rewards.exp
				# Reparto parejo entre los NPCs del roster — siempre el
				# mismo NPC para el mismo id de encargo.
				job.npc_id = NpcRoster.ALL[npc_counter % NpcRoster.ALL.size()]
				npc_counter += 1
				jobs.append(job)

	return jobs

static func is_job_available(job: JobData) -> bool:
	var player_level: int = Game.state.skill_levels.get(job.required_skill, 1)
	return player_level >= job.required_level

static func get_job(job_id: String) -> JobData:
	for job in get_all_jobs():
		if job.id == job_id:
			return job
	return null
