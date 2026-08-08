extends RefCounted
class_name SkillIds

## IDs de las 10 habilidades. Ver docs/habilidades-y-escuela.md para el detalle
## de qué desbloquea cada nivel de cada una.

const LAVADO := "lavado"
const MECANICA_GENERAL := "mecanica_general"
const DESMANTELADOR := "desmantelador"
const TORQUE_HP := "torque_hp"
const PINTURA := "pintura"
const NEUMATICOS := "neumaticos"
const ELECTRICIDAD := "electricidad"
const MOTOR := "motor"
const TRANSMISION_CHASIS := "transmision_chasis"
const TASACION := "tasacion"

const ALL := [
	LAVADO, MECANICA_GENERAL, DESMANTELADOR, TORQUE_HP, PINTURA,
	NEUMATICOS, ELECTRICIDAD, MOTOR, TRANSMISION_CHASIS, TASACION,
]

const DISPLAY_NAMES := {
	LAVADO: "Lavado y Detailing",
	MECANICA_GENERAL: "Mecánica General",
	DESMANTELADOR: "Desmantelador",
	TORQUE_HP: "Torque / HP",
	PINTURA: "Pintura",
	NEUMATICOS: "Neumáticos",
	ELECTRICIDAD: "Electricidad",
	MOTOR: "Motor",
	TRANSMISION_CHASIS: "Transmisión y Chasis",
	TASACION: "Tasación",
}
