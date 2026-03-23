from dataclasses import dataclass, field
from enum import Enum, auto
from typing import List, Dict, Any, Optional

class ActionType(Enum):
    SEND_MESSAGE = auto()
    SEND_MESSAGE_WITH_SEARCH = auto()

    WEB_SEARCH = auto()
    READ_FILE = auto()
    WRITE_FILE = auto()
    LIST_SESSIONS = auto()
    GET_HISTORY = auto()
    IDLE = auto()

@dataclass
class Observation:
    # Latest inbound message
    sender: str
    channel: str
    message_text: str
    session_id: str

    # Derived cognitive inputs
    message_urgency: float        # 0.0–1.0, e.g. from keywords like "urgent", "help"
    unanswered_count: int         # how many messages are pending
    last_action_success: bool
    time_since_last_message: float  # seconds

    # Optional extras
    web_search_result: Optional[str] = None
    file_content: Optional[str] = None
    active_sessions: List[str] = field(default_factory=list)
    sentiment: Optional[str] = None  # "positive", "negative", "neutral"