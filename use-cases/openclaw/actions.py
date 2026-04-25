import time
import requests
from typing import Optional, TYPE_CHECKING
import os
from dotenv import load_dotenv
import subprocess
import json
import re 

load_dotenv()


if TYPE_CHECKING:
    from openclaw_env import OpenClawEnvironment

OPENCLAW_GATEWAY_TOKEN = os.getenv("OPENCLAW_GATEWAY_TOKEN")
GATEWAY_URL = os.getenv("GATEWAY_URL")
DEFAULT_SESSION_KEY = os.getenv("DEFAULT_SESSION_KEY")

GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_API_KEY=os.getenv("GEMINI_API_KEY")


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

def clean_gemini_output(answer: str, query: str, sources=None):
    if not answer:
        answer = ""

    patterns = [
        r'<\s*toolcall\s*>.*?<\s*/\s*toolcall\s*>',
        r'<\s*tool_call\s*>.*?<\s*/\s*tool_call\s*>',
        r'Let me try a simpler search query.*?$',
        r'I\'ll search for.*?without country filtering.*?$'
    ]

    for pattern in patterns:
        answer = re.sub(pattern, '', answer, flags=re.DOTALL | re.IGNORECASE | re.MULTILINE)

    answer = re.sub(r'\n\s*\n+', '\n\n', answer).strip()

    if not answer or len(answer.split()) < 5:
        answer = f"Here is the latest information on: {query}\n\nNo detailed results returned."

    if sources:
        unique_sources = list(dict.fromkeys(sources))
        answer += "\n\nSources:\n" + "\n".join(unique_sources)

    return answer

def _extract_result_text(result: dict) -> str:
    if not isinstance(result, dict):
        return ""

    if "content" in result and isinstance(result["content"], list):
        text = result["content"][0].get("text", "") if result["content"] else ""
        try:
            parsed = json.loads(text) if isinstance(text, str) else text
            if isinstance(parsed, dict):
                return parsed.get("content", "") or parsed.get("text", "") or str(parsed)
        except Exception:
            pass
        return str(text)

    return result.get("content", "") or result.get("details", {}).get("content", "")


def _extract_message_text(content) -> str:
    if isinstance(content, str):
        return content.strip()

    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item.get("text", "").strip())
        return " ".join(part for part in parts if part)

    return ""


def _latest_user_message(session_key: str) -> str:
    messages = fetchHistory(session_key=session_key, limit=20) or []
    for msg in reversed(messages):
        if msg.get("role") == "user":
            return _extract_message_text(msg.get("content", ""))
    return ""


def _gemini_web_search(query: str) -> Optional[str]:
    if not GEMINI_API_KEY:
        print("[actions] Gemini API key not found. Set GEMINI_API_KEY or GOOGLE_API_KEY.")
        return None

    if not query.strip():
        return "No query provided for web search."

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": (
                            "Answer this search query using current web information. "
                            "Be concise, factual, and include cited sources when available.\n\n"
                            f"Query: {query}"
                        )
                    }
                ]
            }
        ],
        "tools": [
            {
                "google_search": {}
            }
        ],
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 700,
        },
    }

    try:
        resp = requests.post(
            url,
            headers={
                "Content-Type": "application/json",
                "x-goog-api-key": GEMINI_API_KEY,
            },
            json=payload,
            timeout=45,
        )
        resp.raise_for_status()
        data = resp.json()
    except requests.exceptions.HTTPError as e:
        body = ""
        try:
            body = resp.text[:500]
        except Exception:
            pass
        print(f"[actions] Gemini web search HTTP error: {e}")
        if body:
            print(f"   Response: {body}")
        return None
    except Exception as e:
        print(f"[actions] Gemini web search failed: {e}")
        return None

    candidates = data.get("candidates", [])
    if not candidates:
        print("[actions] Gemini web search returned no candidates.")
        return None

    candidate = candidates[0]
    content = candidate.get("content", {})
    parts = content.get("parts", []) if isinstance(content, dict) else []
    answer = "\n".join(
        part.get("text", "").strip()
        for part in parts
        if isinstance(part, dict) and part.get("text")
    ).strip()

    grounding = candidate.get("groundingMetadata", {}) or {}
    chunks = grounding.get("groundingChunks", []) or []

    sources = []
    for chunk in chunks:
        web_info = chunk.get("web", {}) if isinstance(chunk, dict) else {}
        title = web_info.get("title")
        uri = web_info.get("uri")
        if uri:
            sources.append(f"- {title or uri}: {uri}")

    if sources:
        answer = f"{answer}\n\nSources:\n" + "\n".join(dict.fromkeys(sources))
        cleaned_answer = clean_gemini_output(answer,query,sources)

    return cleaned_answer or "Gemini search completed, but no text was returned."


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

def doSendMessage(env: "OpenClawEnvironment", text: str = "", session_id: Optional[str] = None) -> Optional[str]:
    session_key = session_id or env.current_session_id or DEFAULT_SESSION_KEY

    latest = _latest_user_message(session_key)

    if (not latest or not latest.strip()):
        if not hasattr(env, "has_greeted") or not env.has_greeted:

            text = "Hello, this is a message from OpenPsi 🚀"
            env.has_greeted = True
            print("[actions] 👋 Sending one-time greeting")
        else:
            print("[actions] ❌ Blocked: No message and already greeted")
            return None

    else:
        if hasattr(env, "last_handled_user_message") and env.last_handled_user_message == latest:
            print("[actions] ⚠️ Blocked: Already responded to this message")
            return None

        if not text or not text.strip():
            print("[actions] ❌ Blocked: Empty response")
            return None

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

            if latest and latest.strip():
                env.last_handled_user_message = latest

            env.last_message_time = time.time()
            return "sent"
        else:
            print(f"❌ CLI failed (code {result.returncode})")
            print(f"   Error: {result.stderr.strip()}")
            return None

    except Exception as e:
        print(f"❌ Exception calling CLI: {e}")
        return None
    
def doSendMessageWithSearch(env: "OpenClawEnvironment") -> Optional[str]:
    session_key = env.current_session_id or DEFAULT_SESSION_KEY

    if not env.last_search_result:
        query = _latest_user_message(session_key)
        if query:
            doWebSearch(env, query)

    if not env.last_search_result:
        print("[actions] No search result available to send.")
        return None

    message = env.last_search_result.strip()
    if len(message) > 3500:
        message = message[:3497] + "..."

    return doSendMessage(env, text=message, session_id=session_key)

def doWebSearch(env: "OpenClawEnvironment", query: str = "") -> Optional[str]:
    content = _gemini_web_search(query)
    if content:
        env.last_search_result = content
        print(f"[actions] Gemini web search done for: '{query}'")
        return content

    result = _invoke("web_search", {"query": query})
    if result:
        content = _extract_result_text(result)
        env.last_search_result = content
        print(f"[actions] Gateway web search done for: '{query[:60]}...'")
        return content

    print(f"[actions] web_search failed for query: '{query}'")
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