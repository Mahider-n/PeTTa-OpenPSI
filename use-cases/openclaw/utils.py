
import re
import time
from typing import Optional
from type import ActionType, Observation
from openclaw_env import OpenClawEnvironment
import observation as observationOps

currentEnv: Optional[OpenClawEnvironment] = None


def connectToOpenClaw() -> str:
    global currentEnv
    env = OpenClawEnvironment()
    if env.connect():
        currentEnv = env
        return "Connected to OpenClaw"
    return "Failed to connect to OpenClaw. Is the Gateway running?"


def disconnectFromOpenClaw() -> str:
    if currentEnv:
        currentEnv.disconnect()
    return "Disconnected"


def getObservation():
    """Called from MeTTa: returns list of Metta atoms"""
    env = OpenClawEnvironment()    
    
    observationOps.buildObservation(env)          
    return getattr(env, 'metta_observation_atoms', ["(hasMessage False)", "(unansweredCount 0)"])


def executeAction(actionName: str, *args):
    if not currentEnv:
        print("[utils] executeAction called but not connected.")
        return []

    action_map = {
        "send_message":              ActionType.SEND_MESSAGE,
        "send_message_with_search":  ActionType.SEND_MESSAGE_WITH_SEARCH,
        "web_search":                ActionType.WEB_SEARCH,
        "read_file":                 ActionType.READ_FILE,
        "write_file":                ActionType.WRITE_FILE,
        "list_sessions":             ActionType.LIST_SESSIONS,
        "idle":                      ActionType.IDLE,
    }

    normalized = actionName.strip().lower().replace(" ", "_")

    if "_" not in normalized:
        normalized = re.sub(r"(?<!^)(?=[A-Z])", "_", actionName).lower()

    action_type = action_map.get(normalized)
    if action_type:
        result = currentEnv.executeAction(action_type, *args) or []
        return result

    print(f"[utils] Unknown action: '{actionName}' (normalized: '{normalized}')")
    return []


def sleepSeconds(seconds: float = 0.5):
    time.sleep(max(0.0, float(seconds)))
    return "ok"


def getUrgencyLevel() -> str:
    if not currentEnv:
        return "0.0"
    obs = currentEnv.getObservation()
    return str(obs.message_urgency)


def getUnansweredCount() -> str:
    if not currentEnv:
        return "0"
    obs = currentEnv.getObservation()
    return str(obs.unanswered_count)


def toSymbol(value) -> str:
    text = str(value or "").strip().lower()
    text = re.sub(r"[^a-z0-9_]", "_", text)
    text = re.sub(r"_+", "_", text)
    text = text.strip("_")
    return text or "unknown"


def observationToMetta(obs: Observation) -> list:
    atoms = []
    atoms.append(f"(sender {toSymbol(obs.sender)})")
    atoms.append(f"(channel {toSymbol(obs.channel)})")
    atoms.append(f"(session {toSymbol(obs.session_id)})")
    atoms.append(f"(urgency {round(obs.message_urgency, 3)})")
    atoms.append(f"(unansweredCount {obs.unanswered_count})")
    atoms.append(f"(timeSinceMessage {round(obs.time_since_last_message, 1)})")
    atoms.append(f"(lastActionSuccess {str(obs.last_action_success).lower()})")
    atoms.append(f"(hasMessage {str(obs.unanswered_count > 0).lower()})")

    if obs.message_text:
        safe = toSymbol(obs.message_text[:40])
        atoms.append(f"(messageText {safe})")

    if obs.web_search_result:
        atoms.append(f"(hasSearchResult true)")

    for s in obs.active_sessions:
        atoms.append(f"(activeSession {toSymbol(s)})")

    return atoms
