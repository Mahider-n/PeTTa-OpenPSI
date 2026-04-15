from dataclasses import dataclass, field
from enum import Enum, auto
from typing import List, Optional

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
    sender: str
    channel: str
    message_text: str
    session_id: str

    message_urgency: float         
    unanswered_count: int          
    last_action_success: bool
    time_since_last_message: float  

    web_search_result: Optional[str] = None
    file_content: Optional[str] = None
    active_sessions: List[str] = field(default_factory=list)
    sentiment: Optional[str] = None  