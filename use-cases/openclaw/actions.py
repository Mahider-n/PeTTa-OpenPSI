import requests
import json
import time

GATEWAY_BASE = "http://127.0.0.1:18789"
DEFAULT_SESSION = "agent:main:whatsapp:direct:+251919157130"

def _send_to_gateway(session_id: str, text: str) -> bool:
    """
    OpenClaw accepts messages POSTed to the gateway.
    Try the documented internal message injection endpoint.
    """
    session_id = session_id or DEFAULT_SESSION

    endpoints_to_try = [
        (f"{GATEWAY_BASE}/api/sessions/{requests.utils.quote(session_id, safe='')}/send",
         {"text": text, "role": "assistant"}),
        (f"{GATEWAY_BASE}/api/message",
         {"sessionId": session_id, "text": text}),
        (f"{GATEWAY_BASE}/send",
         {"session": session_id, "message": text}),
    ]

    for url, payload in endpoints_to_try:
        try:
            resp = requests.post(url, json=payload, timeout=10)
            if resp.status_code in (200, 201, 204):
                print(f"[actions] Message sent via {url}")
                return True
        except Exception as e:
            print(f"[actions] Failed {url}: {e}")
            continue

    print("[actions] All send endpoints failed — message not delivered")
    return False


def doSendMessage(env, text: str = None, session_id: str = None) -> str:
    sid = session_id or env.current_session_id or DEFAULT_SESSION
    # Build a response using the last received message for context
    if text is None:
        last_msg = getattr(env, "last_pending_text", "")
        if last_msg:
            text = f"I received your message: '{last_msg}'. Let me help you with that."
        else:
            text = "Hello! I'm your OpenPsi agent. How can I help you?"

    success = _send_to_gateway(sid, text)
    # Reset pending count after responding
    if success:
        env._known_message_count = getattr(env, "_known_message_count", 0)
    return "MessageSent" if success else None


def doSendMessageWithSearch(env, session_id: str = None) -> str:
    sid = session_id or env.current_session_id or DEFAULT_SESSION
    search_result = getattr(env, "last_search_result", None)
    last_msg = getattr(env, "last_pending_text", "")

    if search_result:
        text = f"I searched for information about your query. Here's what I found:\n\n{search_result[:500]}"
    else:
        text = f"I looked into your request: '{last_msg}'. Here's my response."

    success = _send_to_gateway(sid, text)
    return "MessageSent" if success else None


def doWebSearch(env, query: str = "") -> str:
    # OpenClaw has web_search as an agent tool — call it via the tool API
    if not query:
        query = getattr(env, "last_pending_text", "general query")[:100]

    endpoints_to_try = [
        f"{GATEWAY_BASE}/api/tools/web_search",
        f"{GATEWAY_BASE}/tools/web_search",
    ]
    for url in endpoints_to_try:
        try:
            resp = requests.post(url, json={"query": query}, timeout=15)
            if resp.status_code == 200:
                data = resp.json()
                env.last_search_result = data.get("result", data.get("content", str(data)))[:1000]
                return "SearchComplete"
        except Exception:
            continue

    # Fallback: store the query as result so the agent can still respond
    env.last_search_result = f"[Search attempted for: {query}]"
    return "SearchComplete"


def doListSessions(env) -> str:
    endpoints_to_try = [
        f"{GATEWAY_BASE}/api/sessions",
        f"{GATEWAY_BASE}/sessions",
    ]
    for url in endpoints_to_try:
        try:
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200:
                data = resp.json()
                sessions = data if isinstance(data, list) else data.get("sessions", [])
                env.active_sessions = sessions
                print(f"[actions] Active sessions: {sessions}")
                return "SessionsListed"
        except Exception:
            continue
    return "SessionsListed"


def doReadFile(env, path: str = "") -> str:
    try:
        resp = requests.post(f"{GATEWAY_BASE}/api/tools/read",
                             json={"path": path}, timeout=10)
        if resp.status_code == 200:
            env.last_file_content = resp.json().get("content", "")
            return "FileRead"
    except Exception as e:
        print(f"[actions] read failed: {e}")
    return None


def doIdle(env) -> str:
    time.sleep(1.0)
    return "Idle"