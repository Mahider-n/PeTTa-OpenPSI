
import time
import re
from typing import TYPE_CHECKING
from type import Observation
import actions as actionOps
import os
from dotenv import load_dotenv

load_dotenv()


if TYPE_CHECKING:
    from openclaw_env import OpenClawEnvironment


DEFAULT_SESSION_KEY = os.getenv("DEFAULT_SESSION_KEY")
OPENCLAW_GATEWAY_TOKEN = os.getenv("OPENCLAW_GATEWAY_TOKEN")


URGENT_KEYWORDS = [
    "urgent", "help", "emergency", "asap", "immediately",
    "critical", "error", "broken", "failing", "crash",
]

INFO_KEYWORDS = [
    "what is", "who is", "how does", "explain", "tell me about",
    "search", "find", "look up", "latest", "news", "recent",
]


def _extractText(content) -> str:
    """Extract plain text from a message content block (list or string)."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", "").strip())
        return " ".join(parts)
    return ""


def _computeUrgency(text: str) -> float:
    """Score 0.0–1.0 based on urgent keywords in message text."""
    text_lower = text.lower()
    hits = sum(1 for kw in URGENT_KEYWORDS if kw in text_lower)
    return min(1.0, hits * 0.25)


def _isInfoRequest(text: str) -> bool:
    text_lower = text.lower()
    return any(kw in text_lower for kw in INFO_KEYWORDS)


def buildObservation(env: "OpenClawEnvironment") -> Observation:
    """
    Fetches the latest session history (confirmed working endpoint)
    and builds a full Observation object.
    """
    session_key = env.current_session_id or DEFAULT_SESSION_KEY
    messages = actionOps.fetchHistory(session_key, limit=50) or []

    last_user_msg = None
    last_assistant_msg = None
    unanswered_count = 0

    for msg in reversed(messages):
        role = msg.get("role", "")
        text = _extractText(msg.get("content", ""))

        if role == "user" and last_user_msg is None:
            last_user_msg = msg
        elif role == "assistant" and last_assistant_msg is None:
            last_assistant_msg = msg

        if last_user_msg and last_assistant_msg:
            break

    found_assistant = False
    for msg in reversed(messages):
        if msg.get("role") == "assistant":
            found_assistant = True
            break
        if msg.get("role") == "user":
            unanswered_count += 1

    if not found_assistant:
        unanswered_count = sum(1 for m in messages if m.get("role") == "user")

    message_text = ""
    sender = "unknown"
    urgency = 0.0

    if last_user_msg:
        message_text = _extractText(last_user_msg.get("content", ""))
        sender = last_user_msg.get("senderLabel", "unknown")
        urgency = _computeUrgency(message_text)

    now_ms = time.time() * 1000
    last_ts = 0
    if messages:
        last_ts = messages[-1].get("timestamp", 0)
    time_since = (now_ms - last_ts) / 1000.0 if last_ts else 9999.0

    obs = Observation(
        sender=sender,
        channel="whatsapp",
        message_text=message_text,
        session_id=session_key,
        message_urgency=urgency,
        unanswered_count=unanswered_count,
        last_action_success=env.last_action_success,
        time_since_last_message=time_since,
        web_search_result=env.last_search_result,
        file_content=env.last_file_content,
        active_sessions=env.active_sessions,
        sentiment=None,
    )

    print(f"[observation] Built: unanswered={unanswered_count}, urgency={urgency:.2f}, msg='{message_text[:40]}'")
    return obs


