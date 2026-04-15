 

import json
import os
import sys
import requests
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

CONFIG_PATH = Path.home() / ".openclaw" / "openclaw.json"   

GATEWAY_URL = os.getenv("GATEWAY_URL")
TOKEN_ENV_VAR = os.getenv("OPENCLAW_GATEWAY_TOKEN")

def load_gateway_token():
    """Load token from config file or environment variable"""
    token = os.getenv(TOKEN_ENV_VAR)
    if token:
        print(f"Token loaded from environment variable {TOKEN_ENV_VAR}")
        return token.strip()


    if CONFIG_PATH.exists():
        try:
            with open(CONFIG_PATH, "r", encoding="utf-8") as f:
                config = json.load(f)
            
            token = config.get("gateway", {}) \
                         .get("auth", {}) \
                         .get("token")
            
            if token:
                print(f"Token loaded from config: {CONFIG_PATH}")
                return token.strip()
        except Exception as e:
            print(f" Failed to read config file: {e}")
    
    print(" Token not found in config or environment.")
    print(f"   Run: export {TOKEN_ENV_VAR}=your_token_here")
    print("   Or regenerate with: openclaw doctor --repair --generate-gateway-token")
    sys.exit(1)


def invoke_tool(tool_name: str, args: dict = None, verbose=True):
    """Call any OpenClaw tool via HTTP"""
    if args is None:
        args = {}

    payload = {
        "tool": tool_name,
        "args": args
    }

    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json",
        "User-Agent": "OpenClaw-Test-Script"
    }

    try:
        response = requests.post(
            f"{GATEWAY_URL}/tools/invoke",
            json=payload,
            headers=headers,
            timeout=15
        )

        if verbose:
            print(f"\n🔹 Tool: {tool_name}")
            print(f"   Status: {response.status_code} {response.reason}")

        if response.status_code == 401:
            print(" 401 Unauthorized - Token is invalid or missing")
            print("   Solutions:")
            print("   1. Run: openclaw doctor --repair --generate-gateway-token")
            print("   2. Then restart gateway: openclaw gateway restart")
            print("   3. Or set environment: export OPENCLAW_GATEWAY_TOKEN=...")
            return None

        elif response.status_code == 404:
            print(f" 404 Tool not found: {tool_name}")
            return None

        response.raise_for_status()
        
        data = response.json()
        if verbose:
            print(f"    Success")
            print(json.dumps(data, indent=2)[:800] + "..." if len(str(data)) > 800 else json.dumps(data, indent=2))
        
        return data

    except requests.exceptions.ConnectionError:
        print(f"Cannot connect to gateway at {GATEWAY_URL}")
        print("   Make sure OpenClaw gateway is running (openclaw gateway start)")
        return None
    except requests.exceptions.HTTPError as e:
        print(f" HTTP Error: {e}")
        if response.text:
            print("Response body:", response.text[:500])
        return None
    except json.JSONDecodeError:
        print(" Received non-JSON response (probably HTML error page)")
        print("Response:", response.text[:500])
        return None
    except Exception as e:
        print(f" Unexpected error: {e}")
        return None


if __name__ == "__main__":
    print("OpenClaw Gateway Test Script (401 Fix)\n")
    
    TOKEN = load_gateway_token()
    
    print(f"Gateway URL : {GATEWAY_URL}")
    print(f"Token length: {len(TOKEN)} characters\n")

    print(" Testing gateway health / basic connection...")
    invoke_tool("sessions_list", {}, verbose=True)

    print("\n Testing sessions_list...")
    invoke_tool("sessions_list")

    print("\n Testing sessions_history (your main WhatsApp session)...")
    session_key = "agent:main:whatsapp:direct:+251919157130"
    invoke_tool("sessions_history", {"sessionKey": session_key})

    print("\n Testing sessions_send...")
    invoke_tool("sessions_send", {
        "sessionKey": session_key,
        "message": "Hello from test script! This is a test reply."
    })

    print("\n Test finished. If you still get 401, regenerate the token.")