import json
import os
import sys
from pathlib import Path

import requests
from openclaw_config import get_env

CONFIG_PATH = Path.home() / ".openclaw" / "openclaw.json"
GATEWAY_URL = get_env("GATEWAY_URL", "http://127.0.0.1:18789")
TOKEN = get_env("OPENCLAW_GATEWAY_TOKEN")
DEFAULT_SESSION_KEY = get_env("DEFAULT_SESSION_KEY")

print(GATEWAY_URL)
print(TOKEN)
print(DEFAULT_SESSION_KEY)

def load_gateway_token() -> str:
    """Load the gateway token from env first, then fallback to config."""
    if TOKEN:
        return TOKEN.strip()

    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as file:
                config = json.load(file)
            token = config.get("gateway", {}).get("auth", {}).get("token")
            if token:
                return token.strip()
        except Exception as exc:
            print(f"Failed to read {CONFIG_PATH}: {exc}")

    print("OpenClaw gateway token not found.")
    print("Set OPENCLAW_GATEWAY_TOKEN or regenerate it with:")
    print("openclaw doctor --repair --generate-gateway-token")
    sys.exit(1)


def invoke_tool(token: str, tool_name: str, args: dict | None = None):
    """Call an OpenClaw gateway tool."""
    payload = {"tool": tool_name, "args": args or {}}
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.post(
            f"{GATEWAY_URL}/tools/invoke",
            json=payload,
            headers=headers,
            timeout=15,
        )
        response.raise_for_status()
        data = response.json()
        print(f"{tool_name}: OK")
        return data
    except requests.exceptions.ConnectionError:
        print(f"Could not connect to gateway at {GATEWAY_URL}")
        print("Make sure the OpenClaw gateway is running.")
    except requests.exceptions.HTTPError as exc:
        print(f"{tool_name}: HTTP error: {exc}")
        print(response.text[:500])
    except Exception as exc:
        print(f"{tool_name}: {exc}")
    return None


if __name__ == "__main__":
    print("OpenClaw Gateway Test\n")

    token = load_gateway_token()
    print(f"Gateway URL: {GATEWAY_URL}")
    print(f"Token loaded: {len(token)} characters\n")

    print("Checking sessions_list...")
    invoke_tool(token, "sessions_list")

    if DEFAULT_SESSION_KEY:
        print(f"\nChecking sessions_history for {DEFAULT_SESSION_KEY} ...")
        invoke_tool(token, "sessions_history", {"sessionKey": DEFAULT_SESSION_KEY})
    else:
        print("\nDEFAULT_SESSION_KEY is not set, skipping sessions_history.")
