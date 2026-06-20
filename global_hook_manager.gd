extends Node
## GlobalHookManager — Manages the PowerShell global keyboard hook subprocess
## and UDP listener for receiving key events when the window is unfocused.

signal global_key_pressed

const UDP_PORT: int = 4000
const UDP_HOST: String = "127.0.0.1"

var _udp_server: PacketPeerUDP = PacketPeerUDP.new()
var _hook_pid: int = -1
var _is_bound: bool = false

func _ready() -> void:
	_start_udp_server()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_stop_hook()

func _process(_delta: float) -> void:
	if not _is_bound:
		return
	while _udp_server.get_available_packet_count() > 0:
		var packet = _udp_server.get_packet()
		if packet.size() > 0:
			global_key_pressed.emit()

# ─── Lifecycle ────────────────────────────────────────────────

func _start_udp_server() -> void:
	var err = _udp_server.bind(UDP_PORT, UDP_HOST)
	if err == OK:
		_is_bound = true
		print("[GlobalHook] UDP server listening on port ", UDP_PORT)
		_start_hook_subprocess()
	else:
		print("[GlobalHook] Failed to bind UDP port ", UDP_PORT, ": error ", err)

func _start_hook_subprocess() -> void:
	var hook_path = ProjectSettings.globalize_path("res://global_hook.ps1")
	var args = [
		"-ExecutionPolicy", "Bypass",
		"-File", hook_path,
		"-HostIP", UDP_HOST,
		"-Port", str(UDP_PORT),
		"-ParentPid", str(OS.get_process_id())
	]
	_hook_pid = OS.create_process("powershell.exe", args)
	if _hook_pid != -1:
		print("[GlobalHook] Started global_hook.ps1 with PID: ", _hook_pid)
	else:
		print("[GlobalHook] Failed to start global_hook.ps1")

func _stop_hook() -> void:
	if _hook_pid != -1:
		OS.kill(_hook_pid)
		_hook_pid = -1
	if _is_bound:
		_udp_server.close()
		_is_bound = false

func is_active() -> bool:
	return _is_bound and _hook_pid != -1
