import time
import requests
from typing import Optional, TYPE_CHECKING
import os
from dotenv import load_dotenv
import subprocess
load_dotenv()


if TYPE_CHECKING:
    from openclaw_env import OpenClawEnvironment


OPENCLAW_GATEWAY_TOKEN = os.getenv("OPENCLAW_GATEWAY_TOKEN")
GATEWAY_URL = os.getenv("GATEWAY_URL")
DEFAULT_SESSION_KEY = os.getenv("DEFAULT_SESSION_KEY")

HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {OPENCLAW_GATEWAY_TOKEN}"
}

def _invoke(tool: str, args: dict) -> Optional[dict]:
    """
    Central tool caller with proper authentication
    """
    try:
        resp = requests.post(
            f"{GATEWAY_URL}/tools/invoke",
            json={"tool": tool, "args": args},
            headers=HEADERS,
            timeout=30,
        )

        if resp.status_code == 401:
            print(f"[actions] _invoke error ({tool}): 401 Unauthorized - Check token!")
            print("   Run: export OPENCLAW_GATEWAY_TOKEN=your_new_token")
            return None

        resp.raise_for_status()
        data = resp.json()

        if data.get("ok"):
            return data.get("result", {})
        
        print(f"[actions] Tool '{tool}' returned ok=false: {data}")
        return None

    except requests.exceptions.HTTPError as e:
        print(f"[actions] _invoke error ({tool}): HTTP {resp.status_code} - {e}")
        if resp.text:
            print(f"   Response: {resp.text[:400]}")
        return None
    except Exception as e:
        print(f"[actions] _invoke error ({tool}): {e}")
        return None


def doListSessions(env: "OpenClawEnvironment") -> Optional[list]:
    """Use the proper sessions_list tool"""
    result = _invoke("sessions_list", {})
    if result and isinstance(result, dict):
        content = result.get("content", [])
        if isinstance(content, list) and len(content) > 0:
            text = content[0].get("text", "") if isinstance(content[0], dict) else ""
            try:
                import json
                parsed = json.loads(text) if isinstance(text, str) else text
                sessions = parsed.get("sessions", []) if isinstance(parsed, dict) else []
                env.active_sessions = [s.get("key") for s in sessions if isinstance(s, dict)]
                print(f"[actions] Sessions found: {len(env.active_sessions)}")
                return env.active_sessions
            except:
                pass
    print("[actions] doListSessions failed or returned unexpected format")
    return None


def fetchHistory(session_key: str = DEFAULT_SESSION_KEY, limit: int = 50) -> Optional[list]:
    """Use sessions_history tool """
    result = _invoke("sessions_history", {
        "sessionKey": session_key,
        "limit": limit,
        "includeTools": False,
    })
    if result:
        if isinstance(result, dict):
            content = result.get("content", [])
            if isinstance(content, list) and content:
                text = content[0].get("text", "") if isinstance(content[0], dict) else ""
                try:
                    import json
                    parsed = json.loads(text) if isinstance(text, str) else text
                    return parsed.get("messages", []) if isinstance(parsed, dict) else []
                except:
                    pass
        return result.get("messages", []) or result.get("details", {}).get("messages", [])
    
    print(f"[actions] fetchHistory failed - returning empty history")
    return []
 
def doSendMessage(env: "OpenClawEnvironment", text: str = "Hello, this is a message from openpsi", session_id: Optional[str] = None) -> Optional[str]:
    session_key = session_id or env.current_session_id or DEFAULT_SESSION_KEY
    
    target = session_key.split(":")[-1]
    
    print(f"🚀 OPENPSI IS REPLYING VIA CLI → {text[:150]}")
    print(f"   Channel: whatsapp | Target: {target}")

    try:
        cmd = [
            "openclaw", "message", "send",
            "--channel", "whatsapp",
            "--target", target,
            "--message", text
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        
        if result.returncode == 0:
            print("✅ SUCCESS: OpenPsi reply delivered via CLI")
            print(f"   CLI output: {result.stdout.strip()}")
            env.last_message_time = time.time()
            return "sent"
        else:
            print(f"❌ CLI failed (code {result.returncode})")
            print(f"   Error: {result.stderr.strip()}")
            return None

    except Exception as e:
        print(f"❌ Exception calling CLI: {e}")
        return None

def doWebSearch(env: "OpenClawEnvironment", query: str = "") -> Optional[str]:
    result = _invoke("web_search", {"query": query})
    if result:
        content = ""
        if isinstance(result, dict):
            if "content" in result and isinstance(result["content"], list):
                text = result["content"][0].get("text", "") if result["content"] else ""
                try:
                    import json
                    parsed = json.loads(text) if isinstance(text, str) else text
                    content = parsed.get("content", "") if isinstance(parsed, dict) else str(text)
                except:
                    content = str(text)
            else:
                content = result.get("content", "") or result.get("details", {}).get("content", "")
        
        env.last_search_result = content
        print(f"[actions] Web search done for: '{query[:60]}...'")
        return content
    
    print(f"[actions] web_search tool not available or failed for query: '{query}'")
    env.last_search_result = f"Web search unavailable right now. Query was: {query}"
    
    return env.last_search_result
    


def doReadFile(env: "OpenClawEnvironment", path: str = "") -> Optional[str]:
    result = _invoke("file", {"action": "read", "path": path})
    if result:
        content = result.get("content", "") or result.get("details", {}).get("content", "")
        env.last_file_content = content
        return content
    return None

def doWriteFile(env: "OpenClawEnvironment", path: str = "", content: str = "") -> Optional[str]:
    result = _invoke("file", {"action": "write", "path": path, "content": content})
    return "written" if result else None


def doIdle(env: "OpenClawEnvironment") -> str:
    print("[actions] Idling for 2 seconds...")
    time.sleep(2)
    return "idle"