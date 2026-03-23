
import json
import time
import threading
import hashlib
import hmac
import os

try:
    import websocket
    WEBSOCKET_AVAILABLE = True
except ImportError:
    WEBSOCKET_AVAILABLE = False
    print("[gateway] Install websocket-client: pip install websocket-client")

from type import Observation

GATEWAY_WS      = "ws://127.0.0.1:18789"
DEFAULT_SESSION = "agent:main:whatsapp:direct:+251919157130"

GATEWAY_TOKEN = os.getenv("OPENCLAW_TOKEN", "")


def _sign_challenge(nonce: str, token: str) -> str:
    return hmac.new(
        token.encode("utf-8"),
        nonce.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


class GatewayClient:
    def __init__(self):
        self.ws             = None
        self.connected      = False
        self.authenticated  = False
        self._lock          = threading.Lock()
        self._thread        = None
        self._ready         = threading.Event()
        self._all_frames    = []
        self._user_messages = []

    def connect(self) -> bool:
        if not WEBSOCKET_AVAILABLE:
            print("[gateway] websocket-client not installed")
            return False

        def on_open(ws):
            self.connected = True
            print("[gateway] WebSocket open — waiting for challenge...")

        def on_message(ws, raw):
            with self._lock:
                self._all_frames.append(raw)
            self._handle(ws, raw)

        def on_error(ws, err):
            print(f"[gateway] error: {err}")
            self._ready.set()

        def on_close(ws, code, msg):
            self.connected     = False
            self.authenticated = False
            print(f"[gateway] closed: {code} {msg}")
            self._ready.set()

        self.ws = websocket.WebSocketApp(
            GATEWAY_WS,
            on_open=on_open, on_message=on_message,
            on_error=on_error, on_close=on_close,
        )
        self._thread = threading.Thread(target=self.ws.run_forever, daemon=True)
        self._thread.start()
        self._ready.wait(timeout=8.0)
        return self.connected and self.authenticated

    def send_message(self, session_id: str, text: str) -> bool:
        if not self.authenticated:
            print("[gateway] not authenticated")
            return False
        try:
            self.ws.send(json.dumps({
                "type":    "event",
                "event":   "session.send",
                "payload": {"sessionId": session_id, "message": text, "role": "assistant"},
            }))
            return True
        except Exception as e:
            print(f"[gateway] send failed: {e}")
            return False

    def get_user_messages(self, session_id: str) -> list:
        with self._lock:
            return list(self._user_messages)

    def dump_frames(self):
        with self._lock:
            frames = list(self._all_frames)
        print(f"\n=== {len(frames)} WS frames ===")
        for i, f in enumerate(frames):
            print(f"  [{i}] {f[:400]}")

    def _handle(self, ws, raw: str):
        try:
            data = json.loads(raw)
        except Exception:
            return

        event   = data.get("event", "")
        payload = data.get("payload", {})
        typ     = data.get("type", "")

        if event == "connect.challenge":
            nonce = payload.get("nonce", "")
            print(f"[gateway] challenge nonce={nonce}")
            sig = _sign_challenge(nonce, GATEWAY_TOKEN) if GATEWAY_TOKEN else ""
            if not GATEWAY_TOKEN:
                print("[gateway] WARNING: OPENCLAW_TOKEN not set")
                print("   Find it: cat ~/.config/openclaw/config.json | python3 -m json.tool")
                print("   Then:    export OPENCLAW_TOKEN=your_token && metta main.metta")
            ws.send(json.dumps({
                "type":    "event",
                "event":   "connect.auth",
                "payload": {"nonce": nonce, "signature": sig},
            }))
            return

        if event in ("connect.ready", "connect.ok", "ready"):
            print("[gateway] authenticated OK")
            self.authenticated = True
            self._subscribe(ws)
            self._ready.set()
            return

        if event in ("connect.error", "auth.error", "auth.failed"):
            print(f"[gateway] auth FAILED: {data}")
            self._ready.set()
            return

        if not self.authenticated:
            print("[gateway] no-auth gateway — proceeding")
            self.authenticated = True
            self._subscribe(ws)
            self._ready.set()

        self._parse_message_data(data, event, typ, payload)

    def _subscribe(self, ws):
        for msg in [
            {"type": "event", "event": "session.subscribe",
             "payload": {"sessionId": DEFAULT_SESSION}},
            {"type": "event", "event": "session.history",
             "payload": {"sessionId": DEFAULT_SESSION}},
            {"type": "event", "event": "sessions.list", "payload": {}},
        ]:
            try:
                ws.send(json.dumps(msg))
                time.sleep(0.05)
            except Exception as e:
                print(f"[gateway] subscribe failed: {e}")

    def _parse_message_data(self, data, event, typ, payload):
        with self._lock:
            if typ == "message" and data.get("role") == "user":
                self._user_messages.append(data)
            if event in ("session.message", "message") and isinstance(payload, dict):
                if payload.get("role") == "user":
                    self._user_messages.append(payload)
            for msg in data.get("messages", []):
                if isinstance(msg, dict) and msg.get("role") == "user":
                    self._user_messages.append(msg)
            for msg in data.get("history", []):
                if isinstance(msg, dict) and msg.get("role") == "user":
                    self._user_messages.append(msg)


_client      = GatewayClient()
_client_lock = threading.Lock()


def ensure_connected() -> bool:
    with _client_lock:
        if not _client.connected:
            return _client.connect()
        return True


def get_gateway_client() -> GatewayClient:
    ensure_connected()
    return _client


def _score_urgency(text: str) -> float:
    keywords = ["urgent", "help", "asap", "emergency", "now", "please",
                "broken", "error", "critical", "immediately", "fix"]
    return min(1.0, sum(1 for k in keywords if k in text.lower()) * 0.25)


def buildObservation(env) -> Observation:
    ensure_connected()
    session_id    = env.current_session_id or DEFAULT_SESSION
    user_messages = _client.get_user_messages(session_id)
    known_count   = getattr(env, "_known_message_count", 0)
    new_messages  = user_messages[known_count:]

    if new_messages:
        latest  = new_messages[-1]
        text    = latest.get("content", latest.get("text", latest.get("message", "")))
        sender  = latest.get("sender", latest.get("from", "user"))
        urgency = _score_urgency(text)
        env.last_message_time    = time.time()
        env.last_pending_text    = text
        env.last_pending_sender  = sender
        env._known_message_count = len(user_messages)
    else:
        text    = getattr(env, "last_pending_text", "")
        sender  = getattr(env, "last_pending_sender", "")
        urgency = 0.0

    unanswered = len(new_messages)
    time_since = time.time() - env.last_message_time if env.last_message_time else 9999.0

    return Observation(
        sender=sender, channel="whatsapp",
        message_text=text, session_id=session_id,
        message_urgency=urgency, unanswered_count=unanswered,
        last_action_success=env.last_action_success,
        time_since_last_message=time_since,
        web_search_result=getattr(env, "last_search_result", None),
        file_content=getattr(env, "last_file_content", None),
        active_sessions=[session_id],
    )


# import requests
# import time
# import json
# from type import Observation

# GATEWAY_BASE = "http://127.0.0.1:18789"

# # Decoded from your URL: agent:main:whatsapp:direct:+251919157130
# DEFAULT_SESSION = "agent:main:whatsapp:direct:+251919157130"

# _pending_messages = []
# _last_poll_time = 0.0

# def _poll_gateway(session_id: str) -> list:
#     """
#     OpenClaw gateway exposes session history at /api/sessions/{id}/history
#     Adjust the endpoint if yours differs.
#     """
#     global _pending_messages, _last_poll_time

#     endpoints_to_try = [
#         f"{GATEWAY_BASE}/api/sessions/{requests.utils.quote(session_id, safe='')}/history",
#         f"{GATEWAY_BASE}/sessions/{requests.utils.quote(session_id, safe='')}/history",
#         f"{GATEWAY_BASE}/api/history?session={requests.utils.quote(session_id)}",
#     ]

#     for url in endpoints_to_try:
#         try:
#             resp = requests.get(url, timeout=5)
#             if resp.status_code == 200:
#                 data = resp.json()
#                 # Gateway returns list of {role, content, timestamp}
#                 msgs = data if isinstance(data, list) else data.get("messages", data.get("history", []))
#                 # Only return user messages we haven't processed
#                 user_msgs = [m for m in msgs if m.get("role") == "user"]
#                 return user_msgs
#         except Exception:
#             continue
#     return []

# def _score_urgency(text: str) -> float:
#     urgent_keywords = ["urgent", "help", "asap", "emergency", "now", "please",
#                        "broken", "error", "critical", "immediately", "fix"]
#     text_lower = text.lower()
#     hits = sum(1 for kw in urgent_keywords if kw in text_lower)
#     return min(1.0, hits * 0.25)

# def buildObservation(env) -> Observation:
#     session_id = env.current_session_id or DEFAULT_SESSION
#     messages = _poll_gateway(session_id)

#     # Track only new messages since last observation
#     known_count = getattr(env, "_known_message_count", 0)
#     new_messages = messages[known_count:]
#     env._known_message_count = len(messages)

#     if new_messages:
#         latest = new_messages[-1]
#         text = latest.get("content", latest.get("text", ""))
#         sender = latest.get("sender", latest.get("from", "user"))
#         channel = "whatsapp"
#         urgency = _score_urgency(text)
#         env.last_message_time = time.time()
#         env.last_pending_text = text
#         env.last_pending_sender = sender
#     else:
#         text = getattr(env, "last_pending_text", "")
#         sender = getattr(env, "last_pending_sender", "")
#         channel = "whatsapp"
#         urgency = 0.0

#     unanswered = len(new_messages)
#     now = time.time()
#     time_since = now - env.last_message_time if env.last_message_time else 9999.0

#     return Observation(
#         sender=sender,
#         channel=channel,
#         message_text=text,
#         session_id=session_id,
#         message_urgency=urgency,
#         unanswered_count=unanswered,
#         last_action_success=env.last_action_success,
#         time_since_last_message=time_since,
#         web_search_result=getattr(env, "last_search_result", None),
#         file_content=getattr(env, "last_file_content", None),
#         active_sessions=[session_id],
#     )