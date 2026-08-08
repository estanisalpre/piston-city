extends RefCounted
class_name MessagesCenter

## Único punto de entrada para mandar mensajes a la bandeja del jugador
## (Game.state.messages). Cualquier sistema que necesite avisarle algo al
## jugador pasa por acá, para que el shape del mensaje sea siempre el mismo.

static func send(title: String, body: String) -> void:
	Game.state.messages.append({
		"title": title,
		"body": body,
		"day": Game.state.day,
		"read": false,
	})

static func unread_count() -> int:
	var count := 0
	for message in Game.state.messages:
		if not message.get("read", false):
			count += 1
	return count
