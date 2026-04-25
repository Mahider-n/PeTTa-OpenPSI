
import requests
from typing import Optional
from type import ActionType, Observation
import actions as actionOps
import observation as observationOps
from openclaw_config import get_env

GATEWAY_URL = get_env("GATEWAY_URL")
DEFAULT_SESSION_KEY = get_env("DEFAULT_SESSION_KEY")

class OpenClawEnvironment:
    def __init__(self):
        self.connected = False
        self.current_session_id: Optional[str] = None
        self.last_message_time: Optional[float] = None
        self.last_action_success: bool = True
        self.last_search_result: Optional[str] = None
        self.last_file_content: Optional[str] = None
        self.active_sessions: list = []
 

        self.action_handlers = {
            ActionType.SEND_MESSAGE:             self.doSendMessage,
            ActionType.SEND_MESSAGE_WITH_SEARCH: self.doSendMessageWithSearch,
            ActionType.WEB_SEARCH:               self.doWebSearch,
            ActionType.READ_FILE:                self.doReadFile,
            ActionType.WRITE_FILE:               self.doWriteFile,
            ActionType.LIST_SESSIONS:            self.doListSessions,
            ActionType.IDLE:                     self.doIdle,
           
        }

    def connect(self) -> bool:
        print("Connecting to OpenClaw Gateway...")
        try:
            resp = requests.get(
                f"{GATEWAY_URL}/sessions/{DEFAULT_SESSION_KEY}/history?limit=1",
                timeout=5,
            )
            if resp.status_code == 200:
                self.connected = True
                self.current_session_id = DEFAULT_SESSION_KEY
                print(f"Connected to OpenClaw Gateway. Session: {self.current_session_id}")
                return True
            else:
                print(f"Gateway returned status {resp.status_code}")
        except Exception as e:
            print(f"Connection failed: {e}")
        return False

    def disconnect(self):
        self.connected = False
        print("Disconnected from OpenClaw Gateway.")

    def getObservation(self) -> Observation:
        return observationOps.buildObservation(self)

    def executeAction(self, action_type: ActionType, *args):
        if not self.connected:
            print("Not connected.")
            return None
        handler = self.action_handlers.get(action_type)
        if handler:
            result = handler(*args)
            self.last_action_success = result is not None
            return result
        print(f"Unknown action: {action_type}")
        return None

    def doSendMessage(self, text="Hello,this is a message from openpsi environment 🚀", session_id=None):
        return actionOps.doSendMessage(self, text, session_id)

    def doSendMessageWithSearch(self):
        return actionOps.doSendMessageWithSearch(self)

    def doWebSearch(self, query=""):
        return actionOps.doWebSearch(self, query)

    def doReadFile(self, path=""):
        return actionOps.doReadFile(self, path)

    def doWriteFile(self, path="", content=""):
        return actionOps.doWriteFile(self, path, content)

    def doListSessions(self):
        return actionOps.doListSessions(self)

    def doIdle(self):
        return actionOps.doIdle(self)
