import time
from typing import Optional
from type import ActionType, Observation
import actions as actionOps
import observation as observationOps

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
            ActionType.SEND_MESSAGE: self.doSendMessage,
            ActionType.SEND_MESSAGE_WITH_SEARCH: self.doSendMessageWithSearch,

            ActionType.WEB_SEARCH:   self.doWebSearch,
            ActionType.READ_FILE:    self.doReadFile,
            ActionType.WRITE_FILE:   self.doWriteFile,
            ActionType.LIST_SESSIONS: self.doListSessions,
            ActionType.IDLE:         self.doIdle,
        }

    def connect(self) -> bool:
        print("Connecting to OpenClaw Gateway...")
        try:
            import requests
            resp = requests.get("http://127.0.0.1:18789/health", timeout=5)
            if resp.status_code == 200:
                self.connected = True
                print("Connected to OpenClaw Gateway.")
                # Fetch the first available session
                sessions = resp.json().get("sessions", [])
                if sessions:
                    self.current_session_id = sessions[0]
                return True
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

    def doSendMessage(self, text="Hello", session_id=None):
        return actionOps.doSendMessage(self, text, session_id)

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
    
    def doSendMessageWithSearch(self):
        return actionOps.doSendMessageWithSearch(self)